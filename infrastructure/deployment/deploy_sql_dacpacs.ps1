param(
    # ============================================
    # Connection Parameters
    # ============================================
    [Parameter(Mandatory=$true)]
    [string] $tenantId,

    [Parameter(Mandatory=$true)]
    [string] $subscriptionId,

    [Parameter(Mandatory=$false)]
    [string] $sqlUsernameSecret = $sqlServerName + '-adminusername',

    [Parameter(Mandatory=$false)]
    [string] $sqlValueSecret = $sqlServerName + '-adminpassword',

    # ============================================
    # Config Parameters
    # ============================================
    [Parameter(Mandatory=$true)]
    [string] $keyVaultName,

    # ============================================
    # Core Parameters
    # ============================================
    [Parameter(Mandatory=$true)]
    [string] $sqlServerName,

    [Parameter(Mandatory=$true)]
    [string] $sqlDatabaseName,

    [Parameter(Mandatory=$true)]
    [string] $databricksWorkspaceName,

    [Parameter(Mandatory=$true)]
    [string] $databricksWorkspaceURL,

    [Parameter(Mandatory=$true)]
    [string] $storageAccountName,

    [Parameter(Mandatory=$true)]
    [string] $resourceGroupName,

    [Parameter(Mandatory=$true)]
    [string] $dataFactoryName,

    [Parameter(Mandatory=$false)]
    [string] $environment = 'Dev',

    # ============================================
    # Data Parameters
    # ============================================
    [Parameter(Mandatory=$false)]
    [boolean] $deployData = $false,

    [Parameter(Mandatory=$false)]
    [boolean] $demoConnectionLocation,

    [Parameter(Mandatory=$false)]
    [boolean] $demoKVSecret,

    [Parameter(Mandatory=$false)]
    [boolean] $demoLinkedService,

    [Parameter(Mandatory=$false)]
    [boolean] $demoResourceName,

    [Parameter(Mandatory=$false)]
    [boolean] $demoSourceLocation,

    [Parameter(Mandatory=$false)]
    [boolean] $demoUsername
)

# ============================================
# Get SQL User and Password from Key Vault to deploy DacPacs
# ============================================
$sqlLogin = az keyvault secret show `
    --name $sqlUsernameSecret `
    --vault-name $keyVaultName `
    --query value `
    --output tsv

$sqlPassword = az keyvault secret show `
    --name $sqlValueSecret `
    --vault-name $keyVaultName `
    --query value `
    --output tsv

$currentLocation = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
$sourceFolderPath = $currentLocation -replace '\\infrastructure\\deployment'

# ============================================
# Build DacPacs
# control/ingest/transform all reference common, so common builds first,
# then the three schema projects build in parallel.
# ============================================

$configuration = "Debug"
$connStr       = "Server=tcp:$sqlServerName.database.windows.net,1433;Initial Catalog=$sqlDatabaseName;Persist Security Info=False;User ID=$sqlLogin;Password=$sqlPassword;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
$reportDir     = "$sourceFolderPath\src\metadata.core"

Write-Host "`nBuilding common (required first)..." -ForegroundColor Green
dotnet build "$sourceFolderPath\src\metadata.common\metadata.common.sqlproj" `
    --configuration $configuration `
    /p:NetCoreBuild=true `
    /p:SqlServerVersion=Azure

Write-Host "Building control / ingest / transform in parallel..." -ForegroundColor Yellow
$buildJobs = @(
    Start-Job -Name "build-control" -ScriptBlock {
        dotnet build $using:sourceFolderPath\src\metadata.control\metadata.control.sqlproj `
            --configuration $using:configuration /p:NetCoreBuild=true /p:SqlServerVersion=Azure
    }
    Start-Job -Name "build-ingest" -ScriptBlock {
        dotnet build $using:sourceFolderPath\src\metadata.ingest\metadata.ingest.sqlproj `
            --configuration $using:configuration /p:NetCoreBuild=true /p:SqlServerVersion=Azure
    }
    Start-Job -Name "build-transform" -ScriptBlock {
        dotnet build $using:sourceFolderPath\src\metadata.transform\metadata.transform.sqlproj `
            --configuration $using:configuration /p:NetCoreBuild=true /p:SqlServerVersion=Azure
    }
)

if ($deployData) {
    $buildJobs += Start-Job -Name "build-data" -ScriptBlock {
        dotnet build $using:sourceFolderPath\src\metadata.data\metadata.data.sqlproj `
            --configuration $using:configuration /p:NetCoreBuild=true /p:SqlServerVersion=Azure
    }
}

$buildJobs | Wait-Job | Receive-Job
$buildJobs | Remove-Job

# ============================================
# Publish the core set of DacPacs + PostDeployment Scripts
# common must publish before the schema-specific projects (they reference
# its objects at runtime). control / ingest / transform target different
# schemas and have no cross-dependencies, so they publish in parallel.
# /p:ScriptDatabaseOptions=false skips the DB-level options round-trip,
# which is the single biggest per-publish time saving.
# ============================================

Write-Host "`nPublishing common schema objects (required first)..." -ForegroundColor Green
SqlPackage /Action:Publish `
    "/SourceFile:$sourceFolderPath\src\metadata.common\bin\Debug\metadata.common.dacpac" `
    "/TargetConnectionString:$connStr" `
    /v:DatabricksWSName=$databricksWorkspaceName `
    "/v:DatabricksHost=https://$databricksWorkspaceURL" `
    /v:DLSName=$storageAccountName `
    /v:Environment=$environment `
    /v:KeyVaultName=$keyVaultName `
    /v:RGName=$resourceGroupName `
    /v:SubscriptionID=$subscriptionId `
    /p:ScriptDatabaseOptions=false `
    "/DeployReportPath:$reportDir\deploy-report-common.xml"

Write-Host "Publishing the control schema objects..."
SqlPackage /Action:Publish `
    "/SourceFile:$sourceFolderPath\src\metadata.control\bin\Debug\metadata.control.dacpac" `
    "/TargetConnectionString:$connStr" `
    /v:Environment=$environment `
    /v:RGName=$resourceGroupName `
    /v:SubscriptionID=$subscriptionId `
    /v:ADFName=$dataFactoryName `
    /v:TenantID=$tenantId `
    /DeployReportPath:"$sourceFolderPath\src\metadata.core\deploy-report.xml"


Write-Host "Publishing ingest / transform in parallel..." -ForegroundColor Yellow
$publishJobs = @(
    Start-Job -Name "publish-ingest" -ScriptBlock {
        param($conn, $src, $report)
        & SqlPackage /Action:Publish `
            "/SourceFile:$src\metadata.ingest\bin\Debug\metadata.ingest.dacpac" `
            "/TargetConnectionString:$conn" `
            /p:ScriptDatabaseOptions=false `
            "/DeployReportPath:$report\deploy-report-ingest.xml"
    } -ArgumentList $connStr, "$sourceFolderPath\src", $reportDir

    Start-Job -Name "publish-transform" -ScriptBlock {
        param($conn, $src, $report)
        & SqlPackage /Action:Publish `
            "/SourceFile:$src\metadata.transform\bin\Debug\metadata.transform.dacpac" `
            "/TargetConnectionString:$conn" `
            /p:ScriptDatabaseOptions=false `
            "/DeployReportPath:$report\deploy-report-transform.xml"
    } -ArgumentList $connStr, "$sourceFolderPath\src", $reportDir
)

$publishJobs | Wait-Job | Receive-Job
if ($publishJobs | Where-Object { $_.State -eq "Failed" }) {
    throw "One or more schema publishes failed. Check output above."
}
$publishJobs | Remove-Job

# ============================================
# Publish the data PostDeployment Scripts
# ============================================
if ($deployData) {
    Write-Host "Publishing and populating the metadata-as-code ..." -ForegroundColor Yellow
    SqlPackage /Action:Publish `
        "/SourceFile:$sourceFolderPath\src\metadata.data\bin\Debug\metadata.data.dacpac" `
        "/TargetConnectionString:$connStr" `
        /v:ADFName=$dataFactoryName `
        /v:DemoConnectionLocation=$demoConnectionLocation `
        /v:DemoKVSecret=$demoKVSecret `
        /v:DemoLinkedService=$demoLinkedService `
        /v:DemoResourceName=$demoResourceName `
        /v:DemoSourceLocation=$demoSourceLocation `
        /v:DemoUsername=$demoUsername `
        /p:ScriptDatabaseOptions=false
}

# ============================================
# Set Entra AD Admin to current user
# ============================================
Write-Host "Setting current user as Entra AD Admin..."
$userDetails = az ad signed-in-user show --query userPrincipalName --output tsv
$userId = az ad signed-in-user show --query id --output tsv
az sql server ad-admin create --resource-group $resourceGroupName --server $sqlServerName --display-name $userDetails --object-id $userId

# ============================================
# Provision Role assignments for ADF SPN
# ============================================
Write-Host "Grant Access for ADF on Metadata Database..."
$createADFUserScript = $currentLocation + '\grant_adf_access.ps1'
& $createADFUserScript `
    -sqlServerName $sqlServerName `
    -sqlDatabaseName $sqlDatabaseName `
    -dataFactoryName $dataFactoryName

Remove-Variable sqlPassword 

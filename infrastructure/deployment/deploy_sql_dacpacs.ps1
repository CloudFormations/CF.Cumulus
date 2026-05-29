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
    --verbosity quiet `
    /p:NetCoreBuild=true `
    /p:SqlServerVersion=Azure

Write-Host "Building control / ingest / transform in parallel..." -ForegroundColor Yellow
$buildJobs = @(
    Start-Job -Name "build-control" -ScriptBlock {
        dotnet build $using:sourceFolderPath\src\metadata.control\metadata.control.sqlproj `
            --configuration $using:configuration --verbosity quiet /p:NetCoreBuild=true /p:SqlServerVersion=Azure
    }
    Start-Job -Name "build-ingest" -ScriptBlock {
        dotnet build $using:sourceFolderPath\src\metadata.ingest\metadata.ingest.sqlproj `
            --configuration $using:configuration --verbosity quiet /p:NetCoreBuild=true /p:SqlServerVersion=Azure
    }
    Start-Job -Name "build-transform" -ScriptBlock {
        dotnet build $using:sourceFolderPath\src\metadata.transform\metadata.transform.sqlproj `
            --configuration $using:configuration --verbosity quiet /p:NetCoreBuild=true /p:SqlServerVersion=Azure
    }
)

if ($deployData) {
    $buildJobs += Start-Job -Name "build-data" -ScriptBlock {
        dotnet build $using:sourceFolderPath\src\metadata.data\metadata.data.sqlproj `
            --configuration $using:configuration --verbosity quiet /p:NetCoreBuild=true /p:SqlServerVersion=Azure
    }
}

$buildJobs | Wait-Job | Receive-Job
$buildJobs | Remove-Job

# ============================================
# Publish the core set of DacPacs + PostDeployment Scripts
# Dependency order:
#   Phase 1: common   (no dependencies)
#   Phase 2: control  (references common objects)
#   Phase 3: ingest + transform in parallel (both reference common + control;
#            no cross-dependency between each other)
# ============================================

Write-Host "`nPhase 1: Publishing common schema objects..." -ForegroundColor Green
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
    /p:BlockOnPossibleDataLoss=false `
    /p:VerifyDeployment=false

Write-Host "`nPhase 2: Publishing control schema objects..." -ForegroundColor Green
SqlPackage /Action:Publish `
    "/SourceFile:$sourceFolderPath\src\metadata.control\bin\Debug\metadata.control.dacpac" `
    "/TargetConnectionString:$connStr" `
    /v:Environment=$environment `
    /v:RGName=$resourceGroupName `
    /v:SubscriptionID=$subscriptionId `
    /v:ADFName=$dataFactoryName `
    /v:TenantID=$tenantId `
    /p:ScriptDatabaseOptions=false `
    /p:BlockOnPossibleDataLoss=false `
    /p:VerifyDeployment=false

Write-Host "`nPhase 3: Publishing ingest + transform schemas in parallel..." -ForegroundColor Yellow
$publishJobs = @(
    Start-Job -Name "publish-ingest" -ScriptBlock {
        $src  = $using:sourceFolderPath
        $conn = $using:connStr
        SqlPackage /Action:Publish `
            "/SourceFile:$src\src\metadata.ingest\bin\Debug\metadata.ingest.dacpac" `
            "/TargetConnectionString:$conn" `
            /p:ScriptDatabaseOptions=false `
            /p:BlockOnPossibleDataLoss=false `
            /p:VerifyDeployment=false
    }
    Start-Job -Name "publish-transform" -ScriptBlock {
        $src  = $using:sourceFolderPath
        $conn = $using:connStr
        SqlPackage /Action:Publish `
            "/SourceFile:$src\src\metadata.transform\bin\Debug\metadata.transform.dacpac" `
            "/TargetConnectionString:$conn" `
            /p:ScriptDatabaseOptions=false `
            /p:BlockOnPossibleDataLoss=false `
            /p:VerifyDeployment=false
    }
)
$publishJobs | Wait-Job | Receive-Job
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
# Create SQL auth user for ADF (cumulus_adf_user)
# ============================================
Write-Host "Creating SQL auth user for ADF..."
$rng         = [System.Security.Cryptography.RandomNumberGenerator]::Create()
$pwdBytes    = New-Object byte[] 24; $rng.GetBytes($pwdBytes)
$adfPassword = 'Cf2@' + [Convert]::ToBase64String($pwdBytes).TrimEnd('=').Replace('+','p').Replace('/','q')

az keyvault secret set `
    --vault-name $keyVaultName `
    --name "$sqlServerName-adfpassword" `
    --value $adfPassword `
    --output none

$escapedAdfPwd = $adfPassword.Replace("'", "''")
$adfUserSql = @"
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'cumulus_adf_user' AND type_desc = 'SQL_USER')
    CREATE USER [cumulus_adf_user] WITH PASSWORD = '$escapedAdfPwd';
ELSE
    ALTER USER [cumulus_adf_user] WITH PASSWORD = '$escapedAdfPwd';

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'db_cumulususer' AND type = 'R')
    CREATE ROLE [db_cumulususer];

GRANT EXECUTE, SELECT, INSERT, UPDATE, DELETE, CONTROL, ALTER ON SCHEMA::[common]    TO [db_cumulususer];
GRANT EXECUTE, SELECT, INSERT, UPDATE, DELETE, CONTROL, ALTER ON SCHEMA::[control]   TO [db_cumulususer];
GRANT EXECUTE, SELECT, INSERT, UPDATE, DELETE, CONTROL, ALTER ON SCHEMA::[ingest]    TO [db_cumulususer];
GRANT EXECUTE, SELECT, INSERT, UPDATE, DELETE, CONTROL, ALTER ON SCHEMA::[transform] TO [db_cumulususer];

IF NOT EXISTS (
    SELECT 1 FROM sys.database_role_members rm
    JOIN sys.database_principals r ON r.principal_id = rm.role_principal_id AND r.name = 'db_cumulususer'
    JOIN sys.database_principals m ON m.principal_id = rm.member_principal_id AND m.name = 'cumulus_adf_user')
    ALTER ROLE [db_cumulususer] ADD MEMBER [cumulus_adf_user];
"@

Invoke-Sqlcmd `
    -ServerInstance "$sqlServerName.database.windows.net" `
    -Database       $sqlDatabaseName `
    -Username       $sqlLogin `
    -Password       $sqlPassword `
    -Query          $adfUserSql `
    -TrustServerCertificate `
    -ConnectionTimeout 60
Write-Host "ADF SQL user 'cumulus_adf_user' created/updated in database"

Remove-Variable sqlPassword
Remove-Variable adfPassword

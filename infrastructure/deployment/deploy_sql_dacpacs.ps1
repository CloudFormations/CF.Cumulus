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
# ============================================

Write-Host "Building SQL DACPAC projects..." -ForegroundColor Green
$configuration = "Debug"

Write-Host "Building common SQL DACPAC project..." c
dotnet build "$sourceFolderPath\src\metadata.common\metadata.common.sqlproj" `
    --configuration $configuration `
    /p:NetCoreBuild=true `
    /p:SqlServerVersion=Azure

# Write-Host "Building control SQL DACPAC project..." -ForegroundColor Yellow
# dotnet build "$sourceFolderPath\src\metadata.control\metadata.control.sqlproj" `
#     --configuration $configuration `
#     /p:NetCoreBuild=true `
#     /p:SqlServerVersion=Azure

# Write-Host "Building ingest SQL DACPAC project..." -ForegroundColor Yellow
# dotnet build "$sourceFolderPath\src\metadata.ingest\metadata.ingest.sqlproj" `
#     --configuration $configuration `
#     /p:NetCoreBuild=true `
#     /p:SqlServerVersion=Azure

# Write-Host "Building transform SQL DACPAC project..." -ForegroundColor Yellow
# dotnet build "$sourceFolderPath\src\metadata.transform\metadata.transform.sqlproj" `
#     --configuration $configuration `
#     /p:NetCoreBuild=true `
#     /p:SqlServerVersion=Azure

# if ($deployData) {
#     Write-Host "Building data SQL DACPAC project..." -ForegroundColor Yellow
#     dotnet build "$sourceFolderPath\src\metadata.data\metadata.data.sqlproj" `
#         --configuration $configuration `
#         /p:NetCoreBuild=true `
#         /p:SqlServerVersion=Azure
# }

# ============================================
# Publish the core set of DacPacs + PostDeployment Scripts
# ============================================

Write-Host "Publishing the common schema objects..." -ForegroundColor Green
SqlPackage /Action:Publish `
    /SourceFile:"$sourceFolderPath\src\metadata.common\bin\Debug\metadata.common.dacpac" `
    /TargetConnectionString:"Server=tcp:$sqlServerName.database.windows.net,1433;Initial Catalog=$sqlDatabaseName;Persist Security Info=False;User ID=$sqlLogin;Password=$sqlPassword;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;" `
    /v:DatabricksWSName=$databricksWorkspaceName `
    /v:DatabricksHost="https://$databricksWorkspaceURL" `
    /v:DLSName=$storageAccountName `
    /v:Environment=$environment `
    /v:KeyVaultName=$keyVaultName `
    /v:RGName=$resourceGroupName `
    /v:SubscriptionID=$subscriptionId `
    /DeployReportPath:"$sourceFolderPath\src\metadata.core\deploy-report.xml"

# Write-Host "Publishing the control schema objects..." -ForegroundColor Yellow
# SqlPackage /Action:Publish `
#     /SourceFile:"$sourceFolderPath\src\metadata.control\bin\Debug\metadata.control.dacpac" `
#     /TargetConnectionString:"Server=tcp:$sqlServerName.database.windows.net,1433;Initial Catalog=$sqlDatabaseName;Persist Security Info=False;User ID=$sqlLogin;Password=$sqlPassword;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;" `
#     /v:Environment=$environment `
#     /v:RGName=$resourceGroupName `
#     /v:SubscriptionID=$subscriptionId `
#     /v:ADFName=$dataFactoryName `
#     /v:TenantID=$tenantId `
#     /DeployReportPath:"$sourceFolderPath\src\metadata.core\deploy-report.xml"

# Write-Host "Publishing the ingest schema objects..." -ForegroundColor Yellow
# SqlPackage /Action:Publish `
#     /SourceFile:"$sourceFolderPath\src\metadata.ingest\bin\Debug\metadata.ingest.dacpac" `
#     /TargetConnectionString:"Server=tcp:$sqlServerName.database.windows.net,1433;Initial Catalog=$sqlDatabaseName;Persist Security Info=False;User ID=$sqlLogin;Password=$sqlPassword;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;" `
#     /DeployReportPath:"$sourceFolderPath\src\metadata.core\deploy-report.xml"
    
# Write-Host "Publishing the transform schema objects..." -ForegroundColor Yellow
# SqlPackage /Action:Publish `
#     /SourceFile:"$sourceFolderPath\src\metadata.transform\bin\Debug\metadata.transform.dacpac" `
#     /TargetConnectionString:"Server=tcp:$sqlServerName.database.windows.net,1433;Initial Catalog=$sqlDatabaseName;Persist Security Info=False;User ID=$sqlLogin;Password=$sqlPassword;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;" `
#     /DeployReportPath:"$sourceFolderPath\src\metadata.core\deploy-report.xml"

# # ============================================
# # Publish the data PostDeployment Scripts
# # ============================================
# if ($deployData) {
#     Write-Host "Publishing and populating the metadata-as-code ..." -ForegroundColor Yellow
#     SqlPackage /Action:Publish `
#         /SourceFile:"$sourceFolderPath\src\metadata.data\bin\Debug\metadata.data.dacpac" `
#         /TargetConnectionString:"Server=tcp:$sqlServerName.database.windows.net,1433;Initial Catalog=$sqlDatabaseName;Persist Security Info=False;User ID=$sqlLogin;Password=$sqlPassword;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;" `
#         /v:ADFName=$dataFactoryName `
#         /v:DemoConnectionLocation=$demoConnectionLocation `
#         /v:DemoKVSecret=$demoKVSecret `
#         /v:DemoLinkedService=$demoLinkedService `
#         /v:DemoResourceName=$demoResourceName `
#         /v:DemoSourceLocation=$demoSourceLocation `
#         /v:DemoUsername=$demoUsername
# }

# # ============================================
# # Set Entra AD Admin to current user
# # ============================================
# Write-Host "Setting current user as Entra AD Admin..."
# $userDetails = az ad signed-in-user show --query userPrincipalName --output tsv
# $userId = az ad signed-in-user show --query id --output tsv
# az sql server ad-admin create --resource-group $resourceGroupName --server $sqlServerName --display-name $userDetails --object-id $userId

# # ============================================
# # Provision Role assignments for ADF SPN
# # ============================================
# Write-Host "Grant Access for ADF on Metadata Database..."
# $createADFUserScript = $currentLocation + '\grant_adf_access.ps1'
# & $createADFUserScript `
#     -sqlServerName $sqlServerName `
#     -sqlDatabaseName $sqlDatabaseName `
#     -dataFactoryName $dataFactoryName

# Remove-Variable sqlPassword 

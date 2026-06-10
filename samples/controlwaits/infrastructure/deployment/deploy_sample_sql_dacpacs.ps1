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
    [string] $dataFactoryName
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

$configuration = "Debug"
$connStr       = "Server=tcp:$sqlServerName.database.windows.net,1433;Initial Catalog=$sqlDatabaseName;Persist Security Info=False;User ID=$sqlLogin;Password=$sqlPassword;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"

Write-Host "`nBuilding samples..." -ForegroundColor Green
dotnet build "$sourceFolderPath\src\metadata.samples\metadata.samples.sqlproj" `
    --configuration $configuration `
    /p:NetCoreBuild=true `
    /p:SqlServerVersion=Azure

# ============================================
# Publish the samples DacPac
# ============================================
Write-Host "`nPublishing samples schema objects..." -ForegroundColor Green
SqlPackage /Action:Publish `
    "/SourceFile:$sourceFolderPath\src\metadata.samples\bin\Debug\metadata.samples.dacpac" `
    "/TargetConnectionString:$connStr" `
    /v:ADFName=$dataFactoryName `
    /p:ScriptDatabaseOptions=false
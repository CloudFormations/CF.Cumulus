# ============================================
# Parameters
# ============================================
param(
    [Parameter(Mandatory = $true)]
    [string] $currentLocation,
    
    [Parameter(Mandatory = $true)]
    [string] $resourceGroupName,

    [Parameter(Mandatory = $true)]
    [string] $functionAppName,
    
    [Parameter(Mandatory = $true)]
    [string] $keyVaultName
)

# ============================================
# Paths
# ============================================
$sourceFolderPath = $currentLocation -replace '\\infrastructure\\deployment'
$functionAppPath  = Join-Path $sourceFolderPath 'src\azure.functionapp'
$publishPath      = Join-Path $currentLocation 'publishFunctions'

# ============================================
# Clean project output
# ============================================
dotnet clean `
    $functionAppPath `
    --configuration Release `
    /property:GenerateFullPaths=true `
    /consoleloggerparameters:NoSummary

# ============================================
# Publish Function App
# ============================================
dotnet publish `
    $functionAppPath `
    --configuration Release `
    --output $publishPath

# ============================================
# Create deployment ZIP
# ============================================
$sourcePath = $publishPath + '/*'
Compress-Archive -Path $sourcePath -DestinationPath ./funcapp.zip -Update

# ============================================
# Deploy ZIP package to Azure Function App
# ============================================
az functionapp deployment source config-zip `
    --resource-group $resourceGroupName `
    --name $functionAppName `
    --src ./funcapp.zip

# ============================================
# Store Function App Master Key in Key Vault
# ============================================
$functionAppKeys      = az functionapp keys list -g $resourceGroupName -n $functionAppName | ConvertFrom-Json
$functionAppMasterKey = $functionAppKeys.masterKey

az keyvault secret set `
    --vault-name $keyVaultName `
    --name "cumulusfunctionsKey" `
    --value $functionAppMasterKey
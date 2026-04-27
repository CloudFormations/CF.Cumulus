# ============================================
# Target Resources
# ============================================
$tenantId                = ""
$subscriptionName        = ""
$subscriptionId          = ""
$location                = ""
$resourceGroupName       = ""
$keyVaultName            = ""
$keyVaultId              = ""
$keyVaultUri             = ""
$governKeyVaultName      = ""
$governKeyVaultId        = ""
$governKeyVaultUri       = ""
$databricksWorkspaceName = ""
$databricksWorkspaceURL  = ""
$storageAccountName      = ""
$governStorageAccountName = ""
$functionAppName         = ""
$dataFactoryName         = ""
$sqlServerName           = ""
$sqlDatabaseName         = ""

# ============================================
# Logging Information
# ============================================
function ParseTimeValue {
    param(
        $processTimerInterim
    )
    $elapsedTimeInterim = "{0:00}:{1:00}:{2:00}.{3:00}" -f `
    $processTimerInterim.Hours, `
    $processTimerInterim.Minutes, `
    $processTimerInterim.Seconds, `
    ($processTimerInterim.Milliseconds / 10)

    return $elapsedTimeInterim
}
$processTimerStart = [System.Diagnostics.Stopwatch]::StartNew()

$infoTime = ParseTimeValue -processTimerInterim $processTimerStart.Elapsed
Write-Host "Starting Deployment. $infoTime`r`n" -ForegroundColor Yellow

# ============================================
# Determine script location
# ============================================
$currentLocation = Split-Path -Path $MyInvocation.MyCommand.Path -Parent

$infoTime = ParseTimeValue -processTimerInterim $processTimerStart.Elapsed
Write-Host "Current Path Set. $infoTime`r`n" -ForegroundColor Yellow

# ============================================
# Pre-execution module checks
# ============================================
$checkImportsScript = Join-Path $currentLocation "check_imports.ps1"
& $checkImportsScript

$infoTime = ParseTimeValue -processTimerInterim $processTimerStart.Elapsed
Write-Host "Predeployment Checks Done. $infoTime`r`n" -ForegroundColor Yellow

# ============================================
# Authenticate using Azure CLI
# ============================================
az login --tenant $tenantId

$subscriptionId = az account list `
    --query "[?name=='${subscriptionName}'].id" `
    --output tsv

$infoTime = ParseTimeValue -processTimerInterim $processTimerStart.Elapsed
Write-Host "Authenticated to Azure. $infoTime`r`n" -ForegroundColor Yellow

# ============================================
# Authenticate Azure PowerShell
# ============================================
Connect-AzAccount -SubscriptionId $subscriptionId

$infoTime = ParseTimeValue -processTimerInterim $processTimerStart.Elapsed
Write-Host "Connected to Subscription. $infoTime`r`n" -ForegroundColor Yellow

# ============================================
# Create Data Lake Containers
# ============================================
$deployStorageContainersScript = Join-Path $currentLocation "deploy_storage_containers.ps1"

& $deployStorageContainersScript `
    -SubscriptionId $subscriptionId
    -ResourceGroupName $resourceGroupName
    -StorageAccountName $storageAccountName
    -Containers @("raw, cleansed, curated")

$infoTime = ParseTimeValue -processTimerInterim $processTimerStart.Elapsed
Write-Host "Deployed Primary Data Lake Containers. $infoTime`r`n" -ForegroundColor Yellow

& $deployStorageContainersScript `
    -SubscriptionId $subscriptionId
    -ResourceGroupName $resourceGroupName
    -StorageAccountName $governStorageAccountName
    -Containers @("govern")

$infoTime = ParseTimeValue -processTimerInterim $processTimerStart.Elapsed    
Write-Host "Deployed Govern Data Lake Containers. $infoTime`r`n" -ForegroundColor Yellow

# ============================================
# Grant Key Vault Secrets Officer to User
# ============================================
$userDetails = az ad signed-in-user show | ConvertFrom-Json
$userId = $userDetails.id

az role assignment create `
    --role "Key Vault Secrets Officer" `
    --assignee $userId `
    --scope "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.KeyVault/vaults/$keyVaultName"

$infoTime = ParseTimeValue -processTimerInterim $processTimerStart.Elapsed
Write-Host "Set User Key Vault Access. $infoTime`r`n" -ForegroundColor Yellow

# ============================================
# Deploy Azure Functions
# ============================================
$deployAzureFunctionsScript = Join-Path $currentLocation "deploy_azure_functions.ps1"

& $deployAzureFunctionsScript `
    -currentLocation $currentLocation `
    -resourceGroupName $resourceGroupName `
    -functionAppName $functionAppName `
    -keyVaultName $keyVaultName

$infoTime = ParseTimeValue -processTimerInterim $processTimerStart.Elapsed
Write-Host "Deployed Functions. $infoTime`r`n" -ForegroundColor Yellow

# ============================================
# Configure environment variables (Data Factory)
# ============================================
$Env:SQLSERVER   = $sqlServerName 
$Env:SQLDATABASE = $sqlDatabaseName 
$Env:DATAFACTORY = $dataFactoryName 
$Env:FUNCTIONAPP = $functionAppName 
$Env:KEYVAULT    = $keyVaultName 

$infoTime = ParseTimeValue -processTimerInterim $processTimerStart.Elapsed
Write-Host "Set Environment Variables for Data Factory. $infoTime`r`n" -ForegroundColor Yellow

# ============================================
# Deploy Data Factory components
# ============================================
$deployDataFactoryComponentsScript = Join-Path $currentLocation "deploy_data_factory_components.ps1"

& $deployDataFactoryComponentsScript `
    -tenantId $tenantId `
    -subscriptionName $subscriptionName `
    -location $location `
    -resourceGroupName $resourceGroupName `
    -dataFactoryName $dataFactoryName

$infoTime = ParseTimeValue -processTimerInterim $processTimerStart.Elapsed
Write-Host "Deployed Data Factory Artifacts. $infoTime`r`n" -ForegroundColor Yellow

# ============================================
# Deploy Databricks Resources
# ============================================
$deployDatabricksResourcesScript = Join-Path $currentLocation "deploy_databricks_resources.ps1"

& $deployDatabricksResourcesScript `
    -subscriptionId $subscriptionId `
    -resourceGroupName $resourceGroupName `
    -keyVaultName $keyVaultName `
    -keyVaultId $keyVaultId `
    -keyVaultUri $keyVaultUri `
    -databricksWorkspaceURL $databricksWorkspaceURL `
    -storageAccountName $storageAccountName

$infoTime = ParseTimeValue -processTimerInterim $processTimerStart.Elapsed
Write-Host "Deployed Databricks Primary Artifacts. $infoTime`r`n" -ForegroundColor Yellow

# ============================================
# Deploy Govern Databricks Resources
# ============================================
$deployDatabricksResourcesScript = Join-Path $currentLocation "deploy_databricks_resources_govern.ps1"

& $deployDatabricksResourcesScript `
    -subscriptionId $subscriptionId `
    -resourceGroupName $resourceGroupName `
    -keyVaultName $governKeyVaultName `
    -keyVaultId $governKeyVaultId `
    -keyVaultUri $governKeyVaultUri `
    -databricksWorkspaceURL $databricksWorkspaceURL `
    -storageAccountName $storageAccountName `
    -governStorageAccountName $governStorageAccountName

$infoTime = ParseTimeValue -processTimerInterim $processTimerStart.Elapsed
Write-Host "Deployed Databricks Govern Artifacts. $infoTime`r`n" -ForegroundColor Yellow

# ============================================
# Deploy SQL DACPACs
# ============================================
$deploySQLDacPacsScript = Join-Path $currentLocation "deploy_sql_dacpacs.ps1"

& $deploySQLDacPacsScript `
    -tenantId $tenantId `
    -subscriptionId $subscriptionId `
    -keyVaultName $keyVaultName `
    -sqlServerName $sqlServerName `
    -sqlDatabaseName $sqlDatabaseName `
    -databricksWorkspaceName $databricksWorkspaceName `
    -databricksWorkspaceURL $databricksWorkspaceURL `
    -storageAccountName $storageAccountName `
    -resourceGroupName $resourceGroupName `
    -dataFactoryName $dataFactoryName

$infoTime = ParseTimeValue -processTimerInterim $processTimerStart.Elapsed
Write-Host "Deployed SQL DACPAC. $infoTime`r`n" -ForegroundColor Yellow

# ============================================
# Cleanup
# ============================================
$Env:SQLSERVER   = ""
$Env:SQLDATABASE = ""
$Env:DATAFACTORY = ""
$Env:FUNCTIONAPP = ""
$Env:KEYVAULT    = ""

$infoTime = ParseTimeValue -processTimerInterim $processTimerStart.Elapsed
Write-Host "Deployment Complete. $infoTime`r`n" -ForegroundColor Yellow
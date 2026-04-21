# ============================================
# Parameters
# ============================================
param(
    [Parameter(Mandatory = $true)]
    [string] $tenantId,

    [Parameter(Mandatory = $true)]
    [string] $subscriptionName,

    [Parameter(Mandatory = $true)]
    [string] $location,
    
    [Parameter(Mandatory = $false)]
    [string] $templateFile = "infrastructure/main.bicep",
    
    [Parameter(Mandatory = $false)]
    [string] $parametersFile = "infrastructure/configuration/_installation/main.bicepparam"
)

# ============================================
# Determine script location
# ============================================
$currentLocation = Split-Path -Path $MyInvocation.MyCommand.Path -Parent

# ============================================
# Pre-execution module checks
# ============================================
$checkImportsScript = Join-Path $currentLocation "check_imports.ps1"
& $checkImportsScript

# ============================================
# Authenticate Azure CLI
# ============================================
az login --tenant $tenantId

$subscriptionId = az account list `
    --all `
    --query "[?name=='$subscriptionName'].id" `
    --output tsv
    
# ============================================
# Authenticate Azure PowerShell
# ============================================
Connect-AzAccount -Tenant $tenantId -SubscriptionId $subscriptionId

# ============================================
# Validate parameters
# ============================================
$checkParamsScript = Join-Path $currentLocation "check_params_from_file.ps1"
& $checkParamsScript -parametersFile $parametersFile

$acceptInput = Read-Host "Are the utilised parameters correct? (Y to confirm, anything else to cancel)"

if ($acceptInput.ToUpper() -eq "Y") {
    Write-Host "Proceeding with deployment..."
}
else {
    Write-Host "Cancelling deployment."
    exit
}

# ============================================
# Start Timer
# ============================================
$processTimerStart = [System.Diagnostics.Stopwatch]::StartNew()

# ============================================
# Deploy Bicep Template
# ============================================
$bicepDeployment = az deployment sub create `
    --subscription $subscriptionName `
    --location $location `
    --template-file $templateFile `
    --parameters $parametersFile |
    ConvertFrom-Json

# ============================================
# Extract Bicep Outputs
# ============================================
$resourceGroupName      = $bicepDeployment.properties.outputs.rgName.value
$keyVaultName           = $bicepDeployment.properties.outputs.keyVaultName.value
$keyVaultId             = $bicepDeployment.properties.outputs.keyVaultId.value
$keyVaultUri            = $bicepDeployment.properties.outputs.keyVaultUri.value
$databricksWorkspaceName = $bicepDeployment.properties.outputs.databricksWorkspaceName.value
$databricksWorkspaceURL  = $bicepDeployment.properties.outputs.databricksWorkspaceURL.value
$storageAccountName      = $bicepDeployment.properties.outputs.storageAccountName.value
$functionAppName         = $bicepDeployment.properties.outputs.functionAppName.value
$dataFactoryName         = $bicepDeployment.properties.outputs.dataFactoryName.value
$sqlServerName           = $bicepDeployment.properties.outputs.sqlServerName.value
$sqlDatabaseName         = $bicepDeployment.properties.outputs.sqlDatabaseName.value

# ============================================
# Grant Key Vault Secrets Officer to User
# ============================================
$userDetails = az ad signed-in-user show | ConvertFrom-Json
$userId      = $userDetails.id

az role assignment create `
    --role "Key Vault Secrets Officer" `
    --assignee $userId `
    --scope "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.KeyVault/vaults/$keyVaultName"

# ============================================
# Deploy Azure Functions
# ============================================
$deployAzureFunctionsScript = Join-Path $currentLocation "deploy_azure_functions.ps1"

& $deployAzureFunctionsScript `
    -currentLocation $currentLocation `
    -resourceGroupName $resourceGroupName `
    -functionAppName $functionAppName `
    -keyVaultName $keyVaultName

# ============================================
# Set environment variables for ADF deployments
# ============================================
$Env:SQLSERVER   = $sqlServerName 
$Env:SQLDATABASE = $sqlDatabaseName 
$Env:DATAFACTORY = $dataFactoryName 
$Env:FUNCTIONAPP = $functionAppName 
$Env:KEYVAULT    = $keyVaultName 

# ============================================
# Deploy Data Factory Components
# ============================================
$deployDataFactoryComponentsScript = Join-Path $currentLocation "deploy_data_factory_components.ps1"

& $deployDataFactoryComponentsScript `
    -tenantId $tenantId `
    -subscriptionName $subscriptionName `
    -location $location `
    -resourceGroupName $resourceGroupName `
    -dataFactoryName $dataFactoryName

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

# ============================================
# Interim Timer
# ============================================
$processTimerInterim = $processTimerStart.Elapsed
$elapsedTimeInterim = "{0:00}:{1:00}:{2:00}.{3:00}" -f `
    $processTimerInterim.Hours, `
    $processTimerInterim.Minutes, `
    $processTimerInterim.Seconds, `
    ($processTimerInterim.Milliseconds / 10)

Write-Host "Penultimate Deployment Complete! Elapsed Time $elapsedTimeInterim`r`n"

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

# ============================================
# Final Timer
# ============================================
$processTimerEnd = $processTimerStart.Elapsed
$elapsedTime = "{0:00}:{1:00}:{2:00}.{3:00}" -f `
    $processTimerEnd.Hours, `
    $processTimerEnd.Minutes, `
    $processTimerEnd.Seconds, `
    ($processTimerEnd.Milliseconds / 10)

Write-Host "Deployment Complete! Elapsed Time $elapsedTime`r`n"

# ============================================
# Cleanup - Clear environment variables
# ============================================
$Env:SQLSERVER   = ""
$Env:SQLDATABASE = ""
$Env:DATAFACTORY = ""
$Env:FUNCTIONAPP = ""
$Env:KEYVAULT    = ""
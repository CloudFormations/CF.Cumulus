#Assigining the parameters for the environment
param(
    [Parameter(Mandatory=$true)]
    [string] $tenantId,

    [Parameter(Mandatory=$true)]
    [string] $subscriptionId,

    [Parameter(Mandatory=$true)]
    [string] $location,
    
    [Parameter(Mandatory=$false)]
    [string] $templateFile = "infrastructure/main.bicep",
    
    [Parameter(Mandatory=$false)]
    [string] $parametersFile = "infrastructure/configuration/_installation/main.bicepparam"
)

# Login to the Azure Tenant
az login --tenant $tenantId

$currentLocation = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
$checkParamsScript = $currentLocation + '\check_params_from_file.ps1'
& $checkParamsScript `
    -parametersFile $parametersFile

$acceptInput = Read-Host "Are the utilised parameters correct? (Y) yes, (all other input) no. Press enter to confirm."

if ( $acceptInput.ToUpper() -eq "Y")
{
    Write-Host "Proceed with deployment"
}
else {
    Write-Host "Cancelling deployment"
    exit
}

# DEMO: Start a timer
$processTimerStart = [System.Diagnostics.Stopwatch]::StartNew()

# Run the *main*.bicep file to deploy your resources to Azure as per your configuration file
$bicepDeployment = az deployment sub create `
    --subscription $subscriptionId `
    --location $location `
    --template-file $templateFile `
    --parameters $parametersFile `
    | ConvertFrom-Json

# Save Outputs of reusable details from BiCep for other scripts
$resourceGroupName = $bicepDeployment.properties.outputs.rgName.value
$keyVaultName = $bicepDeployment.properties.outputs.keyVaultName.value
$keyVaultId = $bicepDeployment.properties.outputs.keyVaultId.value
$keyVaultUri = $bicepDeployment.properties.outputs.keyVaultUri.value
$databricksWorkspaceName = $bicepDeployment.properties.outputs.databricksWorkspaceName.value
$databricksWorkspaceURL = $bicepDeployment.properties.outputs.databricksWorkspaceURL.value
$storageAccountName = $bicepDeployment.properties.outputs.storageAccountName.value
$functionAppName = $bicepDeployment.properties.outputs.functionAppName.value
$dataFactoryName = $bicepDeployment.properties.outputs.dataFactoryName.value
$sqlServerName = $bicepDeployment.properties.outputs.sqlServerName.value
$sqlDatabaseName = $bicepDeployment.properties.outputs.sqlDatabaseName.value


$currentLocation = Split-Path -Path $MyInvocation.MyCommand.Path -Parent

# Get Subscription Id from Name
$subscriptionIdValue = az account list --query "[?name=='${subscriptionId}'].id" --output tsv

# Grant User Key Vault Secret Administrator RBAC to save Function App Key to KV
$userDetails = az ad signed-in-user show | ConvertFrom-Json
$userId = $userDetails.id
az role assignment create --role "Key Vault Secrets Officer" --assignee $userId --scope "/subscriptions/$subscriptionIdValue/resourceGroups/$resourceGroupName/providers/Microsoft.KeyVault/vaults/$keyVaultName"

# Grant Databricks Key Vault Secrets User RBAC to read secrets from KV
# Get Databricks Object Id
$databricksDetails = az ad sp list --query "[?displayName=='AzureDatabricks']" | ConvertFrom-Json

az role assignment create --assignee-object-id $databricksDetails.id --role "Key Vault Secrets User" --scope "/subscriptions/$subscriptionIdValue/resourceGroups/$resourceGroupName/providers/Microsoft.KeyVault/vaults/$keyVaultName"

# Deploy the C# Functions to the Function App
$deployAzureFunctionsScript = $currentLocation + '\deploy_azure_functions.ps1'
& $deployAzureFunctionsScript `
    -currentLocation $currentLocation `
    -resourceGroupName $resourceGroupName `
    -functionAppName $functionAppName


# Set environment variables for Data Factory LS deployments:
# Set environment variables up for other PS script executions
$Env:SQLSERVER = $sqlServerName 
$Env:SQLDATABASE = $sqlDatabaseName 
$Env:DATAFACTORY = $dataFactoryName 
$Env:FUNCTIONAPP = $functionAppName 
$Env:KEYVAULT = $keyVaultName 

# Deploy Data Factory objects to Data Factory
$deployDataFactoryComponentsScript = $currentLocation + '\deploy_data_factory_components.ps1'
& $deployDataFactoryComponentsScript `
    -tenantId $tenantId `
    -subscriptionId $subscriptionId `
    -location $location `
    -resourceGroupName $resourceGroupName `
    -dataFactoryName $dataFactoryName

# Deploy Databricks Resources
    # Includes: Create PAT
    # Includes: Create Secret Scope
    # Includes: Create Cluster with ADLS Secret configuration
    # Includes: Add notebooks to Workspace/Live folder path
$deployDatabricksResourcesScript = $currentLocation + '\deploy_databricks_resources.ps1'
& $deployDatabricksResourcesScript `
    -keyVaultId $keyVaultId `
    -keyVaultUri $keyVaultUri `
    -databricksWorkspaceURL $databricksWorkspaceURL `
    -storageAccountName $storageAccountName


# Demo interim duration logging + surfacing
$processTimerInterim = $processTimerStart.Elapsed
$elapsedTimeInterim = "{0:00}:{1:00}:{2:00}.{3:00}" -f $processTimerInterim.Hours, $processTimerInterim.Minutes, $tprocessTimerInterim.Seconds, ($processTimerInterim.Milliseconds / 10)
Write-Host "Penultimate Deployment Complete! Elapsed Time $elapsedTimeInterim `r`n"

# Deploy the SQL Server Metadata objects
# Child script: Create common Schema Objects
    # Includes: Publish DacPacs to the instance
    # Includes: Create user for ADF, create role, grant role permissions, add user to role
$deploySQLDacPacsScript = $currentLocation + '\deploy_sql_dacpacs.ps1'
& $deploySQLDacPacsScript `
    -tenantId $tenantId `
    -subscriptionIdValue $subscriptionIdValue `
    -keyVaultName $keyVaultName `
    -sqlServerName $sqlServerName `
    -sqlDatabaseName $sqlDatabaseName `
    -databricksWorkspaceName $databricksWorkspaceName `
    -databricksWorkspaceURL $databricksWorkspaceURL `
    -storageAccountName $storageAccountName `
    -resourceGroupName $resourceGroupName `
    -dataFactoryName $dataFactoryName


# Demo duration logging + surfacing
$processTimerEnd = $processTimerStart.Elapsed
$elapsedTime = "{0:00}:{1:00}:{2:00}.{3:00}" -f $processTimerEnd.Hours, $processTimerEnd.Minutes, $tprocessTimerEnd.Seconds, ($processTimerEnd.Milliseconds / 10)
Write-Host "Deployment Complete! Elapsed Time $elapsedTime `r`n"

# Cleanup Actions:

# Remove unrequired environment variables
# Set environment variables up for other PS script executions
$Env:SQLSERVER = '' 
$Env:SQLDATABASE = '' 
$Env:DATAFACTORY = '' 
$Env:FUNCTIONAPP = '' 
$Env:KEYVAULT = '' 


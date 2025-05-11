#Assigining the parameters for the environment
param(
    [Parameter(Mandatory=$true)]
    [string] $tenantId,

    [Parameter(Mandatory=$true)]
    [string] $subscriptionId,

    [Parameter(Mandatory=$true)]
    [string] $location,
    
    [Parameter(Mandatory=$true)]
    [string] $templateFile,
    
    [Parameter(Mandatory=$true)]
    [string] $parametersFile
)

# Login to the Azure Tenant
az login --tenant $tenantId

# Run the *main*.bicep file to deploy your resources to Azure as per your configuration file
$bicepDeployment = az deployment sub create `
    --subscription $subscriptionId `
    --location $location `
    --template-file $templateFile `
    --parameters $parametersFile `
    # --what-if
    | ConvertFrom-Json

# Save Outputs of reusable details from BiCep for other scripts
$resourceGroupName = $bicepDeployment.properties.outputs.rgName.value
$keyVaultName = $bicepDeployment.properties.outputs.keyVaultName.value
$keyVaultId = $bicepDeployment.properties.outputs.keyVaultId.value
$keyVaultUri = $bicepDeployment.properties.outputs.keyVaultUri.value
$databricksWorkspaceURL = $bicepDeployment.properties.outputs.databricksWorkspaceURL.value
$storageAccountName = $bicepDeployment.properties.outputs.storageAccountName.value
$functionAppName = $bicepDeployment.properties.outputs.functionAppName.value
$dataFactoryName = $bicepDeployment.properties.outputs.dataFactoryName.value
$sqlServerName = $bicepDeployment.properties.outputs.sqlServerName.value
$sqlDatabaseName = $bicepDeployment.properties.outputs.sqlDatabaseName.value

# # Read resource names from configuration/_installation/main.bicepparam file for confirmation on naming convention
# $deployedResourceScript = $currentLocation + '\get_deployed_resources.ps1'
# & $deployedResourceScript -resourceGroupName $resourceGroupName

$currentLocation = Split-Path -Path $MyInvocation.MyCommand.Path -Parent

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


# Deploy the SQL Server Metadata objects
    # Child script: Create control Schema Objects
    # Child script: Create common Schema Objects
    # Child script: Create ingest Schema Objects
    # Child script: Create transform Schema Objects
    # Child script: Query Databricks Workspace URL
    # Child script: Populate Default values for control, common
    # Child script: Create user for ADF, create role, add user to role
    
# Cleanup Actions:

# Remove unrequired environment variables
# Set environment variables up for other PS script executions
$Env:SQLSERVER = '' 
$Env:SQLDATABASE = '' 
$Env:DATAFACTORY = '' 
$Env:FUNCTIONAPP = '' 
$Env:KEYVAULT = '' 

# Remove Databricks Profile Config file

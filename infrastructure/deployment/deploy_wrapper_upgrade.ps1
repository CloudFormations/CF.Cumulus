#Assigining the parameters for the environment
param(
    [Parameter(Mandatory=$true)]
    [string] $tenantId,

    [Parameter(Mandatory=$true)]
    [string] $subscriptionId,

    [Parameter(Mandatory=$true)]
    [string] $location,

    [Parameter(Mandatory=$true)]
    [string] $resourcePrefix,

    [Parameter(Mandatory=$true)]
    [string] $resourceSuffix,

    [Parameter(Mandatory=$false)]
    [string] $resourceGroupName = '',

    [Parameter(Mandatory=$false)]
    [string] $resourceGroupNamingConvention = 'rg',

    [Parameter(Mandatory=$false)]
    [string] $keyVaultNamingConvention = 'kv',

    [Parameter(Mandatory=$false)]
    [string] $storageAccountNamingConvention = 'dls',

    [Parameter(Mandatory=$false)]
    [string] $functionAppNamingConvention = 'func',

    [Parameter(Mandatory=$false)]
    [string] $dataFactoryNamingConvention = 'adf',

    [Parameter(Mandatory=$false)]
    [string] $sqlServerNamingConvention = 'sql',

    [Parameter(Mandatory=$false)]
    [string] $sqlDatabaseNamingConvention = 'sqldb',
    
    [Parameter(Mandatory=$false)]
    [string] $databricksNamingConvention = 'dbw'
)
# Login to the Azure Tenant
az login --tenant $tenantId
Connect-AzAccount

# DEMO: Start a timer
$processTimerStart = [System.Diagnostics.Stopwatch]::StartNew()

# Save Outputs of reusable details from BiCep for other scripts
if ($resourceGroupName -eq '') { 
    $resourceGroupName = $resourcePrefix + $resourceGroupNamingConvention + $resourceSuffix
}
else {
    $resourceGroupName = $resourceGroupName
}

$keyVaultName = $resourcePrefix + $keyVaultNamingConvention + $resourceSuffix
$storageAccountName = $resourcePrefix + $storageAccountNamingConvention + $resourceSuffix
$functionAppName = $resourcePrefix + $functionAppNamingConvention + $resourceSuffix
$dataFactoryName = $resourcePrefix + $dataFactoryNamingConvention + $resourceSuffix
$sqlServerName = $resourcePrefix + $sqlServerNamingConvention + $resourceSuffix
$sqlDatabaseName = $resourcePrefix + $sqlDatabaseNamingConvention + $resourceSuffix
$databricksWorkspaceName = $resourcePrefix + $databricksNamingConvention + $resourceSuffix

$currentLocation = Split-Path -Path $MyInvocation.MyCommand.Path -Parent

# Get Subscription Id from Name
$subscriptionDetails = az account subscription list | ConvertFrom-Json | Where-Object { $_.displayName -eq $subscriptionId }
$subscriptionIdValue = $subscriptionDetails.subscriptionId

$keyVaultId = az keyvault list --subscription $subscriptionIdValue --query "[?name=='$keyVaultName'].id" --output tsv
$keyVaultUri = "https://${keyVaultName}.vault.azure.net/"

$databricksWorkspaceURL = az databricks workspace show --name $databricksWorkspaceName --resource-group $resourceGroupName --subscription $subscriptionIdValue --query "workspaceUrl" --output tsv

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

# Upgrade script functionality: Add current IP address to Firewall
az sql server firewall-rule create -g $resourceGroupName -s $sqlServerName -n CumulusDeploymentIPRequirement --start-ip-address 51.194.125.40 --end-ip-address 51.194.125.40

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

# Upgrade script functionality: Delete current IP address from Firewall
az sql server firewall-rule delete  -g $resourceGroupName -s $sqlServerName -n CumulusDeploymentIPRequirement

# Demo duration logging + surfacing
$processTimerEnd = $processTimerStart.Elapsed
$elapsedTime = "{0:00}:{1:00}:{2:00}.{3:00}" -f $processTimerEnd.Hours, $processTimerEnd.Minutes, $tprocessTimerEnd.Seconds, ($processTimerEnd.Milliseconds / 10)
Write-Host "Deployment Complete! Elapsed Time $elapsedTime `r`n"

# # Cleanup Actions:

# # Remove unrequired environment variables
# # Set environment variables up for other PS script executions
# $Env:SQLSERVER = '' 
# $Env:SQLDATABASE = '' 
# $Env:DATAFACTORY = '' 
# $Env:FUNCTIONAPP = '' 
# $Env:KEYVAULT = '' 

# # Remove Databricks Profile Config file

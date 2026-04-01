#Assigining the parameters for the environment
param(
    [Parameter(Mandatory=$true)]
    [string] $resourceGroupName
)

$resources = az resource list --resource-group $resourceGroupName
$resources = $resources | ConvertFrom-Json

# Get resource names from response
$keyVault = $resources| Where-Object { $_.type -eq "Microsoft.KeyVault/vaults" }| ForEach-Object { $_.name }
$functionApp = $resources| Where-Object { $_.type -eq "Microsoft.Web/sites" }| ForEach-Object { $_.name }
$dataFactoryName = $resources| Where-Object { $_.type -eq "Microsoft.DataFactory/factories" }| ForEach-Object { $_.name }
$sqlServerName = $resources| Where-Object { $_.type -eq "Microsoft.Sql/servers" }| ForEach-Object { $_.name }
$sqlDatabaseName = $resources| Where-Object { $_.type -eq "Microsoft.Sql/servers/databases" }| ForEach-Object { $_.name }

# $applicationInsights = $resources| Where-Object { $_.type -eq "Microsoft.Insights/components" }| ForEach-Object { $_.name }
# $storageAccounts = $resources| Where-Object { $_.type -eq "Microsoft.Storage/storageAccounts" }| ForEach-Object { $_.name }

# Set environment variables up for other PS script executions
$Env:SQLSERVER = $sqlServerName 
$Env:SQLDATABASE = $sqlDatabaseName 
$Env:DATAFACTORY = $dataFactoryName 
$Env:FUNCTIONAPP = $functionApp 
$Env:KEYVAULT = $keyVault 

//  Main infrastructure deployment template for a CF.Cumulus data platform
//  Deploys core services including:
//  - Key Vault, Storage, Data Factory, Databricks, Function Apps, SQL Server
//  - Configures role assignments and dependencies between services

targetScope = 'subscription'

//Parameters for environment configuration
// * These parameters control resource naming and deployment options
// * Recommended for consistent resource naming across environments
param orgName string = 'cf'
param domainName string = 'cumulus'
param envName string = 'dev'
param location string = 'uksouth'
param uniqueIdentifier string = '01'

// SQL Server: Optional Parameters
param myIPAddress string = '1.1.1.1'// For SQL Server Firewall rule
param allowAzureServices bool = false// For allowing Azure services access to Azure SQL Server

//Parameter to add timestamp to activity deployment
param deploymentTimestamp string = utcNow('yy-MM-dd-HHmm')


// Mapping of Azure regions to short codes for naming conventions
var locationShortCodes = {
  uksouth: 'uks'
  ukwest: 'ukw'
  eastus: 'eus'
  westus: 'wus'
  westus2: 'wus2'
  centralus: 'cus'
  northcentralus: 'ncus'
  southcentralus: 'scus'
  eastus2: 'eus2'
  westeurope: 'weu'
  northeurope: 'neu'
  francecentral: 'frc'
  germanywestcentral: 'gwc'
  switzerlandnorth: 'swn'
  norwayeast: 'noe'
  brazilsouth: 'brs'
  canadacentral: 'cac'
  canadaeast: 'cae'
  swedencentral: 'sde'
}

var locationShortCode = locationShortCodes[location]

// Resource naming convention variables
var namePrefix = '${orgName}${domainName}${envName}'
var nameSuffix = '${locationShortCode}${uniqueIdentifier}'


// Resource Names
var rgName = '${namePrefix}rg${nameSuffix}'
var keyVaultName = '${namePrefix}kv${nameSuffix}'
var dataFactoryName = '${namePrefix}adf${nameSuffix}'
var sqlServerName = '${namePrefix}sql${nameSuffix}'
var sqlDatabaseName = '${namePrefix}sqldb${nameSuffix}'
var sampleSqlDatabaseName = '${namePrefix}advworks${nameSuffix}'



// Create resource group
resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: rgName
  location: location
}

// Deploy SQL Server with a basic blank database
module sqlServerDeploy './modules/sqlserver.template.bicep' =  {
  scope: rg
  name: 'sql-server${deploymentTimestamp}'
  params: {
    sqlServerName: sqlServerName
    sqlDatabaseName: sampleSqlDatabaseName
    myIPAddress: myIPAddress
    allowAzureServices: allowAzureServices
  }
}



// OUTPUTS
output rgName string = rgName
output keyVaultName string = keyVaultName
output dataFactoryName string = dataFactoryName
output sqlServerName string = sqlServerDeploy.outputs.sqlServerName
output sqlDatabaseName string = sqlDatabaseName
output sampleSqlDatabaseName string = sqlServerDeploy.outputs.databaseName

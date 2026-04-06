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

//Parameters for optional deployments
param deployADF bool = true
param deployWorkers bool = false      // if worker pipelines are to live in a separate data factory instance to the bootstrap pipelines
param deploySQL bool = true           // assumes SQL database is required to house metadata
param deployFunction bool = true      // exclude function app if already created or manual config is preferred later
param deployADBWorkspace bool = true  // exclude databricks if already created or manual config is preferred later
param setRoleAssignments bool = true

// Resoure Group Level: Optional Settings
param deployNetworking bool = false    // if custom VNet and specific IP address space is to be used
param deployVM bool = false           // if self hosted IR is required for data factory

//Parameters for configuration settings
@allowed(['premium','consumption', 'flex'])
param aspSKU string = 'flex'   // ASP SKU for function app

param configureGitHub bool = false    // if GitHub repo configuration is required for ADF deployment

@allowed(['Premium','Standard'])
param databricksSKU string = 'Premium'   // Databricks Workspace SKU


// SQL Server: Optional Parameters
param myIPAddress string = '1.1.1.1'// For SQL Server Firewall rule
param allowAzureServices bool = false// For allowing Azure services access to Azure SQL Server

// Storage: Optional naming configurations
param datalakeNameShort string = 'dls' //Storage account name prefix
param functionStorageNameShort string = 'st' //Function app storage name prefix

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
}

var locationShortCode = locationShortCodes[location]

// Resource naming convention variables
var namePrefix = '${orgName}${domainName}${envName}'
var nameSuffix = '${locationShortCode}${uniqueIdentifier}'


// Resource Names
var rgName = '${namePrefix}rg${nameSuffix}'
var logAnalyticsWorkspaceName = '${namePrefix}log${nameSuffix}'
var applicationInsightsName = '${namePrefix}appi${nameSuffix}'

var vnetName = '${namePrefix}vnet${nameSuffix}'
var functionSubnetName = '${namePrefix}snetsep${nameSuffix}'
var privateSubnetName = '${namePrefix}snetpep${nameSuffix}'

var keyVaultName = '${namePrefix}kv${nameSuffix}'
var keyVaultPEPName = '${namePrefix}kvpep${nameSuffix}'
var keyVaultNICName = '${namePrefix}kvnic${nameSuffix}'

var functionStorageName = '${namePrefix}${functionStorageNameShort}${nameSuffix}'
var functionStorageContainerName = 'app-package-${functionStorageName}-bb6a' //Function app storage name prefix
var functionAppName = '${namePrefix}func${nameSuffix}'
var hostingPlanName = '${namePrefix}asp${nameSuffix}'
var functionPEPName = '${namePrefix}funcpep${nameSuffix}'

var sqlServerName = '${namePrefix}sql${nameSuffix}'
var sqlServerPEPName = '${namePrefix}sqlpep${nameSuffix}'
// var sqlServerNICName = '${namePrefix}sqlpepnic${nameSuffix}'

var dataFactoryName = '${namePrefix}adf${nameSuffix}'
var dataFactoryPEPName = '${namePrefix}adfpep${nameSuffix}'
var dataFactoryNICName = '${namePrefix}adfnic${nameSuffix}'

var StorageAccountName = '${namePrefix}dls${nameSuffix}'
var StorageAccountBlobPEPName = '${namePrefix}dlsblobpep${nameSuffix}'
var StorageAccountBlobNICName = '${namePrefix}dlsblobnic${nameSuffix}'
var StorageAccountDFSPEPName = '${namePrefix}dlsdfspep${nameSuffix}'
var StorageAccountDFSNICName = '${namePrefix}dlsdfsnic${nameSuffix}'



// Create resource group
resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: rgName
  location: location
}



// Update Function App with Vnet requirements
module functionAppPostDeploy './modules/postdeployment/functionapp.template.bicep' = if (deployFunction) {
  scope: rg
  name: 'functionApp-network-integration${deploymentTimestamp}'
  params: {
    location: location
    functionAppName: functionAppName
    vnetName: vnetName
    subnetName: privateSubnetName
    privateEndpointName: functionPEPName
  }
}

// Update SQL Server with Vnet requirements
module sqlServerPostDeploy './modules/postdeployment/sqlserver.template.bicep' = if (deploySQL) {
  scope: rg
  name: 'sqlServer-network-integration${deploymentTimestamp}'
  params: {
    location: location
    vnetName: vnetName
    subnetName: privateSubnetName
    sqlServerName: sqlServerName
    privateEndpointName: sqlServerPEPName
  }
}

// Update Data Factory with Vnet requirements
module adfPostDeploy './modules/postdeployment/datafactory.template.bicep' = if (deploySQL) {
  scope: rg
  name: 'adf-network-integration${deploymentTimestamp}'
  params: {
    location: location
    vnetName: vnetName
    subnetName: privateSubnetName
    dataFactoryName: dataFactoryName
    privateEndpointName: dataFactoryPEPName
    nicName: dataFactoryNICName
  }
}

// Update DLS for Vnet integrations
module dlsPostDeploy './modules/postdeployment/storage.template.bicep' = if (deploySQL) {
  scope: rg
  name: 'dls-network-integration${deploymentTimestamp}'
  params: {
    location: location
    vnetName: vnetName
    subnetName: privateSubnetName
    StorageAccountName: StorageAccountName
    privateEndpointBlobName: StorageAccountBlobPEPName
    nicBlobName: StorageAccountBlobNICName
    privateEndpointDFSName: StorageAccountDFSPEPName
    nicDFSName: StorageAccountDFSNICName
  }
}

// Update KV for Vnet integrations
module kvPostDeploy './modules/postdeployment/keyvault.template.bicep' = if (deploySQL) {
  scope: rg
  name: 'kv-network-integration${deploymentTimestamp}'
  params: {
    location: location
    vnetName: vnetName
    subnetName: privateSubnetName
    keyVaultName: keyVaultName
    privateEndpointName: keyVaultPEPName
    nicName: keyVaultNICName
  }
}


// VM deployment + config

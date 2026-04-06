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

var vNetName = '${namePrefix}vnet${nameSuffix}'
var functionSubnetName = 'mattnwk-dev-sep-01'
var privateSubnetName = 'mattnwk-dev-pep-01'

var keyVaultName = '${namePrefix}kv${nameSuffix}'

var functionStorageName = '${namePrefix}${functionStorageNameShort}${nameSuffix}'
var functionStorageContainerName = 'app-package-${functionStorageName}-bb6a' //Function app storage name prefix
var functionAppName = '${namePrefix}func${nameSuffix}'
var hostingPlanName = '${namePrefix}asp${nameSuffix}'



// Create resource group
resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: rgName
  location: location
}

// Monitoring Resources
module logAnalyticsDeploy './modules/loganalytics.template.bicep' = {
  scope: rg
  name: 'log-analytics${deploymentTimestamp}'
  params: {
    envName: envName
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
  }
}

module appInsightsDeploy './modules/applicationinsights.template.bicep' = {
  scope: rg
  name: 'app-insights${deploymentTimestamp}'
  params: {
    envName: envName
    applicationInsightsName: applicationInsightsName
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
  }
  dependsOn: [
    logAnalyticsDeploy
  ]
}

// Base resources
module keyVaultDeploy './modules/keyvault.template.bicep' = {
  scope: rg
  name: 'keyvault${deploymentTimestamp}'
  params: {
    keyVaultName: keyVaultName
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
  }
  dependsOn: [
    logAnalyticsDeploy
  ]
}

// Deploy Function App
// Deploy Function App Storage Account
module functionStorageAccountDeploy './modules/storage.template.bicep' = if (deployFunction) {
  name: 'functionStorage${deploymentTimestamp}'
  scope: rg
  params: {
    envName: envName
    isHnsEnabled: false
    isSftpEnabled: false
    storageAccountName: functionStorageName
    keyVaultName: keyVaultName
    storageKind: 'StorageV2'
    containers: {
      deployments: {
        name: functionStorageContainerName
      }
    }
  }
  dependsOn: [
    keyVaultDeploy
  ]
}

// Deploy Function App + ASP
module functionAppDeploy './modules/functionapp.template.bicep' = if (deployFunction) {
  scope: rg
  name: 'functionApp${deploymentTimestamp}'
  params: {
    location: location
    functionAppName: functionAppName
    applicationInsightsName: applicationInsightsName
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    storageAccountName: functionStorageName
    storageAccountContainerName: functionStorageContainerName
    aspSKU: aspSKU
    hostingPlanName: hostingPlanName
    vNetName: vNetName
    subnetName: functionSubnetName
  }
  dependsOn: [
    functionStorageAccountDeploy
  ]
}

// Deploy SQL Server with a basic blank database
module sqlServerDeploy './modules/sqlserver.template.bicep' = if (deploySQL) {
  scope: rg
  name: 'sql-server${deploymentTimestamp}'
  params: {
    myIPAddress: myIPAddress
    allowAzureServices: allowAzureServices
    namePrefix: namePrefix
    nameSuffix: nameSuffix
  }
  dependsOn: [
    keyVaultDeploy
    logAnalyticsDeploy
  ]
}

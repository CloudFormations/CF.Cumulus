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
var nsgName = '${namePrefix}nsg${nameSuffix}'
var functionSubnetName = '${namePrefix}snetsep${nameSuffix}'
var privateSubnetName = '${namePrefix}snetpep${nameSuffix}'
var databricksControlPlaneSubnetName = '${namePrefix}snetpublic${nameSuffix}'
var databricksWorkerPlaneSubnetName = '${namePrefix}snetprivate${nameSuffix}'

var databricksWorkspaceName = '${namePrefix}dbw${nameSuffix}'
var databricksManagedResourceGroupName = '${namePrefix}mrg${nameSuffix}'
var databricksPEPName = '${namePrefix}dbwpep${nameSuffix}'


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


@description('Network Configuration resource Names.')
var networkNames = {
  virtualNetwork: vNetName
  nsg: nsgName
  subnets: {
    controlPlane: databricksControlPlaneSubnetName
    workerNodes: databricksWorkerPlaneSubnetName
    serviceEndpoint: functionSubnetName
    privateEndpoint: privateSubnetName
  }
}

@description('Network Configuration JSON with NSG, VNet and Subnet details.')
var networkConfig = {
  dev: {
    vnetAddressPrefix: '10.0.0.0/22'
    subnetPrefixes: {
      privateSubnetCIDR: '10.0.0.0/24'
      publicSubnetCIDR: '10.0.1.0/24'
      serviceEndpoint: '10.0.2.0/24'
      privateEndpoint: '10.0.3.0/24'
    }
  }
  tst: {
    vnetAddressPrefix: '10.0.4.0/22'
    subnetPrefixes: {
      privateSubnetCIDR: '10.0.4.0/24'
      publicSubnetCIDR: '10.0.5.0/24'
      serviceEndpoint: '10.0.6.0/24'
      privateEndpoint: '10.0.7.0/24'
    }
  }
  prd: {
    vnetAddressPrefix: '10.0.8.0/22'
    subnetPrefixes: {
      privateSubnetCIDR: '10.0.8.0/23'
      publicSubnetCIDR: '10.0.10.0/23'
      serviceEndpoint: '10.0.12.0/23'
      privateEndpoint: '10.0.14.0/23'
    }
  }
}

// Create resource group
resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: rgName
  location: location
}

// Deploy Networking Resources
module networkingDeploy './modules/networking.template.bicep' = {
  scope: rg
  name: 'networking${deploymentTimestamp}'
  params: {
    environment: envName
    networkConfig: networkConfig
    names: networkNames
  }
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
module databricksWorkspaceDeploy './modules/databricksworkspace.template.bicep' = {
  scope: rg
  name: 'databricks${deploymentTimestamp}'
  params: {
    vNetName: vNetName
    subnets: networkNames.subnets
    privateEndpointName: databricksPEPName
    workspaceName: databricksWorkspaceName
    managedResourceGroupName: databricksManagedResourceGroupName
  }
}

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

// Deploy ADLS for Data Lake
module storageAccountDeploy './modules/storage.template.bicep' = {
  name: 'storageaccount${deploymentTimestamp}'
  scope: rg
  params: {
    envName: envName
    isHnsEnabled: false
    isSftpEnabled: false
    storageAccountName: functionStorageName
    keyVaultName: keyVaultName
    storageKind: 'StorageV2'
    containers: {
      bronze: {
        name: 'raw'
      }
      silver: {
        name: 'cleansed'
      }
      gold: {
        name: 'curated'
      }
    }
  }
  dependsOn: [
    keyVaultDeploy
  ]
}

// Deploy Data Factory
module dataFactoryDeploy './modules/datafactory.template.bicep' = if (deployADF) {
  scope: rg
  name: 'datafactory-orchestrator${deploymentTimestamp}'
  params: {
    dataFactoryName: dataFactoryName
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
  }
  dependsOn: [
    keyVaultDeploy
    logAnalyticsDeploy
  ]
}

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


// Deploy VM for SHIR ( + act as Jump box?)

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

//Parameters for configuration settings
@allowed(['premium','consumption', 'flex'])
param aspSKU string = 'flex'   // ASP SKU for function app

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
  swedencentral: 'sde'
}

var locationShortCode = locationShortCodes[location]

// Resource naming convention variables
var namePrefix = '${orgName}${domainName}${envName}'
var nameSuffix = '${locationShortCode}${uniqueIdentifier}'


// Resource Names
var rgName = '${namePrefix}rg${nameSuffix}'
var logAnalyticsWorkspaceName = '${namePrefix}log${nameSuffix}'
var applicationInsightsName = '${namePrefix}appi${nameSuffix}'

var databricksWorkspaceName = '${namePrefix}dbw${nameSuffix}'
var databricksManagedResourceGroupName = '${namePrefix}mrg${nameSuffix}'


var keyVaultName = '${namePrefix}kv${nameSuffix}'

var functionStorageName = '${namePrefix}${functionStorageNameShort}${nameSuffix}'
var functionStorageContainerName = 'app-package-${functionStorageName}' //Function app storage name prefix
var functionAppName = '${namePrefix}func${nameSuffix}'
var hostingPlanName = '${namePrefix}asp${nameSuffix}'

var sqlServerName = '${namePrefix}sql${nameSuffix}'
var sqlDatabaseName = '${namePrefix}sqldb${nameSuffix}'

var dataFactoryName = '${namePrefix}adf${nameSuffix}'

var storageAccountName = '${namePrefix}${datalakeNameShort}${nameSuffix}'


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
module databricksWorkspaceDeploy './modules/databricksworkspace.template.bicep' =  {
  scope: rg
  name: 'databricks${deploymentTimestamp}'
  params: {
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
    storageAccountName: storageAccountName
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
module dataFactoryDeploy './modules/datafactory.template.bicep' = {
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
module functionStorageAccountDeploy './modules/storage.template.bicep' = {
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
module functionAppDeploy './modules/functionapp.template.bicep' = {
  scope: rg
  name: 'functionApp${deploymentTimestamp}'
  params: {
    location: location
    functionAppName: functionAppName
    applicationInsightsName: applicationInsightsName
    storageAccountName: functionStorageName
    storageAccountContainerName: functionStorageContainerName
    aspSKU: aspSKU
    hostingPlanName: hostingPlanName
  }
  dependsOn: [
    functionStorageAccountDeploy
  ]
}

// Deploy SQL Server with a basic blank database
module sqlServerDeploy './modules/sqlserver.template.bicep' =  {
  scope: rg
  name: 'sql-server${deploymentTimestamp}'
  params: {
    sqlServerName: sqlServerName
    sqlDatabaseName: sqlDatabaseName
    keyVaultName: keyVaultName
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    myIPAddress: myIPAddress
    allowAzureServices: allowAzureServices
  }
  dependsOn: [
    keyVaultDeploy
    logAnalyticsDeploy
  ]
}



// Role Assignments:
// Data Factory Role Assignments
module dataFactoryRoleAssignmentsDeploy './modules/roleassignments/datafactory.template.bicep' =  {
  scope: rg
  name: 'adf-orchestration-roleassignments${deploymentTimestamp}'
  params: {
    dataFactoryName: dataFactoryName
    storageAccountName: storageAccountName
    sqlServerName: sqlServerName
    keyVaultName: keyVaultName
    databricksWorkspaceName: databricksWorkspaceName
    functionAppName: functionAppName
  }
  dependsOn: [
    dataFactoryDeploy
    storageAccountDeploy
    sqlServerDeploy
    keyVaultDeploy
    databricksWorkspaceDeploy
    functionAppDeploy
  ]
}



// Data Factory Role Assignments
module functionAppRoleAssignmentsDeploy './modules/roleassignments/functionapp.template.bicep' =  {
  scope: rg
  name: 'function-app-roleassignments${deploymentTimestamp}'
  params: {
    functionAppName: functionAppName
    dataFactoryName: dataFactoryName 
    keyVaultName: keyVaultName
  }
  dependsOn: [
    storageAccountDeploy
    dataFactoryDeploy
    functionAppDeploy
  ]
}

// OUTPUTS
output rgName string = rgName
output databricksWorkspaceName string = databricksWorkspaceDeploy.outputs.name
output databricksWorkspaceURL string = databricksWorkspaceDeploy.outputs.workspaceURL
output databricksWorkspaceId string = databricksWorkspaceDeploy.outputs.workspaceID
output keyVaultName string = keyVaultDeploy.outputs.name
output keyVaultUri string = keyVaultDeploy.outputs.keyVaultUri
output keyVaultId string = keyVaultDeploy.outputs.keyVaultId
output storageAccountName string = storageAccountDeploy.outputs.name
output functionAppName string = functionAppDeploy.outputs.functionAppName
output dataFactoryName string = dataFactoryDeploy.outputs.name
output sqlServerName string = sqlServerDeploy.outputs.sqlServerName
output sqlDatabaseName string = sqlServerDeploy.outputs.databaseName

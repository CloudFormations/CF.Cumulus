//  Main infrastructure deployment template for a CF.Cumulus data platform
//  Deploys core services including:
//  - Key Vault, Storage, Data Factory, Databricks, Function Apps, SQL Server
//  - Configures role assignments and dependencies between services

targetScope = 'subscription'

//Parameters for environment configuration
// * These parameters control resource naming and deployment options
// * Recommended for consistent resource naming across environments
param orgName string = 'cfc'
param domainName string = 'demo'
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
@allowed(['premium','consumption'])
param aspSKU string = 'consumption'   // ASP SKU for function app

param configureGitHub bool = false    // if GitHub repo configuration is required for ADF deployment

@allowed(['Premium','Standard'])
param databricksSKU string = 'Premium'   // Databricks Workspace SKU


// SQL Server: Optional Parameters
param myIPAddress string // For SQL Server Firewall rule
param allowAzureServices bool // For allowing Azure services access to Azure SQL Server

// Storage: Optional naming configurations
param datalakeName string = 'dls' //Storage account name prefix
param functionStorageName string = 'st' //Function app storage name prefix

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
var rgName = '${namePrefix}rg${nameSuffix}'

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
    namePrefix: namePrefix
    nameSuffix: nameSuffix
  }
}

module appInsightsDeploy './modules/applicationinsights.template.bicep' = {
  scope: rg
  name: 'app-insights${deploymentTimestamp}'
  params: {
    envName: envName
    namePrefix: namePrefix
    nameSuffix: nameSuffix
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
    namePrefix: namePrefix
    nameSuffix: nameSuffix
  }
  dependsOn: [
    logAnalyticsDeploy
  ]
}

// Datafactory Resources
module dataFactoryDeployOrchestrator './modules/datafactory.template.bicep' = if (deployADF) {
  scope: rg
  name: 'datafactory-orchestrator${deploymentTimestamp}'
  params: {
    nameFactory: deployWorkers ? 'factory' : 'adf' // if workers adf is being setup we call this one factory, otherwise we call it adf
    namePrefix: namePrefix
    nameSuffix: nameSuffix
    configureGitHub: configureGitHub
  }
  dependsOn: [
    keyVaultDeploy
    logAnalyticsDeploy
  ]
}

// Additional Data Factory Resource deployment if you require mulitple instances 
module dataFactoryDeployWorkers './modules/datafactory.template.bicep' = if (deployADF && deployWorkers) {
  scope: rg
  name: 'datafactory-workers${deploymentTimestamp}'
  params: {
    nameFactory: 'workers'
    namePrefix: namePrefix
    nameSuffix: nameSuffix
    configureGitHub: configureGitHub
  }
  dependsOn: [
    keyVaultDeploy
    logAnalyticsDeploy
  ]
}

// Deploy ADLS for Data Lake
module storageAccountDeploy './modules/storage.template.bicep' = {
  name: 'storageaccount${deploymentTimestamp}'
  scope: rg
  params: {
    isHnsEnabled: true
    isSftpEnabled: false
    accessTier: 'Hot'
    namePrefix: namePrefix
    nameSuffix: nameSuffix
    nameStorage: datalakeName
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
    envName: envName
  }
  dependsOn: [
    keyVaultDeploy
    logAnalyticsDeploy
  ]
}

// Deploy Function App
// Deploy Function App Storage Account
module functionStorageAccountDeploy './modules/storage.template.bicep' = if (deployFunction) {
  name: 'functionStorage${deploymentTimestamp}'
  scope: rg
  params: {
    containers: {}
    envName: envName
    isHnsEnabled: false
    isSftpEnabled: false
    namePrefix: namePrefix
    nameStorage: functionStorageName
    nameSuffix: nameSuffix
    storageKind: 'StorageV2'
  }
  dependsOn: [
    keyVaultDeploy
    appInsightsDeploy
    logAnalyticsDeploy
  ]
}

// Deploy Function App + ASP
module functionAppDeploy './modules/functionapp.template.bicep' = if (deployFunction) {
  scope: rg
  name: 'functionApp${deploymentTimestamp}'
  params: {
    namePrefix: namePrefix
    nameSuffix: nameSuffix
    nameStorage: functionStorageName
    aspSKU: aspSKU
  }
  dependsOn: [
    keyVaultDeploy
    appInsightsDeploy
    logAnalyticsDeploy
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

// Deploy Databricks workspace.
module databricksWorkspaceDeploy './modules/databricksworkspace.template.bicep' = if (deployADBWorkspace) {
  scope: rg
  name: 'databricks${deploymentTimestamp}'
  params: {
    namePrefix: namePrefix
    nameSuffix: nameSuffix
    skuTier: databricksSKU
    deployVnet: deployNetworking
    // vnetId: deployNetworking ? networkingDeploy.outputs.vnetId : '' // VNet configuration not required for standard deployment of CF.Cumulus
  }
  dependsOn: [
    keyVaultDeploy
    storageAccountDeploy
    // logAnalyticsDeploy   // Relationship still to be configured
    // deployNetworking ? networkingDeploy : null

  ]
}

// Role Assignments:
// Data Factory Role Assignments
module dataFactoryOrchestratorRoleAssignmentsDeploy './modules/roleassignments/datafactory.template.bicep' = if (deployADF && setRoleAssignments) {
  scope: rg
  name: 'adf-orchestration-roleassignments${deploymentTimestamp}'
  params: {
    nameFactory: deployWorkers ? 'factory' : 'adf' // if workers adf is being setup we call this one factory, otherwise we call it adf
    namePrefix: namePrefix
    nameSuffix: nameSuffix
    nameStorage: datalakeName
    statusADB: deployADBWorkspace
    statusFunction: deployFunction
  }
  dependsOn: [
    keyVaultDeploy
    storageAccountDeploy
    dataFactoryDeployOrchestrator
    deploySQL ? sqlServerDeploy : null
    deployFunction ? functionAppDeploy : null
    deployADBWorkspace ? databricksWorkspaceDeploy : null
  ]
}

// Data Factory Role Assignments
module dataFactoryWorkersRoleAssignmentsDeploy './modules/roleassignments/datafactory.template.bicep' = if (deployWorkers && setRoleAssignments) {
  scope: rg
  name: 'adf-workers-roleassignments${deploymentTimestamp}'
  params: {
    nameFactory: 'workers'
    namePrefix: namePrefix
    nameSuffix: nameSuffix
    nameStorage: datalakeName
    statusADB: deployADBWorkspace
    statusFunction: deployFunction
  }
  dependsOn: [
    keyVaultDeploy
    storageAccountDeploy
    dataFactoryDeployWorkers
    deploySQL ? sqlServerDeploy : null
    deployFunction ? functionAppDeploy : null
    deployADBWorkspace ? databricksWorkspaceDeploy : null
  ]
}

// // Databricks Role Assignments
// module databricksRoleAssignmentsDeploy './modules/roleassignments/databricks.template.bicep' = if (deployADBWorkspace && setRoleAssignments) {
//   scope: rg
//   name: 'databricks-roleassignments${deploymentTimestamp}'
//   params: {
//     adbWorkspaceName: databricksWorkspaceDeploy.outputs.name
//     nameStorage: datalakeName
//     keyVaultName: keyVaultDeploy.outputs.name
//     databricksID: databricksWorkspaceDeploy.outputs.databricksID
//   }
//   dependsOn: [
//     keyVaultDeploy
//     storageAccountDeploy
//     databricksWorkspaceDeploy
//     dataFactoryDeployOrchestrator
//   ]
// }

// OUTPUTS
output rgName string = rgName
output databricksWorkspaceURL string = databricksWorkspaceDeploy.outputs.workspaceURL
output databricksWorkspaceId string = databricksWorkspaceDeploy.outputs.workspaceID
output keyVaultName string = keyVaultDeploy.outputs.name
output keyVaultUri string = keyVaultDeploy.outputs.keyVaultUri
output keyVaultId string = keyVaultDeploy.outputs.keyVaultId
output storageAccountName string = storageAccountDeploy.outputs.name
output functionAppName string = functionAppDeploy.outputs.functionAppName
output dataFactoryName string = dataFactoryDeployOrchestrator.outputs.name
output sqlServerName string = sqlServerDeploy.outputs.sqlServerName
output sqlDatabaseName string = sqlServerDeploy.outputs.databaseName

//  Main infrastructure deployment template for a CF.Cumulus data platform
//  Deploys core services including:
//  - Key Vault, Storage, Data Factory, Databricks, Function Apps, SQL Server
//  - Configures role assignments and dependencies between services

targetScope = 'subscription'

//Parameters for environment configuration
// * These parameters control resource naming and deployment options
// * Recommended for consistent resource naming across environments

//Naming convention parameters
//**************************************************************************************************************
@description('The naming prefix for all resources to be deployed.')
param orgName string = 'cfc' 

@description('The optional middle part naming for all resources to be deployment. Suggested as the business unit, project or domain.')
param domainName string = 'demo'

@description('The environment name abbreviation used for the deployment.')
param envName string = 'dev, tst, prd'

@description('The Azure region where all resources will be deployed.')
param location string = 'uksouth'

@description('Optional naming abbreviation for the Azure Data Lake Storage account.')
param datalakeName string = 'dls'

@description('Optional naming abbreviation for the Azure Storage account used to support the Azure Functions App.')
param functionStorageName string = 'st'

@description('The numeric identifier for all resources as a naming suffix, used to differentiate between instances of resources.')
param uniqueIdentifier string = '01'


//Parameters to support resource configuration
//**************************************************************************************************************
@description('The product SKU for the Azure Databricks workspace.')
@allowed(['Premium','Standard'])
param databricksSKU string = 'Premium'

@description('The product SKU for the App Service Plan used by the Azure Function App.')
@allowed(['premium','consumption'])
param aspSKU string = 'consumption'   

@description('Deploy the SQL DACPAC required for the metadata database objects.')
param deploySQLDacpac bool = true

@description('An external IP address that is allowed access to the Azure SQL Database, as part of the logical SQL instance Firewall Rules.')
param myIPAddress string 

@description('Allow Azure services to access the Azure SQL Database, as part of the logical SQL instance Firewall Rules. Required for Azure Data Factory MI authentication.')
param allowAzureServices bool = true

@description('A timestamp format used for the deployment execution naming only. Used to differentiate between instances of resources deployed.')
param deploymentTimestamp string = utcNow('yy-MM-dd-HHmm')


//Parameters for optional resource deployments considering new vs existing instances
//**************************************************************************************************************
@description('Optionally deploy Azure Data Factory, if it already exists.')
param deployADF bool = true

@description('Optionally deploy a separate Azure Data Factory instance to house Worker and Bootstrap pipelines separately.')
param deployWorkers bool = false

@description('Optionally deploy an Azure SQL Database to house all metadata, if it already exists.')
param deploySQL bool = true           

@description('Optionally deploy an Azure Function App, if it already exists.')
param deployFunction bool = true

@description('Optionally deploy an Azure Databricks workspace, if it already exists.')
param deployADBWorkspace bool = true

@description('Optionally setup role assignments as part of the deployment.')
param setRoleAssignments bool = true

@description('Optionally deploy a custom VNet for the Azure Databricks workspace.')
param deployNetworking bool = false

@description('Optionally deploy a Virtual Machine to house self-hosted Integration Runtime (IR) for Azure Data Factory.')
param deployVM bool = false  

@description('Optionally configure GitHub repository for Azure Data Factory.')
param configureGitHub bool = false    


//End of parameters - no need to change anything below
//**************************************************************************************************************
//**************************************************************************************************************
//**************************************************************************************************************

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
    deployDacpac: deploySQLDacpac
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

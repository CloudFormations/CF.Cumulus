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
param location string = 'uksouth'
param envName string = 'demo'

param uniqueIdentifier string = '05'
param datalakeName string = 'dls' //Storage account name prefix
param functionBlobName string = 'st' //Function app storage name prefix

param deploymentTimestamp string = utcNow('yy-MM-dd-HHmm') //used for activity deployment naming only

//Parameters for optional settings
param firstDeployment bool = true     // controls initial RBAC setup with security group
param deployADF bool = true
param deployWorkers bool = false      // if worker pipelines are to live in a separate data factory instance to the bootstrap pipelines
param deployVM bool = false           // if self hosted IR is required for data factory
param deploySQL bool = true           // assumes SQL database is required to house metadata
param deployFunction bool = true      // exclude function app if already created or manual config is preferred later
param deployNetworking bool = true    // if custom VNet and specific IP address space is to be used
param deployADBWorkspace bool = true  // exclude databricks if already created or manual config is preferred later
param deployADBCluster bool = false   // Controls ADB Cluster creation - TODO
param deployPAT bool = false          // - TODO
param setRoleAssignments bool = true


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

//var databaseName string = 'Metadata' //SQL Database name
var databaseName = '${namePrefix}sqldb${nameSuffix}' //SQL Database name

// Network IP address space, assuming floating VNet per environment without peering.
// This configuration is for demo purposes only, and should be adjusted for production.
var networkConfig = {
  default: {
    vnetAddressPrefix: '10.210.8.0/21'
    subnetPrefixes: {
      privateSubnetCIDR: '10.210.8.0/23'
      publicSubnetCIDR: '10.210.10.0/23'
      serviceEndpoint: '10.210.12.0/23'
      privateEndpoint: '10.210.14.0/23'
    }
  }
}


// Do we need to register Microsoft.AlertsManagement provider?
// Need to find the correct API


// Create resource group
resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: rgName
  location: location
}


// Create security group on first run
module securityGroupDeploy './modules/securitygroup.template.bicep' = if (firstDeployment) {
  scope: rg
  name: 'CF.CumulusAdmins'
}

// Base resources
module keyVaultDeploy './modules/keyvault.template.bicep' = {
  scope: rg
  name: 'keyvault${deploymentTimestamp}'
  params: {
    keyVaultExists: false
    namePrefix: namePrefix
    nameSuffix: nameSuffix
  }
}

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
  ]
}

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
}

//Function resources
module functionBlobDeploy './modules/storage.template.bicep' = if (deployFunction) {
  name: 'functionStorage${deploymentTimestamp}'
  scope: rg
  params: {
    containers: {}
    envName: envName
    isHnsEnabled: false
    isSftpEnabled: false
    namePrefix: namePrefix
    nameStorage: functionBlobName
    nameSuffix: nameSuffix
    storageKind: 'Storage'
  }
  dependsOn: [
    keyVaultDeploy
  ]
}

module functionAppDeploy './modules/functionapp.template.bicep' = if (deployFunction) {
  scope: rg
  name: 'functionApp${deploymentTimestamp}'
  params: {
    namePrefix: namePrefix
    nameSuffix: nameSuffix
    nameStorage: functionBlobName
  }
  dependsOn: [
    keyVaultDeploy
    appInsightsDeploy
    functionBlobDeploy
  ]
}

// Deploy Networking resources
module networkingDeploy './modules/networking.template.bicep' = if (deployNetworking) {
  scope: rg
  name: 'networking${deploymentTimestamp}'
  params: {
    namePrefix: namePrefix
    nameSuffix: nameSuffix
    networkConfig: networkConfig
  }
  dependsOn: [
    keyVaultDeploy
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
    envName: envName
    logAnalyticsWorkspaceId: logAnalyticsDeploy.outputs.resourceId
  }
  dependsOn: [
    keyVaultDeploy
    logAnalyticsDeploy
  ]
}

module dataFactoryDeployWorkers './modules/datafactory.template.bicep' = if (deployADF && deployWorkers) {
  scope: rg
  name: 'datafactory-workers${deploymentTimestamp}'
  params: {
    nameFactory: 'workers'
    namePrefix: namePrefix
    nameSuffix: nameSuffix
    envName: envName
    logAnalyticsWorkspaceId: logAnalyticsDeploy.outputs.resourceId
  }
  dependsOn: [
    keyVaultDeploy
    logAnalyticsDeploy
  ]
}

// Deploy SQL Server with a basic blank database
module sqlServerDeploy './modules/sqlserver.template.bicep' = if (deploySQL) {
  scope: rg
  name: 'sql-server${deploymentTimestamp}'
  params: {
    databaseName: databaseName
    namePrefix: namePrefix
    nameSuffix: nameSuffix
  }
  dependsOn: [
    keyVaultDeploy
  ]
}

// Deploy databricks deployment (within a VNET)
module databricksWorkspaceDeploy './modules/databricksworkspace.template.bicep' = if (deployADBWorkspace) {
  scope: rg
  name: 'databricks${deploymentTimestamp}'
  params: {
    namePrefix: namePrefix
    nameSuffix: nameSuffix
    skuTier: 'Standard'
    deployVnet: deployNetworking
    vnetId: deployNetworking ? networkingDeploy.outputs.vnetId : ''
  }
  dependsOn: [
    keyVaultDeploy
    storageAccountDeploy
    deployNetworking ? networkingDeploy : null

  ]
}

module databricksPatDeploy './modules/databrickspat.template.bicep' = if (deployADBWorkspace && deployPAT) {
  scope: rg
  name: 'databrickspat${deploymentTimestamp}'
  params: {
    adb_workspace_managed_identity: databricksWorkspaceDeploy.outputs.databricks_managed_identity
    adb_workspace_id: databricksWorkspaceDeploy.outputs.databricks_workspace.id
    adb_workspace_url: databricksWorkspaceDeploy.outputs.databricks_workspace.properties.workspaceUrl
    adb_secret_scope_name: 'CumulusScope01'
    akv_id: keyVaultDeploy.outputs.keyVaultId
    akv_uri: keyVaultDeploy.outputs.keyVaultURI
  }
  dependsOn: [
    databricksWorkspaceDeploy
    keyVaultDeploy
  ]
}
 
module databricksClusterDeploy './modules/databrickscluster.template.bicep' = if (deployADBCluster) {
  scope: rg
  name: 'databrickscluster${deploymentTimestamp}'
  params: {
    adb_cluster_name: 'cluster-01'
    adb_workspace_id: databricksWorkspaceDeploy.outputs.databricks_workspace.id
    adb_workspace_url: databricksWorkspaceDeploy.outputs.databricks_workspace.properties.workspaceUrl
    adb_workspace_managed_identity: databricksWorkspaceDeploy.outputs.databricks_managed_identity
    adb_secret_scope_name: 'CumulusScope01'
  }
  dependsOn: [
    databricksWorkspaceDeploy
  ]
}

module virtualMachineDeploy './modules/virtualmachine.template.bicep' = if (deployVM) {
  scope: rg
  name: 'vm${deploymentTimestamp}'
  params: {
    adminUsername: 'SHIRAdmin'
    envName: envName
    namePrefix: namePrefix
    nameSuffix: nameSuffix
  }
  dependsOn: [
    keyVaultDeploy
  ]
}

/* RBAC Configuration
 * Configures service-to-service permissions:
 * - Data Factory access to storage, functions, and other services
 * - Function App access to required resources
 */

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

module functionAppRoleAssignmentsDeploy './modules/roleassignments/functionapp.template.bicep' = if (deployFunction && setRoleAssignments) {
  scope: rg
  name: 'functionapp-roleassignments${deploymentTimestamp}'
  params: {
    namePrefix: namePrefix
    nameSuffix: nameSuffix
    firstDeployment: firstDeployment
    deployWorkers: deployWorkers
  }
  dependsOn: [
    keyVaultDeploy
    storageAccountDeploy
    dataFactoryDeployOrchestrator
    deploySQL ? sqlServerDeploy : null
    deployFunction ? functionAppDeploy : null
    deployADBWorkspace ? databricksWorkspaceDeploy : null
    deployWorkers ? dataFactoryDeployWorkers : null
  ]
}



module dataBricksRoleAssignmentsDeploy './modules/roleassignments/databricks.template.bicep' = if (deployADBWorkspace && setRoleAssignments) {
  scope: rg
  name: 'databricks-roleassignments${deploymentTimestamp}'
  params: {
    adbWorkspaceName: databricksWorkspaceDeploy.name
    nameStorage: datalakeName
  }
  dependsOn: [
    storageAccountDeploy
    databricksWorkspaceDeploy
    dataFactoryDeployOrchestrator
  ]
}

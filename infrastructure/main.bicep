targetScope = 'subscription'

param location string = 'uksouth'
param envName string
param domainName string = 'cfc'
param orgName string = 'demo'
param uniqueIdentifier string = '01'
param nameStorage string = 'dls'

param functionStorageName string = 'fst'

param deploymentTimestamp string = utcNow('yy-MM-dd-HHmm')

param firstDeployment bool = false

var locationShortCodes = {
  uksouth: 'uks'
  ukwest: 'ukw'
  eastus: 'eus'
}

var locationShortCode = locationShortCodes[location]

var namePrefix = '${domainName}${orgName}${envName}'
var nameSuffix = '${locationShortCode}${uniqueIdentifier}'
var rgName = '${namePrefix}rg${nameSuffix}'

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: rgName
  location: location
}

module keyVaultDeploy 'modules/keyvault.template.bicep' = {
  scope: rg
  name: 'keyvault${deploymentTimestamp}'
  params:{
    keyVaultExists: false
    namePrefix: namePrefix
    nameSuffix: nameSuffix
  }
}

module appInsightsDeploy 'modules/applicationinsights.template.bicep' = {
  scope: rg
  name: 'app-insights${deploymentTimestamp}'
  params:{
    envName: envName
    namePrefix: namePrefix
    nameSuffix: nameSuffix
  }
}

module storageAccountDeploy 'modules/storage.template.bicep' = {
  name: 'storageaccount${deploymentTimestamp}'
  scope: rg
  params: {
    isHnsEnabled: true
    isSftpEnabled: false
    accessTier: 'Hot'
    namePrefix: namePrefix
    nameSuffix: nameSuffix
    nameStorage: nameStorage
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

module dataFactoryDeployOrchestrator 'modules/datafactory.template.bicep' = {
  scope: rg
  name: 'datafactory-orchestrator${deploymentTimestamp}'
  params:{
    nameFactory: 'factory'
    namePrefix: namePrefix
    nameSuffix: nameSuffix
    envName: envName
  }
  dependsOn: [
    keyVaultDeploy
  ]
}

module dataFactoryDeployWorkers 'modules/datafactory.template.bicep' = {
  scope: rg
  name: 'datafactory-workers${deploymentTimestamp}'
  params:{
    nameFactory: 'workers'
    namePrefix: namePrefix
    nameSuffix: nameSuffix
    envName: envName
  }
  dependsOn: [
    keyVaultDeploy
  ]
}

module logAnalyticsDeploy 'modules/loganalytics.template.bicep' = {
  scope: rg
  name: 'log-analytics${deploymentTimestamp}'
  params:{
    envName: envName
    namePrefix: namePrefix
    nameSuffix: nameSuffix
  }
}

module databricksWorkspaceDeploy 'modules/databricks.template.bicep' = {
  scope: rg
  name: 'databricks${deploymentTimestamp}'
  params: {
    namePrefix: namePrefix
    nameSuffix: nameSuffix
    skuTier: 'standard'
  }
  dependsOn: [
    keyVaultDeploy
  ]
}

module functionStorageDeploy 'modules/storage.template.bicep' = {
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
  }
  dependsOn: [
    keyVaultDeploy
  ]
}

module functionAppDeploy 'modules/functionapp.template.bicep' = {
  scope: rg
  name: 'functionApp${deploymentTimestamp}'
  params: {
    namePrefix: namePrefix
    nameSuffix: nameSuffix
    nameStorage: functionStorageName
  }
  dependsOn: [
    keyVaultDeploy
    functionStorageDeploy
    appInsightsDeploy
  ]
}

module sqlServerDeploy 'modules/sqlserver.template.bicep' = {
  scope: rg
  name: 'sql-server${deploymentTimestamp}'
  params: {
    databaseName: 'metadata'
    namePrefix: namePrefix
    nameSuffix: nameSuffix
  }
  dependsOn: [
    keyVaultDeploy
  ]
}

module databricksClusterDeploy 'modules/databrickscluster.template.bicep' = {
  scope: rg
  name: 'databrickscluster${deploymentTimestamp}'
  params: {
    location: location
    adb_workspace_url: databricksWorkspaceDeploy.outputs.databricks_workspaceUrl
    adb_workspace_id: databricksWorkspaceDeploy.outputs.databricks_workspace_id
    adb_secret_scope_name: 'CumulusScope02'
    akv_id: keyVaultDeploy.outputs.keyVaultId
    akv_uri: keyVaultDeploy.outputs.keyVaultURI
    namePrefix: namePrefix
    nameSuffix: nameSuffix
    // LogAWkspId: logAnalyticsDeploy.outputs.resourceId
    // LogAWkspKey: logAnalyticsDeploy.outputs.primarySharedKey
  }
  dependsOn: [
    databricksWorkspaceDeploy
    keyVaultDeploy
  ]
}

module virtualMachineDeploy 'modules/virtualmachine.template.bicep' = {
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


module dataFactoryOrchestratorRoleAssignmentsDeploy 'modules/roleassignments/datafactory.template.bicep' = {
  scope: rg
  name: 'adf-orchestration-roleassignments${deploymentTimestamp}'
  params:{
    nameFactory: 'factory'
    namePrefix: namePrefix
    nameSuffix: nameSuffix
    nameStorage: nameStorage
  }
  dependsOn: [
    dataFactoryDeployOrchestrator
    dataFactoryDeployWorkers
    functionAppDeploy
    storageAccountDeploy
    sqlServerDeploy
    databricksWorkspaceDeploy
    keyVaultDeploy
  ]
}

module dataFactoryWorkersRoleAssignmentsDeploy 'modules/roleassignments/datafactory.template.bicep' = {
  scope: rg
  name: 'adf-workers-roleassignments${deploymentTimestamp}'
  params:{
    nameFactory: 'workers'
    namePrefix: namePrefix
    nameSuffix: nameSuffix
    nameStorage: nameStorage
  }
  dependsOn: [
    dataFactoryDeployOrchestrator
    dataFactoryDeployWorkers
    functionAppDeploy
    storageAccountDeploy
    sqlServerDeploy
    databricksWorkspaceDeploy
    keyVaultDeploy
  ]
}



module functionAppRoleAssignmentsDeploy 'modules/roleassignments/functionapp.template.bicep' = {
  scope: rg
  name: 'functionapp-roleassignments${deploymentTimestamp}'
  params: {
    namePrefix: namePrefix
    nameSuffix: nameSuffix
    firstDeployment: firstDeployment
  }
  dependsOn: [
    dataFactoryDeployOrchestrator
    dataFactoryDeployWorkers
    functionAppDeploy
    storageAccountDeploy
    sqlServerDeploy
    databricksWorkspaceDeploy
    keyVaultDeploy
  ]
}

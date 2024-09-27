param location string = resourceGroup().location

param namePrefix string 
param nameSuffix string 
param firstDeployment bool
param timestamp string = utcNow('yy-MM-dd-HHmm')


var name = '${namePrefix}func${nameSuffix}'
resource keyVault  'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: '${namePrefix}kv${nameSuffix}'
}

resource functionApp 'Microsoft.Web/sites@2023-12-01' existing = {
  name: name

}

resource keyVaultRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (firstDeployment == true) {
  name: guid(functionApp.id, keyVault.id, 'Reader', timestamp)
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6') // Contributor role
    principalId: functionApp.identity.principalId
  }
}


resource dataFactory 'Microsoft.DataFactory/factories@2018-06-01' existing = {
  name: '${namePrefix}factory${nameSuffix}'
}

resource dataFactoryRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (firstDeployment == true) {
  name: guid(functionApp.id, dataFactory.id, 'Contributor', timestamp)
  scope: dataFactory
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '673868aa-7521-48a0-acc6-0f60742d39f5') // Data Factory Contributor role
    principalId: functionApp.identity.principalId
  }
}

resource dataFactoryWorkers 'Microsoft.DataFactory/factories@2018-06-01' existing = {
  name: '${namePrefix}workers${nameSuffix}'
}

resource dataFactoryWorkersRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (firstDeployment == true) {
  name: guid(functionApp.id, dataFactoryWorkers.id, 'Contributor', timestamp)
  scope: dataFactoryWorkers
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '673868aa-7521-48a0-acc6-0f60742d39f5') // Data Factory Contributor role
    principalId: functionApp.identity.principalId
  }
}

output location string = location
output name string = functionApp.name
output resourceGroupName string = resourceGroup().name
output resourceId string = functionApp.id


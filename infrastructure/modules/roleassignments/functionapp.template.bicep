// Input parameters for resource naming and deployment control
param location string = resourceGroup().location
param namePrefix string 
param nameSuffix string 
//param nameFactory string
param firstDeployment bool
param deployWorkers bool

var nameFactory = deployWorkers ? 'factory' : 'adf' // if workers adf is being setup we call this one factory, otherwise we call it adf

// Timestamp parameter used to generate unique GUIDs for role assignments
param timestamp string = utcNow('yy-MM-dd-HHmm')

// Construct the function app name using prefix and suffix
var functionappName = '${namePrefix}func${nameSuffix}'

// Reference to an existing Key Vault resource
resource keyVault  'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: '${namePrefix}kv${nameSuffix}'
}

// Reference to an existing Function App resource
resource functionApp 'Microsoft.Web/sites@2023-12-01' existing = {
  name: functionappName
}

// Assign Key Vault Reader role to the Function App's managed identity
// Only executed during first deployment (firstDeployment == true)
resource keyVaultRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (firstDeployment) {
  name: guid(functionApp.id, keyVault.id, 'Reader', timestamp)
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6') // Contributor role
    principalId: functionApp.identity.principalId
  }
}

// Reference to an existing Data Factory resource
resource dataFactory 'Microsoft.DataFactory/factories@2018-06-01' existing = {
  name: '${namePrefix}${nameFactory}${nameSuffix}'
}

// Assign Data Factory Contributor role to the Function App's managed identity
// Only executed during first deployment (firstDeployment == true)
resource dataFactoryRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (firstDeployment) {
  name: guid(functionApp.id, dataFactory.id, 'Contributor', timestamp)
  scope: dataFactory
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '673868aa-7521-48a0-acc6-0f60742d39f5') // Data Factory Contributor role
    principalId: functionApp.identity.principalId
  }
}

// Reference to an existing Workers Data Factory resource
resource dataFactoryWorkers 'Microsoft.DataFactory/factories@2018-06-01' existing = if (deployWorkers) {
  name: '${namePrefix}workers${nameSuffix}'
}

// Assign Data Factory Contributor role to the Function App's managed identity for the Workers Data Factory
// Only executed during first deployment (firstDeployment == true)
resource dataFactoryWorkersRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (firstDeployment && deployWorkers) {
  name: guid(functionApp.id, dataFactoryWorkers.id, 'Contributor', timestamp)
  scope: dataFactoryWorkers
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '673868aa-7521-48a0-acc6-0f60742d39f5') // Data Factory Contributor role
    principalId: functionApp.identity.principalId
  }
}

// Output values that can be referenced by other templates or deployments
output location string = location
output name string = functionApp.name
output resourceGroupName string = resourceGroup().name
output resourceId string = functionApp.id

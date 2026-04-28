@description('Resource group location.')
param location string = resourceGroup().location

@description('Function App Name.')
param functionAppName string

@description('Key Vault name.')
param keyVaultName string

@description('Data Factory resource name.')
param dataFactoryName string

@description('Unique timestamp for RBAC deployments to prevent duplication conflicts.')
param timestamp string = utcNow('yy-MM-dd-HHmm')

// Reference to an existing Key Vault resource
resource keyVault  'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: keyVaultName
}

// Reference to an existing Function App resource
resource functionApp 'Microsoft.Web/sites@2023-12-01' existing = {
  name: functionAppName
}

// Assign Key Vault Reader role to the Function App's managed identity
resource keyVaultRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(functionApp.id, keyVault.id, 'Reader')
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6') // Contributor role
    principalId: functionApp.identity.principalId
  }
}

// Reference to an existing Data Factory resource
resource dataFactory 'Microsoft.DataFactory/factories@2018-06-01' existing = {
  name: dataFactoryName
}

// Assign Data Factory Contributor role to the Function App's managed identity
resource dataFactoryRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(functionApp.id, dataFactory.id, 'Contributor')
  scope: dataFactory
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

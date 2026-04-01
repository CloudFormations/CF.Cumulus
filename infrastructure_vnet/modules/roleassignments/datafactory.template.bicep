// Input parameters for resource naming and location
param location string = resourceGroup().location
param namePrefix string 
param nameSuffix string 
param nameFactory string
param nameStorage string
param statusADB bool
param statusFunction bool

// Construct the Data Factory name using prefix, factory name, and suffix
var name = '${namePrefix}${nameFactory}${nameSuffix}'

// Reference to existing Data Factory resource
resource dataFactory 'Microsoft.DataFactory/factories@2018-06-01' existing = {
  name: name
}

// Assign Data Factory Contributor role to the Data Factory's managed identity
// Only created if nameFactory is 'factory' or 'adf'
resource dataFactoryRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (nameFactory == 'factory' || nameFactory == 'adf') {
  name: guid(dataFactory.id, dataFactory.id, 'Contributor')
  scope: dataFactory
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '673868aa-7521-48a0-acc6-0f60742d39f5') // Data Factory Contributor role
    principalId: dataFactory.identity.principalId
  }
}

// Reference to existing Key Vault resource
resource keyVault  'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: '${namePrefix}kv${nameSuffix}'
}

// Assign Key Vault Secrets User role to allow Data Factory to access secrets
resource keyVaultRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(dataFactory.id, keyVault.id, 'Reader')
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6') // Key Vault Secrets User role
    principalId: dataFactory.identity.principalId
  }
}

// Reference to existing SQL Server resource
resource sqlServer 'Microsoft.Sql/servers@2023-05-01-preview' existing = {
  name: '${namePrefix}sql${nameSuffix}'
}

// Assign Reader role to Data Factory for SQL Server access
resource sqlRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(dataFactory.id, sqlServer.id, 'Reader')
  scope: sqlServer
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'acdd72a7-3385-48ef-bd42-f606fba81ae7') // Reader role
    principalId: dataFactory.identity.principalId
  }
}

// Reference to existing Databricks workspace
resource databricks 'Microsoft.Databricks/workspaces@2024-05-01' existing = if (statusADB ) {
  name: '${namePrefix}dbw${nameSuffix}'
}

// Assign Contributor role to Data Factory for Databricks workspace access
resource databricksRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (statusADB ) {
  name: guid(dataFactory.id, databricks.id, 'Contributor')
  scope: databricks
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c') // Reader role
    principalId: dataFactory.identity.principalId
  }
}

//Reference to existing Function App
resource functionApp 'Microsoft.Web/sites@2023-12-01' existing = if (statusFunction) {
  name: '${namePrefix}func${nameSuffix}'
}

// Assign Contributor role to Data Factory for Function App access
resource functionAppRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' =  if (statusFunction) {
  name: guid(dataFactory.id, functionApp.id, 'Contributor')
  scope: functionApp
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c') // Reader role
    principalId: dataFactory.identity.principalId
  }
}

// Reference to existing Storage Account
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: '${namePrefix}${nameStorage}${nameSuffix}'
}

// Assign Storage Blob Data Contributor role to Data Factory for storage access
resource storageAccountRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(dataFactory.id, storageAccount.id, 'StorageBlobDataContributor')
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe') // Storage Blob Data Contributor role
    principalId: dataFactory.identity.principalId
  }
}

// Output important resource information
output location string = location
output name string = dataFactory.name
output resourceGroupName string = resourceGroup().name
output resourceId string = dataFactory.id

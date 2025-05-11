// Input parameters
param adbWorkspaceName string // = 'cfcumulusdevdbwuks04'
param nameStorage string      // = 'cfcumulusdevdlsuks04'
param keyVaultName string 
param databricksID string

resource databricks 'Microsoft.Databricks/workspaces@2024-05-01' existing = {
  name: adbWorkspaceName
}

var StorageBlobDataContributorId = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'

// Reference to existing Storage Account
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: nameStorage
}

// Assign Storage Blob Data Contributor role to Data Factory for storage access
resource storageAccountRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(databricks.id, storageAccount.id, 'StorageBlobDataContributor')
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', StorageBlobDataContributorId) // Storage Blob Data Contributor role
    principalId: databricksID
  }
}


// Reference to existing Key Vault resource
resource keyVault  'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: keyVaultName
}

// Assign Key Vault Secrets User role to allow Data Factory to access secrets
resource keyVaultRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(databricks.id, keyVault.id, 'Reader')
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6') // Key Vault Secrets User role
    principalId: databricksID
  }
}

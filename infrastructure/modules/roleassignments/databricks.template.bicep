// Input parameters
param adbWorkspaceName string // = 'cfcumulusdevdbwuks04'
param nameStorage string      // = 'cfcumulusdevdlsuks04'
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

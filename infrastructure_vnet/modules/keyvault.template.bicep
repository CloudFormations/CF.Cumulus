@description('Resource group location.')
param location string = resourceGroup().location

@description('Key Vault Name.')
param keyVaultName string 

@description('Log Analytics Workspace Name.')
param logAnalyticsWorkspaceName string

@description('Tenant Id value.')
param tenantId string = subscription().tenantId

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  properties:{
    enableRbacAuthorization: true
    sku: {
      name: 'standard'
      family: 'A'
    }
    tenantId: tenantId
    accessPolicies: []
  }
}

// resource deployerRoleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
//   name: guid(keyVault.id, deployer().objectId, 'KeyVaultContributor')
//   properties: {
//     roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7') // Key Vault Contributor role
//     principalId: deployer().objectId
//     principalType: 'ServicePrincipal'
//     scope: keyVault.id
//   }
// }

// Get existing Log Analytics Resource for Id value
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {  
  name: logAnalyticsWorkspaceName
}


// Enable Diagnostic Settings to send logs to Log Analytics
resource keyVaultDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'keyVaultDiagnostics'
  scope: keyVault
  properties: {
  workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        category: 'AuditEvent'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}


output location string = location
output name string = keyVault.name
output resourceGroupName string = resourceGroup().name
output keyVaultId string = keyVault.id
output keyVaultUri string = keyVault.properties.vaultUri

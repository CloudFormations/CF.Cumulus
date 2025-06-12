@description('Resource group location.')
param location string = resourceGroup().location

@description('Resource name prefix as per template naming concatenated in the main file.')
@minLength(3) // "logAnalyticsWorkspaceName" within the resource has a min length of 4. Adding this decorator constraint removes the warning.
param namePrefix string 

@description('Resource name suffix as per template naming concatenated in the main file.')
param nameSuffix string 

@description('Tenant Id value.')
param tenantId string = subscription().tenantId


var name = '${namePrefix}kv${nameSuffix}'

var logAnalyticsWorkspaceName = '${namePrefix}log${nameSuffix}'


resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: name
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

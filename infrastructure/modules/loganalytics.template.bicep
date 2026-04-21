@description('Resource group location.')
param location string = resourceGroup().location

@description('Log Analytics Workspace Name.')
param logAnalyticsWorkspaceName string

@description('Environment name such as dev, test, prod.')
param envName string 

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  
  name: logAnalyticsWorkspaceName
  location: location
  properties: {
    sku: {
      name: 'pergb2018'
    }
    retentionInDays: (envName == 'dev') ? 30 : 90
  }
}

var keyObj = listKeys(resourceId('Microsoft.OperationalInsights/workspaces', logAnalyticsWorkspaceName), '2020-10-01')

output primarySharedKey  string = keyObj.primarySharedKey
output resourceId string = logAnalyticsWorkspace.id

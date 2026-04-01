@description('Resource group location.')
param location string = resourceGroup().location

@description('Environment name, such as dev, test, prod.')
param envName string

@description('Application Insights Name.')
param applicationInsightsName string

@description('Log Analytics Workspace Name.')
param logAnalyticsWorkspaceName string

// Get existing Log Analytics Resource for Id value
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {  
  name: logAnalyticsWorkspaceName
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Redfield'
    Request_Source: 'IbizaAIExtension'
    WorkspaceResourceId: logAnalyticsWorkspace.id
    IngestionMode: 'LogAnalytics'
    RetentionInDays: (envName == 'dev') ? 30 : 90
  }
}

output location string = location
output name string = appInsights.name
output resourceGroupName string = resourceGroup().name
output resourceId string = appInsights.id

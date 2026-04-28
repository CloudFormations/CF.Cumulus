@description('Resource group location.')
param location string = resourceGroup().location

@description('Environment name, such as dev, test, prod.')
param envName string

@description('Resource name prefix as per template naming concatenated in the main file.')
@minLength(3) // "logAnalyticsWorkspaceName" within the resource has a min length of 4. Adding this decorator constraint removes the warning.
param namePrefix string 

@description('Resource name suffix as per template naming concatenated in the main file.')
param nameSuffix string 

var name = '${namePrefix}appi${nameSuffix}'

var logAnalyticsWorkspaceName = '${namePrefix}log${nameSuffix}'

// Get existing Log Analytics Resource for Id value
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {  
  name: logAnalyticsWorkspaceName
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: name
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

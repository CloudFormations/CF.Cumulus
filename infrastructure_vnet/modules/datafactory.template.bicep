@description('Resource group location.')
param location string = resourceGroup().location

@description('Resource name prefix as per template naming concatenated in the main file.')
@minLength(3) // "logAnalyticsWorkspaceName" within the resource has a min length of 4. Adding this decorator constraint removes the warning.
param namePrefix string 

@description('Resource name suffix as per template naming concatenated in the main file.')
param nameSuffix string 

@description('Data Factory resource name.')
param nameFactory string

@description('Option to configure Data Factory linked to GitHub.')
param configureGitHub bool

var name = '${namePrefix}${nameFactory}${nameSuffix}'

var logAnalyticsWorkspaceName = '${namePrefix}log${nameSuffix}'

var repoConfig = {
  accountName: 'cfsource'
  repositoryName: 'CF.Cumulus'
  collaborationBranch: 'main'
  rootFolder: '/src/azure.datafactory'
  type: 'FactoryGitHubConfiguration'
}

resource dataFactory 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: name
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    repoConfiguration: (configureGitHub == true) ? repoConfig : {}
    globalParameters: {
      // Define your global parameters here
      envName: {
        type: 'String'
        value: 'Dev'
      }
    }
  }
}


// Get existing Log Analytics Resource for Id value
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {  
  name: logAnalyticsWorkspaceName
}

resource dataFactoryDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: dataFactory
  name: 'logs-${dataFactory.name}'
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logAnalyticsDestinationType: 'Dedicated'
    logs: [
      {
        category: 'ActivityRuns'
        enabled: true
      }
      {
        category: 'PipelineRuns'
        enabled: true
      }
      {
        category: 'TriggerRuns'
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

// Deploy Data Factory Artifacts as ARM Template if configureGitHub == false


output location string = location
output name string = dataFactory.name
output resourceGroupName string = resourceGroup().name
output resourceId string = dataFactory.id

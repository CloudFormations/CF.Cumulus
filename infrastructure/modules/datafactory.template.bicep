param location string = resourceGroup().location

param namePrefix string 
param nameSuffix string 
param nameFactory string
param envName string

param logAnalyticsWorkspaceId string

var name = '${namePrefix}${nameFactory}${nameSuffix}'

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
    repoConfiguration: (envName == 'dev') ? repoConfig : {}
    globalParameters: {
      // Define your global parameters here
      envName: {
        type: 'String'
        value: 'Dev'
      }
    }
  }
}

output location string = location
output name string = dataFactory.name
output resourceGroupName string = resourceGroup().name
output resourceId string = dataFactory.id

resource dataFactoryDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: dataFactory
  name: 'logs-${dataFactory.name}'
  properties: {
    workspaceId: logAnalyticsWorkspaceId
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

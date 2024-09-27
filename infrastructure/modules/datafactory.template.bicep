param location string = resourceGroup().location

param namePrefix string 
param nameSuffix string 
param nameFactory string
param envName string


var name = '${namePrefix}${nameFactory}${nameSuffix}'
var repoConfig = {
  accountName: 'cfsource'
  collaborationBranch: 'main'
  projectName: 'CF.Cumulus'
  repositoryName: 'CF.Cumulus'
  rootFolder: '/src/azure.datafactory'
  type: 'FactoryVSTSConfiguration'
  tenantId: subscription().tenantId
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

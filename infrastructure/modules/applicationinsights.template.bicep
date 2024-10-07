param location string = resourceGroup().location

param envName string

param namePrefix string 
param nameSuffix string 

var name = '${namePrefix}appi${nameSuffix}'

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: name
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Redfield'
    Request_Source: 'IbizaAIExtension'
    RetentionInDays: (envName == 'dev') ? 30 : 90
  }
}

output location string = location
output name string = appInsights.name
output resourceGroupName string = resourceGroup().name
output resourceId string = appInsights.id

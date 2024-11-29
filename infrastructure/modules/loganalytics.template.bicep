param location string = resourceGroup().location

param envName string

param namePrefix string 
param nameSuffix string 

var name = '${namePrefix}log${nameSuffix}'

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  
  name: name
  location: location
  properties: {
    sku: {
      name: 'pergb2018'
    }
    retentionInDays: (envName == 'dev') ? 30 : 90
  }
}

var keyObj = listKeys(resourceId('Microsoft.OperationalInsights/workspaces', name), '2020-10-01')

output primarySharedKey  string = keyObj.primarySharedKey
output resourceId string = logAnalyticsWorkspace.id

@description('Resource group location.')
param location string = resourceGroup().location

@description('Resource name prefix as per template naming concatenated in the main file.')
@minLength(1) // "name" within the resource has a min length of 4. Adding this decorator constraint removes the warning.
param namePrefix string 

@description('Resource name suffix as per template naming concatenated in the main file.')
param nameSuffix string 

@description('Environment name such as dev, test, prod.')
param envName string 

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

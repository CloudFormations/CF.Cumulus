// Input parameters for resource naming and location
@description('Location for all resources.')
param location string = resourceGroup().location

param namePrefix string 
param nameSuffix string 
param nameStorage string

// Construct resource names using prefix and suffix
var functionAppName = '${namePrefix}func${nameSuffix}'
var hostingPlanName = '${namePrefix}asp${nameSuffix}'
var storageAccountName = '${namePrefix}${nameStorage}${nameSuffix}'
var applicationInsightsName = '${namePrefix}appi${nameSuffix}'

var contentShare = '${functionAppName}bb6a'

// Reference existing Application Insights instance
resource applicationInsight 'Microsoft.Insights/components@2020-02-02' existing = {
  name: applicationInsightsName
}

// Reference existing Storage Account
resource functionStorage 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: storageAccountName
}

// Create Elastic Premium App Service Plan for the Function App
resource functionHostingPlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: hostingPlanName
  location: location
  sku: {
    name: 'EP1'
    tier: 'ElasticPremium'
    size: 'EP1'
    family: 'EP'
    capacity: 1
  }
  kind: 'elastic'
}


// Create the Function App with isolated .NET runtime
resource functionApp 'Microsoft.Web/sites@2022-03-01' = {
  name: functionAppName
  kind: 'functionapp'
  location: location
  // Enable managed identity for the Function App
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    name: functionAppName
    //serverFarmId: hostingPlan.id
    siteConfig: {
      // Application settings for Function App configuration
      appSettings: [
        // Function runtime version
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        // Specify .NET isolated runtime
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet-isolated'
        }
        // Enable .NET isolated placeholder mode
        {
          name: 'WEBSITE_USE_PLACEHOLDER_DOTNETISOLATED'
          value: '1'
        }
        // Application Insights integration settings
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: applicationInsight.properties.ConnectionString
        }
        {
          name: 'APPLICATIONINSIGHTS_INSTRUMENTATIONKEY'
          value: applicationInsight.properties.InstrumentationKey
        }
        // Storage account configuration for the Function App
        // {
        //   name: 'AzureWebJobsStorage__accountName'
        //   value: storageAccountName
        // }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${functionStorage.listKeys().keys[0].value};BlobEndpoint=https://${storageAccountName}.blob.core.windows.net/;FileEndpoint=https://${storageAccountName}.file.core.windows.net/;TableEndpoint=https://${storageAccountName}.table.core.windows.net/;QueueEndpoint=https://${storageAccountName}.queue.core.windows.net/'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${functionStorage.listKeys().keys[0].value};EndpointSuffix=core.windows.net'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: contentShare
        }
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '1'
        }
      ]
      cors: {
        allowedOrigins: [
          'https://portal.azure.com'
        ]
      }
      use32BitWorkerProcess: false
      ftpsState: 'FtpsOnly'
      netFrameworkVersion: 'v8.0'
    }
    clientAffinityEnabled: false
    virtualNetworkSubnetId: null
    functionsRuntimeAdminIsolationEnabled: true
    publicNetworkAccess: 'Enabled'
    httpsOnly: true
    serverFarmId: '/subscriptions/${subscription().subscriptionId}/resourcegroups/${resourceGroup().name}/providers/Microsoft.Web/serverfarms/${functionHostingPlan.name}'
  }
  dependsOn: []
}

// Configure SCM (Source Control Manager) publishing credentials
resource name_scm 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2022-09-01' = {
  parent: functionApp
  name: 'scm'
  properties: {
    allow: true
  }
}

// Configure FTP publishing credentials
resource name_ftp 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2022-09-01' = {
  parent: functionApp
  name: 'ftp'
  properties: {
    allow: true
  }
}


// Output important values
output functionAppName string = functionApp.name
output functionAppIdentityPrincipalId string = functionApp.identity.principalId

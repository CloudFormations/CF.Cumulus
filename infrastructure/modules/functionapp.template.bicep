@description('Resource group location.')
param location string = resourceGroup().location

@description('Resource name prefix as per template naming concatenated in the main file.')
@minLength(3) // "logAnalyticsWorkspaceName" within the resource has a min length of 4. Adding this decorator constraint removes the warning.
param namePrefix string 

@description('Resource name suffix as per template naming concatenated in the main file.')
param nameSuffix string 

@description('Supporting storage account resource name.')
param nameStorage string

@description('App service plan SKU.')
param aspSKU string

// Construct resource names using prefix and suffix
var functionAppName = '${namePrefix}func${nameSuffix}'
var hostingPlanName = '${namePrefix}asp${nameSuffix}'
var storageAccountName = '${namePrefix}${nameStorage}${nameSuffix}'
var applicationInsightsName = '${namePrefix}appi${nameSuffix}'
var logAnalyticsWorkspaceName = '${namePrefix}log${nameSuffix}'


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
resource functionHostingPlanPremium 'Microsoft.Web/serverfarms@2023-12-01' = if (aspSKU == 'premium') {
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


resource functionHostingPlanConsumption 'Microsoft.Web/serverfarms@2024-04-01' =  if (aspSKU == 'consumption') {
  name: hostingPlanName
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
    size: 'Y1'
    family: 'Y'
    capacity: 0
  }
  kind: 'functionapp'
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
    serverFarmId: '/subscriptions/${subscription().subscriptionId}/resourcegroups/${resourceGroup().name}/providers/Microsoft.Web/serverfarms/${hostingPlanName}'
  }
  dependsOn: [
    functionHostingPlanConsumption
    functionHostingPlanPremium
    functionStorage
  ]
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

// Get existing Log Analytics Resource for Id value
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {  
  name: logAnalyticsWorkspaceName
}

// // Enable Diagnostic Settings to send logs to Log Analytics
// resource functionAppDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
//   name: 'functionAppDiagnostics'
//   scope: functionApp
//   properties: {
//     workspaceId: logAnalyticsWorkspace.id
//     logs: [
//       {
//         category: 'FunctionAppLogs'
//         enabled: true
//       }
//       {
//         category: 'AppServiceHTTPLogs'
//         enabled: true
//       }
//       {
//         category: 'AppServiceConsoleLogs'
//         enabled: true
//       }
//       {
//         category: 'AppServiceAuditLogs'
//         enabled: true
//       }
//     ]
//     metrics: [
//       {
//         category: 'AllMetrics'
//         enabled: true
//       }
//     ]
//   }
// }


// Output important values
output functionAppName string = functionApp.name
output functionAppIdentityPrincipalId string = functionApp.identity.principalId

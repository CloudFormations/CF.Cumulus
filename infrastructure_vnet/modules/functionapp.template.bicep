@description('Resource group location.')
param location string = resourceGroup().location

// Construct resource names using prefix and suffix
@description('Function App Name.')
param functionAppName string

@description('Application Insights Name.')
param applicationInsightsName string

@description('Log Analytics Workspace name.')
param logAnalyticsWorkspaceName string

@description('Supporting storage account resource name.')
param storageAccountName string

@description('Supporting storage account container resource name for app deployments.')
param storageAccountContainerName string

@description('App service plan SKU.')
param aspSKU string

@description('App Service Plan Name.')
param hostingPlanName string

@description('Virtual Network Name.')
param vNetName string 

@description('Subnet used for Function App outbound traffic.')
param subnetName string

var vNetId = resourceId('Microsoft.Network/virtualNetworks', vNetName)
var subnetId = '${vNetId}/subnets/${subnetName}'

// var contentShare = '${functionAppName}bb6a'

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

resource functionHostingPlanFlexConsumption 'Microsoft.Web/serverfarms@2024-11-01' =  if (aspSKU == 'flex') {
  name: hostingPlanName
  location: location
  sku: {
    name: 'FC1'
    tier: 'FlexConsumption'
    size: 'FC1'
    family: 'FC'
    capacity: 0
  }
  kind: 'functionapp'
  properties: {
    perSiteScaling: false
    elasticScaleEnabled: false
    maximumElasticWorkerCount: 1
    isSpot: false
    reserved: true
    isXenon: false
    hyperV: false
    targetWorkerCount: 0
    targetWorkerSizeId: 0
    zoneRedundant: false
    asyncScalingEnabled: false
  }
}
// Create the Function App with isolated .NET runtime
resource functionApp 'Microsoft.Web/sites@2024-11-01' = {
  name: functionAppName
  kind: 'functionapp,linux'
  location: location
  // Enable managed identity for the Function App
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    name: functionAppName
    siteConfig: {
      // Application settings for Function App configuration
      appSettings: [
        // Application Insights integration settings
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: applicationInsight.properties.ConnectionString
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${functionStorage.listKeys().keys[0].value};EndpointSuffix=core.windows.net'
        }  
        {
          name: 'DEPLOYMENT_STORAGE_CONNECTION_STRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${functionStorage.listKeys().keys[0].value};EndpointSuffix=core.windows.net'
        }
      ]
      numberOfWorkers: 1
      acrUseManagedIdentityCreds: false
      alwaysOn: false
      http20Enabled: false
      functionAppScaleLimit: 100
      minimumElasticInstanceCount: 0
    }
    clientAffinityEnabled: false
    virtualNetworkSubnetId: subnetId
    dnsConfiguration: {}
    outboundVnetRouting: {
      allTraffic: false
      applicationTraffic: false
      contentShareTraffic: false
      imagePullTraffic: false
      backupRestoreTraffic: false
    }
    publicNetworkAccess: 'Enabled' // Disable after as we need to deploy functions to the application
    httpsOnly: true
    serverFarmId: '/subscriptions/${subscription().subscriptionId}/resourcegroups/${resourceGroup().name}/providers/Microsoft.Web/serverfarms/${hostingPlanName}'
    functionAppConfig: {
      deployment: {
        storage: {
          type: 'blobcontainer'
          value: 'https://${storageAccountName}.blob.core.windows.net/${storageAccountContainerName}'
          authentication: {
            type: 'storageaccountconnectionstring'
            storageAccountConnectionStringName: 'DEPLOYMENT_STORAGE_CONNECTION_STRING'
          }
        }
      }
      runtime: {
        name: 'dotnet-isolated'
        version: '8.0'
      }
      scaleAndConcurrency: {
        maximumInstanceCount: 100
        instanceMemoryMB: 2048
      }
    }
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
    allow: false
  }
}

// Configure FTP publishing credentials
resource name_ftp 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2022-09-01' = {
  parent: functionApp
  name: 'ftp'
  properties: {
    allow: false
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

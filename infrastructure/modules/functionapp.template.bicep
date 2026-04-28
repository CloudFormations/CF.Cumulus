@description('Resource group location.')
param location string = resourceGroup().location

@description('Function App Name.')
param functionAppName string

@description('Application Insights Name.')
param applicationInsightsName string

@description('Supporting storage account resource name.')
param storageAccountName string

@description('Supporting storage account container resource name for app deployments.')
param storageAccountContainerName string

@description('App service plan SKU.')
param aspSKU string

@description('App Service Plan Name.')
param hostingPlanName string

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
resource functionApp 'Microsoft.Web/sites@2022-03-01' =  if (aspSKU != 'flex') {
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
resource flexFunctionApp 'Microsoft.Web/sites@2024-11-01' = if (aspSKU == 'flex') {
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
resource nameScm 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2022-09-01' = if (aspSKU != 'flex') {
  parent: functionApp
  name: 'scm'
  properties: {
    allow: false
  }
}

resource nameScmFlexApp 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2022-09-01' = if (aspSKU == 'flex') {
  parent: flexFunctionApp
  name: 'scm'
  properties: {
    allow: false
  }
}

// Configure FTP publishing credentials
resource nameFtp 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2022-09-01' = if (aspSKU != 'flex') {
  parent: functionApp
  name: 'ftp'
  properties: {
    allow: false
  }
}


resource nameFtpFlexApp 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2022-09-01' = if (aspSKU == 'flex') {
  parent: flexFunctionApp
  name: 'ftp'
  properties: {
    allow: false
  }
}

// Output important values
output functionAppName string = aspSKU == 'flex'
  ? flexFunctionApp.name
  : functionApp.name

output functionAppIdentityPrincipalId string = aspSKU == 'flex'
  ? flexFunctionApp.identity.principalId
  : functionApp.identity.principalId

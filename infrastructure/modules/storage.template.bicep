@description('Resource group location.')
param location string = resourceGroup().location

@description('Resource name prefix as per template naming concatenated in the main file.')
@minLength(1) // "name" within the resource has a min length of 4. Adding this decorator constraint removes the warning.
param namePrefix string

@description('Resource name suffix as per template naming concatenated in the main file.')
param nameSuffix string 

@description('Environment name such as dev, test, prod.')
param envName string 

@description('Name of the storage account. Currently allowed values (dls, st) for the purpose of CF.Cumulus')
@allowed(['dls', 'st'])
param nameStorage string

// Type of storage account (StorageV2 recommended over Storage)
// Note: Storage (v1) has limitations:
// - No support for static website hosting
// - No support for Azure Data Lake Storage Gen2
// - Limited blob tier support
@description('Kind of the storage account. Currently allowed value (StorageV2) for the purpose of CF.Cumulus')
@allowed(['StorageV2'])
param storageKind string

@description('Container configuration for the storage account')
param containers object

@description('Hierarchical Namespace (HNS) support for Data Lake Storage Gen2')
param isHnsEnabled bool 

@description('SFTP support configuration')
param isSftpEnabled bool

@description('Kind of the storage account. Currently allowed value (StorageV2) for the purpose of CF.Cumulus')
@allowed(['Hot', 'Cold'])
param accessTier string = 'Hot'

// Construct storage account name from components
var name = '${namePrefix}${nameStorage}${nameSuffix}'

var keyVaultName = '${namePrefix}kv${nameSuffix}'

var logAnalyticsWorkspaceName = '${namePrefix}log${nameSuffix}'


// Create storage account resource
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: name
  location: location
    // Warning: If storageKind is 'Storage', the following features are not supported:
  // - accessTier
  // - isHnsEnabled 
  // - isSftpEnabled
  kind: storageKind
  sku: {
    name: 'Standard_GRS'
  }
  properties: {
    isHnsEnabled: storageKind == 'StorageV2' ? isHnsEnabled : false
    isSftpEnabled: storageKind == 'StorageV2' ? isSftpEnabled : false
    accessTier: storageKind == 'StorageV2' ? accessTier : null
    minimumTlsVersion: 'TLS1_2'
    // supportsHttpsTrafficOnly: true
    // allowBlobPublicAccess: false
    // allowSharedKeyAccess: true
    // networkAcls: {
    //   defaultAction: 'Deny'
    //   bypass: ['AzureServices']
    // }
  }
  identity: {
    type: 'SystemAssigned'
  }
}

// Configure blob service settings including retention policies
resource storageAccountBlobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    // Set retention periods based on environment
    containerDeleteRetentionPolicy: {
      enabled: true
      days: (envName == 'dev') ? 15 : 30
    }
    deleteRetentionPolicy: {
      enabled: true
      days: (envName == 'dev') ? 15 : 30
    }
  }
}

// Create containers defined in the containers parameter
resource storageAccountContainers 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = [for container in items(containers): {
  parent: storageAccountBlobService
  name: container.value.name
}]

// Get existing Log Analytics Resource for Id value
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {  
  name: keyVaultName
}

// Generate a secret for the access keys (one per container)
module storageAccountSecretInVault 'secret.template.bicep' =  [for container in items(containers): {
  name: '${storageAccount.name}-${container.value.name}-kv-secrets'
  scope: resourceGroup()
  params: {
    keyVaultName: keyVault.name
    secrets: [
      {
        name: '${name}${container.value.name}accesskey'
        value: storageAccount.listKeys().keys[0].value
      }
    ]
  }
}]

// // Get existing Log Analytics Resource for Id value
// resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {  
//   name: logAnalyticsWorkspaceName
// }

// resource storageDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
//   scope: storageAccount
//   name: 'logs-${storageAccount.name}'
//   properties: {
//     workspaceId: logAnalyticsWorkspace.id
//     logAnalyticsDestinationType: 'Dedicated'
//     logs: [
//       {
//         category: 'StorageRead'
//         enabled: true
//       }
//       {
//         category: 'StorageWrite'
//         enabled: true
//       }
//       {
//         category: 'StorageDelete'
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


// Output key properties for reference by other resources
output location string = location
output name string = storageAccount.name
output resourceGroupName string = resourceGroup().name
output resourceId string = storageAccount.id

// Location where the storage account will be deployed
param location string = resourceGroup().location

// Environment name (e.g. dev, prod) - affects retention policies
param envName string

// Naming components for the storage account
param namePrefix string 
param nameSuffix string 
param nameStorage string

// Type of storage account (StorageV2 recommended over Storage)
// Note: Storage (v1) has limitations:
// - No support for static website hosting
// - No support for Azure Data Lake Storage Gen2
// - Limited blob tier support
param storageKind string

// Container configuration for the storage account
param containers object

// Hierarchical Namespace (HNS) support for Data Lake Storage Gen2
param isHnsEnabled bool 

// SFTP support configuration
param isSftpEnabled bool

// Storage tier for the account (Hot or Cold)
@allowed(['Hot', 'Cold'])
param accessTier string = 'Hot'

// Construct storage account name from components
var name = '${namePrefix}${nameStorage}${nameSuffix}'

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

// Output key properties for reference by other resources
output location string = location
output name string = storageAccount.name
output resourceGroupName string = resourceGroup().name
output resourceId string = storageAccount.id

param location string = resourceGroup().location

param envName string

param namePrefix string 
param nameSuffix string 
param nameStorage string

param containers object
param isHnsEnabled bool 
param isSftpEnabled bool

@allowed(['Hot', 'Cold'])
param accessTier string = 'Hot'

var name = '${namePrefix}${nameStorage}${nameSuffix}'

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: name
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_GRS'
  }
  properties: {
    isHnsEnabled: isHnsEnabled
    isSftpEnabled: isSftpEnabled
    accessTier: accessTier
    minimumTlsVersion: 'TLS1_2'
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource storageAccountBlobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
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

resource storageAccountContainers 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = [for container in items(containers): {
  parent: storageAccountBlobService
  name: container.value.name
}]

output location string = location
output name string = storageAccount.name
output resourceGroupName string = resourceGroup().name
output resourceId string = storageAccount.id

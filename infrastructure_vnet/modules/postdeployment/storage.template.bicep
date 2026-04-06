@description('Resource group location.')
param location string = resourceGroup().location

@description('Virtual Network used for the Resource Group.')
param vnetName string

@description('Subnet used for the Storage Account Private Endpoint.')
param subnetName string

@description('Storage Account Name.')
param StorageAccountName string

@description('Blob Private Endpoint Name for the Storage Account.')
param privateEndpointBlobName string

@description('DFS Private Endpoint Name for the Storage Account.')
param privateEndpointDFSName string

@description('Blob Network Interface Card Name for the Storage Account.')
param nicBlobName string

@description('DFS Network Interface Card Name for the Storage Account.')
param nicDFSName string

@description('Private DNS Zone Name Blobs.')
var privateDnsZoneBlobName string = 'privatelink.blob.core.windows.net'

@description('Private DNS Zone Name DFS.')
var privateDnsZoneDFSName string = 'privatelink.dfs.core.windows.net'

@description('Kind of the storage account. Currently allowed value (StorageV2) for the purpose of CF.Cumulus')
@allowed(['StorageV2'])
param storageKind string = 'StorageV2'

// Disable Public access to the Storage Account
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: StorageAccountName
  location: location
  properties: {
    publicNetworkAccess: 'Disabled'
  }
  kind: storageKind
  sku: {
    name: 'Standard_GRS'
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  name: vnetName
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2021-05-01' existing = {
  parent: vnet
  name: subnetName
}

resource privateEndpointBlob 'Microsoft.Network/privateEndpoints@2025-05-01' = {
  name: privateEndpointBlobName
  location: 'uksouth'
  properties: {
    privateLinkServiceConnections: [
      {
        name: privateEndpointBlobName
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
    manualPrivateLinkServiceConnections: []
    customNetworkInterfaceName: nicBlobName
    subnet: {
      id: subnet.id
    }
    ipConfigurations: []
    customDnsConfigs: []
    ipVersionType: 'IPv4'
  }
}

resource privateEndpointDFS 'Microsoft.Network/privateEndpoints@2025-05-01' = {
  name: privateEndpointDFSName
  location: 'uksouth'
  properties: {
    privateLinkServiceConnections: [
      {
        name: privateEndpointDFSName
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'dfs'
          ]
        }
      }
    ]
    manualPrivateLinkServiceConnections: []
    customNetworkInterfaceName: nicDFSName
    subnet: {
      id: subnet.id
    }
    ipConfigurations: []
    customDnsConfigs: []
    ipVersionType: 'IPv4'
  }
}

resource privateDnsZoneBlob 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsZoneBlobName
  location: 'global'
}

resource privateDnsZoneLinkBlob 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZoneBlob
  name: '${privateDnsZoneBlobName}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

resource privateDnsZoneDFS 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsZoneDFSName
  location: 'global'
}

resource privateDnsZoneLinkDFS 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZoneDFS
  name: '${privateDnsZoneDFSName}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

resource privateEndpointDnsGroupBlob 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2025-05-01' = {
  parent: privateEndpointBlob
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-blob-core-windows-net'
        properties: {
          privateDnsZoneId: privateDnsZoneBlob.id   // FIXED: must reference DNS zone, not PE
        }
      }
    ]
  }
}

resource privateEndpointDnsGroupDFS 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2025-05-01' = {
  parent: privateEndpointDFS
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-dfs-core-windows-net'
        properties: {
          privateDnsZoneId: privateDnsZoneDFS.id   // FIXED: must reference DNS zone, not PE
        }
      }
    ]
  }
}

@description('Resource group location.')
param location string = resourceGroup().location

@description('Virtual Network used for the Resource Group.')
param vnetName string

@description('Subnet used for the Key Vault Private Endpoint.')
param subnetName string

@description('Key Vault Name.')
param keyVaultName string

@description('Private Endpoint Name for the Key Vault.')
param privateEndpointName string

@description('Network Interface Card Name for the Key Vault.')
param nicName string

@description('Tenant Id value.')
param tenantId string = subscription().tenantId

@description('Private DNS Zone Name.')
var privateDnsZoneName string = 'privatelink.vaultcore.azure.net'

// Disable Public access to Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' =  {
  name: keyVaultName
  location: location
  properties: {
    publicNetworkAccess: 'Disabled'
    sku: {
      name: 'standard'
      family: 'A'
    }
    tenantId: tenantId
    accessPolicies: []
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  name: vnetName
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2021-05-01' existing = {
  parent: vnet
  name: subnetName
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2025-05-01' = {
  name: privateEndpointName
  location: 'uksouth'
  properties: {
    privateLinkServiceConnections: [
      {
        name: privateEndpointName
        properties: {
          privateLinkServiceId: keyVault.id
          groupIds: [
            'vault'
          ]
        }
      }
    ]
    manualPrivateLinkServiceConnections: []
    customNetworkInterfaceName: nicName
    subnet: {
      id: subnet.id
    }
    ipConfigurations: []
    customDnsConfigs: []
    ipVersionType: 'IPv4'
  }
}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsZoneName
  location: 'global'
}

resource privateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZone
  name: '${privateDnsZoneName}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

resource privateEndpointDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2025-05-01' = {
  parent: privateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-vaultcore-azure-net'
        properties: {
          privateDnsZoneId: privateDnsZone.id   // FIXED: must reference DNS zone, not PE
        }
      }
    ]
  }
}

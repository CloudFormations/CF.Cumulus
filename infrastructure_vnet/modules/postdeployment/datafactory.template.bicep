@description('Resource group location.')
param location string = resourceGroup().location

@description('Virtual Network used for the Resource Group.')
param vnetName string

@description('Subnet used for the Data Factory Private Endpoint.')
param subnetName string

@description('Data Factory Name.')
param dataFactoryName string

@description('Private Endpoint Name for the Data Factory.')
param privateEndpointName string

@description('Network Interface Card Name for the Data Factory.')
param nicName string

@description('Private DNS Zone Name.')
var privateDnsZoneName string = 'privatelink.datafactory.azure.net'

// Disable Public access to Data Factory
resource dataFactory 'Microsoft.DataFactory/factories@2018-06-01' =  {
  name: dataFactoryName
  location: location
  properties: {
    publicNetworkAccess: 'Disabled'
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
          privateLinkServiceId: dataFactory.id
          groupIds: [
            'dataFactory'
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
        name: 'privatelink-datafactory-azure-net'
        properties: {
          privateDnsZoneId: privateDnsZone.id   // FIXED: must reference DNS zone, not PE
        }
      }
    ]
  }
}

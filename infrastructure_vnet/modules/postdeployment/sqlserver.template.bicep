@description('Resource group location.')
param location string = resourceGroup().location

@description('Virtual Network used for the Resource Group.')
param vnetName string

@description('Subnet used for the SQL Private Endpoint.')
param subnetName string

@description('SQL Server Name.')
param sqlServerName string

@description('Private Endpoint Name for the SQL Server.')
param privateEndpointName string

@description('Private DNS Zone Name.')
var privateDnsZoneName string = 'privatelink${environment().suffixes.sqlServerHostname}'

@description('Private DNS Group Name.')
var pvtEndpointDnsGroupName string = '${privateEndpointName}/mydnsgroupname'

// Disable Public access to SQL Server
resource sqlServer 'Microsoft.Sql/servers@2023-05-01-preview' =  {
  name: sqlServerName
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

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: privateEndpointName
  location: location
  properties: {
    subnet: {
      id: subnet.id
    }
    privateLinkServiceConnections: [
      {
        name: privateEndpointName
        properties: {
          privateLinkServiceId: sqlServer.id
          groupIds: [
            'sqlServer'
          ]
        }
      }
    ]
  }
  dependsOn: [
    vnet
  ]
}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsZoneName
  location: 'global'
  properties: {}
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

resource pvtEndpointDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-05-01' = {
  name: pvtEndpointDnsGroupName
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateDnsZone.id
        }
      }
    ]
  }
  dependsOn: [
    privateEndpoint
  ]
}


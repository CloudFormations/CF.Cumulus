@description('Resource group location.')
param location string = resourceGroup().location

@description('Function App Name.')
param functionAppName string

@description('Function App Private Endpoint Name.')
param privateEndpointName string

@description('Virtual Network Name.')
param vnetName string 

@description('Subnet used for Function App inbound traffic with Private Endpoint.')
param subnetName string

var vNetId = resourceId('Microsoft.Network/virtualNetworks', vnetName)
var subnetId = '${vNetId}/subnets/${subnetName}'

// Create the Function App with isolated .NET runtime
resource functionApp 'Microsoft.Web/sites@2024-11-01' =  {
  name: functionAppName
  location: location
  properties: {
    publicNetworkAccess: 'Disabled'
  }
}
var functionAppExternalId = resourceId('Microsoft.Web/sites', functionAppName)
var privateDNSZoneAzureWebsiteExternalId = resourceId(
  'Microsoft.Network/privateDnsZones',
  'privatelink.azurewebsites.net'
)

var privateEndpointId = resourceId(
  'Microsoft.Network/privateEndpoints',
  privateEndpointName
)

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2024-07-01' = {
  name: privateEndpointName
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: '${privateEndpointName}-896d'
        id: '${privateEndpointId}/privateLinkServiceConnections/${privateEndpointName}-896d'
        properties: {
          privateLinkServiceId: functionAppExternalId
          groupIds: [
            'sites'
          ]
          privateLinkServiceConnectionState: {
            status: 'Approved'
            actionsRequired: 'None'
          }
        }
      }
    ]
    manualPrivateLinkServiceConnections: []
    subnet: {
      id: subnetId
    }
    ipConfigurations: []
    customDnsConfigs: []
  }
}

resource privateEndpointDNSZoneAzureWebsite 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-07-01' = {
  parent: privateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-azurewebsites-net'
        properties: {
          privateDnsZoneId: privateDNSZoneAzureWebsiteExternalId
        }
      }
    ]
  }
}

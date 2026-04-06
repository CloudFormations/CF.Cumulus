param privateEndpoints_pep_cfmattdevfunc2uks01_name string = 'pep-cfmattdevfunc2uks01'
param sites_cfmattdevfunc2uks01_externalid string = '/subscriptions/1b2b1db2-3735-4a51-86a5-18fa41b8bb49/resourceGroups/cfmattdevrguks01/providers/Microsoft.Web/sites/cfmattdevfunc2uks01'
param virtualNetworks_cfmattdevvnetuks01_externalid string = '/subscriptions/1b2b1db2-3735-4a51-86a5-18fa41b8bb49/resourceGroups/cfmattdevrguks01/providers/Microsoft.Network/virtualNetworks/cfmattdevvnetuks01'
param privateDnsZones_privatelink_azurewebsites_net_externalid string = '/subscriptions/1b2b1db2-3735-4a51-86a5-18fa41b8bb49/resourceGroups/cfmattdevrguks01/providers/Microsoft.Network/privateDnsZones/privatelink.azurewebsites.net'

resource privateEndpoints_pep_cfmattdevfunc2uks01_name_resource 'Microsoft.Network/privateEndpoints@2024-07-01' = {
  name: privateEndpoints_pep_cfmattdevfunc2uks01_name
  location: 'uksouth'
  properties: {
    privateLinkServiceConnections: [
      {
        name: '${privateEndpoints_pep_cfmattdevfunc2uks01_name}-896d'
        id: '${privateEndpoints_pep_cfmattdevfunc2uks01_name_resource.id}/privateLinkServiceConnections/${privateEndpoints_pep_cfmattdevfunc2uks01_name}-896d'
        properties: {
          privateLinkServiceId: sites_cfmattdevfunc2uks01_externalid
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
      id: '${virtualNetworks_cfmattdevvnetuks01_externalid}/subnets/mattnwk-dev-pep-01'
    }
    ipConfigurations: []
    customDnsConfigs: []
  }
}

resource privateEndpoints_pep_cfmattdevfunc2uks01_name_default 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-07-01' = {
  name: '${privateEndpoints_pep_cfmattdevfunc2uks01_name}/default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-azurewebsites-net'
        properties: {
          privateDnsZoneId: privateDnsZones_privatelink_azurewebsites_net_externalid
        }
      }
    ]
  }
  dependsOn: [
    privateEndpoints_pep_cfmattdevfunc2uks01_name_resource
  ]
}

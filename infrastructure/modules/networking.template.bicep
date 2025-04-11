// Input parameters
param location string = resourceGroup().location

param namePrefix string
param nameSuffix string
param networkConfig object


// Names for Databricks-specific resources
var names = {
  virtualNetwork: '${namePrefix}vnet${nameSuffix}'
  nsg: '${namePrefix}nsg${nameSuffix}'
  subnets: {
    controlPlane: '${namePrefix}snet-control${nameSuffix}'
    workerNodes: '${namePrefix}snet-worker${nameSuffix}'
    serviceEndpoint: '${namePrefix}sep${nameSuffix}'
    privateEndpoint: '${namePrefix}pep${nameSuffix}'
  }
}




// Select network configuration based on environment
var selectedNetworkConfig = networkConfig.default

// Output variables for use in the rest of your Bicep template
var vnetAddressPrefix = selectedNetworkConfig.vnetAddressPrefix
var subnetPrefixes = selectedNetworkConfig.subnetPrefixes


// Create NSG with required rules for Databricks
resource nsg 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name: names.nsg
  location: location
  properties: {
    securityRules: [
      // Inbound Rules
      {
        name: 'databricks-control-plane-to-worker-ssh'
        properties: {
          description: 'Required for Databricks control plane to workers SSH access'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: 'AzureDatabricks'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'databricks-control-plane-to-worker-proxy'
        properties: {
          description: 'Required for Databricks control plane to workers proxy access'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '5557'
          sourceAddressPrefix: 'AzureDatabricks'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 101
          direction: 'Inbound'
        }
      }
      {
        name: 'databricks-worker-to-worker-inbound'
        properties: {
          description: 'Required for worker nodes communication within a cluster'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 102
          direction: 'Inbound'
        }
      }
      // Outbound Rules
      {
        name: 'databricks-worker-to-databricks-cp'
        properties: {
          description: 'Required for workers communication with Databricks control plane'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'AzureDatabricks'
          access: 'Allow'
          priority: 100
          direction: 'Outbound'
        }
      }
      {
        name: 'databricks-worker-to-sql'
        properties: {
          description: 'Required for workers communication with Azure SQL services'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3306'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'Sql'
          access: 'Allow'
          priority: 101
          direction: 'Outbound'
        }
      }
      {
        name: 'databricks-worker-to-storage'
        properties: {
          description: 'Required for workers communication with Azure Storage services'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'Storage'
          access: 'Allow'
          priority: 102
          direction: 'Outbound'
        }
      }
      {
        name: 'databricks-worker-to-eventhub'
        properties: {
          description: 'Required for workers communication with Azure Event Hub'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '9093'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'EventHub'
          access: 'Allow'
          priority: 103
          direction: 'Outbound'
        }
      }
      {
        name: 'databricks-worker-to-worker-outbound'
        properties: {
          description: 'Required for worker nodes communication within a cluster'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 104
          direction: 'Outbound'
        }
      }
    ]
  }
}


// Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: names.virtualNetwork
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: names.subnets.controlPlane
        properties: {
          addressPrefix: subnetPrefixes.privateSubnetCIDR
          networkSecurityGroup: {
            id: nsg.id
          }
          delegations: [
            {
              name: 'databricks-delegation'
              properties: {
                serviceName: 'Microsoft.Databricks/workspaces'
              }
            }
          ]
          // serviceEndpoints: [
          //   {
          //     service: 'Microsoft.Storage'
          //   }
          // ]
        }
      }
      {
        name: names.subnets.workerNodes
        properties: {
          addressPrefix: subnetPrefixes.publicSubnetCIDR
          networkSecurityGroup: {
            id: nsg.id
          }
          delegations: [
            {
              name: 'databricks-delegation'
              properties: {
                serviceName: 'Microsoft.Databricks/workspaces'
              }
            }
          ]
          // serviceEndpoints: [
          //   {
          //     service: 'Microsoft.Storage'
          //   }
          // ]
        }
      }
      {
        name: names.subnets.serviceEndpoint
        properties: {
          addressPrefix: subnetPrefixes.serviceEndpoint
          networkSecurityGroup: {
            id: nsg.id
          }
          // serviceEndpoints: [
          //   {
          //     service: 'Microsoft.Storage'
          //   }
          //   {
          //     service: 'Microsoft.KeyVault'
          //   }
          // ]
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: names.subnets.privateEndpoint
        properties: {
          addressPrefix: subnetPrefixes.privateEndpoint
          networkSecurityGroup: {
            id: nsg.id
          }
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
  }
}

// Private DNS Zone
// resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
//   name: 'cfcdemodevpluks01'
//   location: 'global'
// }

// DNS Zone Virtual Network Link
// resource databricksVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
//   parent: databricksPrivateDnsZone
//   name: uniqueString(vnet.id)
//   location: 'global'
//   properties: {
//     registrationEnabled: false
//     virtualNetwork: {
//       id: vnet.id
//     }
//   }
// }


// Databricks Private Endpoint
// resource databricksPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = {
//   name: '${workspaceName}-pe'
//   location: location
//   properties: {
//     privateLinkServiceConnections: [
//       {
//         name: 'databricks-connection'
//         properties: {
//           privateLinkServiceId: databricksWorkspace.id
//           groupIds: [
//             'databricks_ui_api'
//           ]
//         }
//       }
//     ]
//     subnet: {
//       id: '${vnet.id}/subnets/${names.subnets.privateEndpoint}'
//     }
//   }
// }


// // Private DNS Zone Record for Databricks - only works for Premium workspace SKU
// resource databricksPrivateDnsRecord 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
//   parent: databricksPrivateDnsZone
//   name: workspaceName
//   properties: {
//     ttl: 3600
//     aRecords: [
//       {
//         ipv4Address: databricksPrivateEndpoint.properties.customDnsConfigs[0].ipAddresses[0]
//       }
//     ]
//   }
// }


output vnetId string = vnet.id

// output vnetName string = vnet.name
// output databricksPublicSubnetName string = databricksPublicSubnetName
// output databricksPrivateSubnetName string = databricksPrivateSubnetName

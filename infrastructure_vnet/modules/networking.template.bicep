@description('Resource group location.')
param location string = resourceGroup().location

@description('Environment name.')
param environment string

@description('Network Configuration JSON with NSG, VNet and Subnet details.')
param networkConfig object

@description('Network Configuration resource Names.')
param names object = {}


// Select network configuration based on environment
var selectedNetworkConfig = networkConfig[environment]

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
        }
      }
      {
        name: names.subnets.serviceEndpoint
        properties: {
          addressPrefix: subnetPrefixes.serviceEndpoint
          networkSecurityGroup: {
            id: nsg.id
          }

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
resource privateEndpointSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' = {
  name: names.subnets.privateEndpoint
  parent: vnet
  properties: {
    addressPrefix: networkConfig[environment].subnetPrefixes.privateEndpoint
    privateEndpointNetworkPolicies: 'Enabled' // REQUIRED for PEs
  }
}





output vnetId string = vnet.id
output privateEndpointSubnetId string = privateEndpointSubnet.id


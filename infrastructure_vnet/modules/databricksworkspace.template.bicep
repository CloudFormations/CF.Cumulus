@description('Resource group location.')
param location string = resourceGroup().location

@description('Virtual Network Name.')
param vNetName string 

@description('Subnets configured in VNet. Used to extract control plane and worker nodes.')
param subnets object

@description('Databricks Private Endpoint Name.')
param privateEndpointName string   

@description('Databricks Workspace Name.')
param workspaceName string 

@description('Databricks Managed Resource Group Name, used to host Databricks self-created resources, such as MI and Spark Compute VMs.')
param managedResourceGroupName string

@description('Databricks Workspace Tier.')
param skuTier string = 'Premium'

@description('Public access configuration setting.')
param publicAccess string = 'Enabled'

@description('VNet Id from the resource.')
var vNetId = resourceId('Microsoft.Network/virtualNetworks', vNetName)

@description('VNet Injection parameters')
var workspaceParameters = {
  // Cluster nodes must not get public IPs
  enableNoPublicIp: { value: true }

  // Required for VNet injection
  customVirtualNetworkId: { value: vNetId }
  customPublicSubnetName: { value: subnets.controlPlane }
  customPrivateSubnetName: { value: subnets.workerNodes }
}

// Databricks Workspace
resource databricksWorkspace 'Microsoft.Databricks/workspaces@2024-05-01' = {
  name: workspaceName
  location: location
  sku: { name: skuTier }
  properties: {
    publicNetworkAccess: publicAccess

    managedResourceGroupId: subscriptionResourceId(
      'Microsoft.Resources/resourceGroups',
      managedResourceGroupName
    )


    requiredNsgRules: 'NoAzureDatabricksRules'
    // VNet injection configuration
    parameters: workspaceParameters
  }
}

// Databricks Private Endpoint for UI/API
resource databricksPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: '${workspaceName}-pe'
  location: location
  properties: {
    subnet: {
      id: '${vNetId}/subnets/${privateEndpointName}'
    }
    privateLinkServiceConnections: [
      {
        name: 'databricks-connection'
        properties: {
          privateLinkServiceId: databricksWorkspace.id
          groupIds: [
            'databricks_ui_api'   // required group for Databricks PE
          ]
        }
      }
    ]
  }
}

// Outputs
output databricks_workspace object = databricksWorkspace
output databricksID string = databricksWorkspace.properties.authorizations[0].principalId
output name string = workspaceName
output workspaceID string = databricksWorkspace.id
output workspaceURL string = databricksWorkspace.properties.workspaceUrl
output workspaceProperties object = databricksWorkspace.properties

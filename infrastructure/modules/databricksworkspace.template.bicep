// Input parameters
param location string = resourceGroup().location
param namePrefix string
param nameSuffix string
param skuTier string
param deployVnet bool
param vnetId string = ''

// Optional parameters
param allowPublicAccess bool = true

// Resource names
var workspaceName = '${namePrefix}dbw${nameSuffix}'
var managedResourceGroupName = '${namePrefix}rgm${nameSuffix}'

// var managedIdentityName = '${workspaceName}Identity' // Is this required


// subnet names
var subnets = {
    controlPlane: '${namePrefix}snet-control${nameSuffix}'
    workerNodes: '${namePrefix}snet-worker${nameSuffix}'
}

var workspaceParameters = {
  enableNoPublicIp: { value: false } // Prevents public IPs on cluster nodes
  customVirtualNetworkId: { value: vnetId }
  customPublicSubnetName: { value: subnets.controlPlane }
  customPrivateSubnetName: { value: subnets.workerNodes }
}

// Databricks Workspace
resource databricksWorkspace 'Microsoft.Databricks/workspaces@2024-05-01' = {
  name: workspaceName
  location: location
  sku: { name: skuTier }
  properties: {
    managedResourceGroupId: subscriptionResourceId('Microsoft.Resources/resourceGroups', managedResourceGroupName)
    publicNetworkAccess: allowPublicAccess ? 'Enabled' : 'Disabled'
    parameters: deployVnet ? workspaceParameters : {}
  }
}

// // Managed Identity
// resource mIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-07-31-preview' = {
//   name: managedIdentityName
//   location: location
// }


// Outputs
output databricks_workspace object = databricksWorkspace
output databricksID string = databricksWorkspace.properties.authorizations[0].principalId
output name string = workspaceName
output workspaceID string = databricksWorkspace.id
output workspaceURL string = databricksWorkspace.properties.workspaceUrl
output workspaceProperties object = databricksWorkspace.properties

// output databricks_managed_identity object = mIdentity

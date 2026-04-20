@description('Resource group location.')
param location string = resourceGroup().location

@description('Databricks Workspace Name.')
param workspaceName string 

@description('Databricks Managed Resource Group Name, used to host Databricks self-created resources, such as MI and Spark Compute VMs.')
param managedResourceGroupName string

@description('Databricks Workspace Tier.')
param skuTier string = 'Premium'

@description('Public access configuration setting.')
param publicAccess string = 'Enabled'


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
  }
}


// Outputs
output databricks_workspace object = databricksWorkspace
output databricksID string = databricksWorkspace.properties.authorizations[0].principalId
output name string = workspaceName
output workspaceID string = databricksWorkspace.id
output workspaceURL string = databricksWorkspace.properties.workspaceUrl
output workspaceProperties object = databricksWorkspace.properties

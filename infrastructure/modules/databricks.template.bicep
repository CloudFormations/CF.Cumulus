param location string = resourceGroup().location


@allowed([
  'standard'
  'premium'
])
@description('')
param skuTier string

// @description('')
// param tagValues object = {}

param namePrefix string 
param nameSuffix string 

var workspaceName = '${namePrefix}dbw${nameSuffix}'
var managedResourceGroupId = '/subscriptions/${subscription().subscriptionId}/resourceGroups/${workspaceName}-managed-rg'

var ownerRoleDefId = '8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
var managedIdentityName = '${workspaceName}Identity' 

resource databricksWorkspace 'Microsoft.Databricks/workspaces@2024-05-01' = {
  name: workspaceName
  location: location
  sku: { name: skuTier }
  properties:{
    managedResourceGroupId: managedResourceGroupId
  }
}

resource mIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-07-31-preview' = {
  name: managedIdentityName
  location: location
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name:  guid(ownerRoleDefId,resourceGroup().id)
  scope: resourceGroup()
  properties: {
    principalType: 'ServicePrincipal'
    principalId: mIdentity.properties.principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', ownerRoleDefId)
  }
}

output databricks_workspace_id string = databricksWorkspace.id
output databricks_workspaceUrl string = databricksWorkspace.properties.workspaceUrl
// output databricks_sku_tier string = adbWorkspaceSkuTier
output databricks_dbfs_storage_accountName string = databricksWorkspace.properties.parameters.storageAccountName.value


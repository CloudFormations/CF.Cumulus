/*
  This template automates the integration between Azure Databricks and Azure Key Vault
  by creating a temporary PAT token and establishing a secret scope link.
  
  Primary purposes:
  1. Creates a short-lived Databricks PAT token for initial setup
  2. Uses this token to establish a permanent connection between Databricks and Key Vault
  3. Enables secure secret management for Databricks through Key Vault
*/

// Resource location - inherits from the resource group
param location string = resourceGroup().location

// Managed identity that will be used to execute the deployment scripts
param adb_workspace_managed_identity object

var adb_workspace_managed_identity_id = adb_workspace_managed_identity.properties.principalId

// Databricks workspace details
param adb_workspace_url string 
param adb_workspace_id string 

// Name of the secret scope to be created in Databricks
@secure()
param adb_secret_scope_name string 

// Azure Key Vault details
param akv_id string 
param akv_uri string 

// Lifetime of the temporary PAT token in seconds (1 hour)
// This token is only used during initial setup and will be cleaned up afterwards
var adb_pat_lifetime = '3600'

// First deployment script: Creates a temporary PAT token in Databricks
// This token is needed to authenticate the API calls that set up the secret scope
resource createAdbPATToken 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'createAdbPATToken'
  location: location
  kind: 'AzureCLI'
  // Uses managed identity for secure authentication
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/${adb_workspace_managed_identity_id}': {}
    }
  }
  properties: {
    azCliVersion: '2.26.0'
    // Script will timeout after 5 minutes if not completed
    timeout: 'PT5M'
    // Cleanup temporary resources after script completes
    cleanupPreference: 'OnExpiration'
    // Keep output available for 1 hour
    retentionInterval: 'PT1H'
    // Environment variables passed to the script
    environmentVariables: [
      {
        name: 'ADB_WORKSPACE_URL'
        value: adb_workspace_url
      }
      {
        name: 'ADB_WORKSPACE_ID'
        value: adb_workspace_id
      }
      {
        name: 'PAT_LIFETIME'
        value: adb_pat_lifetime
      }
    ]
    // Shell script that creates the PAT token
    scriptContent: loadTextContent('../deployment/create_pat.sh')
  }
}

// Second deployment script: Creates the secret scope in Databricks and links it to Key Vault
// This establishes the permanent connection between Databricks and Key Vault
resource secretScopeLink 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'secretScopeLink'
  location: location
  kind: 'AzureCLI'
  // Uses the same managed identity as the PAT token creation
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/${adb_workspace_managed_identity_id}': {}
    }
  }
  properties: {
    azCliVersion: '2.26.0'
    // Longer timeout (1 hour) as secret scope creation might take longer
    timeout: 'PT1H'
    // Cleanup after completion
    cleanupPreference: 'OnExpiration'
    // Keep output available for 1 hour
    retentionInterval: 'PT1H'
    // Environment variables needed for secret scope creation
    environmentVariables: [
      {
        name: 'ADB_WORKSPACE_URL'
        value: adb_workspace_url
      }
      {
        name: 'ADB_WORKSPACE_ID'
        value: adb_workspace_id
      }
      {
        name: 'ADB_SECRET_SCOPE_NAME'
        value: adb_secret_scope_name
      }
      {
        name: 'AKV_ID'
        value: akv_id
      }
      {
        name: 'AKV_URI'
        value: akv_uri
      }
      // Uses the PAT token created by the first script
      {
        name: 'ADB_PAT_TOKEN'
        value: createAdbPATToken.properties.outputs.token_value
      }
    ]
    // Shell script that creates the secret scope and links it to Key Vault
    scriptContent: loadTextContent('../deployment/create_secret_scope.sh')
  }
}

// Output the properties of the PAT token creation for logging/debugging
output patOutput object = createAdbPATToken.properties

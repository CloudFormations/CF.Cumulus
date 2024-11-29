// Resource naming convention
param location string = resourceGroup().location

// Databricks workspace configuration
@secure()
param adb_secret_scope_name string
param adb_cluster_name string
param adb_workspace_id string
param adb_workspace_url string
param adb_workspace_managed_identity object

var adb_workspace_managed_identity_id = adb_workspace_managed_identity.properties.principalId


// Cluster technical configuration
param adb_spark_version string = '15.4.x-scala2.12'
param adb_node_type string = 'Standard_DS3_v2'

// Autoscaling configuration
param adb_min_worker int = 1 //minimum
param adb_num_worker int = 2 //target
param adb_max_worker int = 3 //maximum
param adb_auto_terminate_min int = 30

// Force update mechanism
param force_update string = utcNow()

// Validation
var isValidWorkerConfig = adb_min_worker <= adb_num_worker && adb_num_worker <= adb_max_worker

// Resource definition
resource createAdbCluster 'Microsoft.Resources/deploymentScripts@2020-10-01' = if (isValidWorkerConfig) {
  name: 'createAdbCluster-${uniqueString(resourceGroup().id)}'
  location: location
  kind: 'AzureCLI'

  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${adb_workspace_managed_identity_id}': {}
    }
  }

  properties: {
    azCliVersion: '2.45.0' // Updated to newer version
    timeout: 'PT5M'
    retentionInterval: 'PT1H'
    cleanupPreference: 'OnSuccess' // Only cleanup on successful execution
    forceUpdateTag: force_update

    environmentVariables: [
      { name: 'ADB_WORKSPACE_URL', value: adb_workspace_url }
      { name: 'ADB_WORKSPACE_ID', value: adb_workspace_id }
      { name: 'ADB_SECRET_SCOPE_NAME', value: adb_secret_scope_name }
      { name: 'DATABRICKS_CLUSTER_NAME', value: adb_cluster_name }
      { name: 'DATABRICKS_SPARK_VERSION', value: adb_spark_version }
      { name: 'DATABRICKS_NODE_TYPE', value: adb_node_type }
      { name: 'DATABRICKS_NUM_WORKERS', value: string(adb_num_worker) }
      { name: 'DATABRICKS_AUTO_TERMINATE_MINUTES', value: string(adb_auto_terminate_min) }
      { name: 'DATABRICKS_MIN_WORKERS', value: string(adb_min_worker) }
      { name: 'DATABRICKS_MAX_WORKERS', value: string(adb_max_worker) }
    ]

    scriptContent: loadTextContent('../deployment/create_cluster.sh')
  }
}

// Output the cluster information
output clusterName string = adb_cluster_name
output deploymentStatus object = createAdbCluster.properties.outputs

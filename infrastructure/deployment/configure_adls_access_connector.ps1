<#
.SYNOPSIS
    Deploys an Access Connector for Azure Databricks and configures a cluster to read/write
    ADLS Gen2 using Managed Identity — no secrets or secret scopes required.

.DESCRIPTION
    Steps performed:
      1. Deploy the Access Connector (System-Assigned MSI)
      2. Assign Storage Blob Data Contributor on the target storage account
      3. Patch an existing Databricks cluster to use the Access Connector identity
         and configure Spark for OAuth/MSI auth against the storage account

.PARAMETER SubscriptionId
    Azure subscription ID to target. The Az context is set to this subscription before
    any resources are deployed or queried.

.PARAMETER ResourceGroupName
    Resource group containing the Databricks workspace and Access Connector.

.PARAMETER StorageAccountResourceGroup
    Resource group containing the ADLS Gen2 storage account (can differ from workspace RG).

.PARAMETER Location
    Azure region for the Access Connector resource.

.PARAMETER AccessConnectorName
    Name for the new Access Connector resource.

.PARAMETER StorageAccountName
    Name of the existing ADLS Gen2 storage account.

.PARAMETER DatabricksWorkspaceUrl
    Workspace URL, e.g. https://adb-<id>.azuredatabricks.net

.PARAMETER DatabricksClusterName
    Name of the existing cluster to patch. Used to resolve the cluster ID automatically.
    Mutually exclusive with DatabricksClusterId.

.PARAMETER DatabricksClusterId
    ID of the existing cluster to patch. If omitted, DatabricksClusterName must be provided.

.PARAMETER DatabricksToken
    Personal access token (or AAD token) for the Databricks REST API.

.EXAMPLE
    # Resolve cluster by name
    .\configure_adls_access_connector.ps1 `
        -SubscriptionId              "00000000-0000-0000-0000-000000000000" `
        -ResourceGroupName           "rg-cumulus-dev" `
        -StorageAccountResourceGroup "rg-cumulus-storage" `
        -Location                    "uksouth" `
        -AccessConnectorName         "ac-cumulus-dev" `
        -StorageAccountName          "stcumulusdev" `
        -DatabricksWorkspaceUrl      "https://adb-1234567890.12.azuredatabricks.net" `
        -DatabricksClusterName       "cumulus-shared-cluster" `
        -DatabricksToken             $env:DATABRICKS_TOKEN
#>

param (
    [Parameter(Mandatory)] [string] $SubscriptionId,
    [Parameter(Mandatory)] [string] $ResourceGroupName,
    [Parameter(Mandatory)] [string] $StorageAccountResourceGroup,
    [Parameter(Mandatory)] [string] $Location,
    [Parameter(Mandatory)] [string] $AccessConnectorName,
    [Parameter(Mandatory)] [string] $StorageAccountName,
    [Parameter(Mandatory)] [string] $DatabricksWorkspaceUrl,
    [Parameter(Mandatory)] [string] $DatabricksToken,
    [string] $DatabricksClusterName,
    [string] $DatabricksClusterId
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $DatabricksClusterId -and -not $DatabricksClusterName) {
    throw "Provide either -DatabricksClusterId or -DatabricksClusterName."
}

Write-Host "Setting Az context to subscription '$SubscriptionId'..."
Set-AzContext -SubscriptionId $SubscriptionId | Out-Null

# ── 1. Deploy Access Connector ────────────────────────────────────────────────

Write-Host "Deploying Access Connector '$AccessConnectorName'..."

$bicepPath = Join-Path $PSScriptRoot '..\marketplace\modules\accessconnector.template.bicep'

$deployment = New-AzResourceGroupDeployment `
    -ResourceGroupName  $ResourceGroupName `
    -TemplateFile       $bicepPath `
    -name               "ac-deploy-$(Get-Date -Format 'yyyyMMddHHmm')" `
    -connectorName      $AccessConnectorName `
    -location           $Location

$accessConnectorId  = $deployment.Outputs['accessConnectorId'].Value
$principalId        = $deployment.Outputs['principalId'].Value

# MsiTokenProvider requires the MSI client ID (appId), which differs from the principalId (objectId).
$accessConnectorClientId = az ad sp show --id $principalId --query appId -o tsv 2>$null
if (-not $accessConnectorClientId) {
    throw "Could not resolve client ID (appId) for Access Connector principal '$principalId'. Ensure you are logged in with sufficient Entra ID read permissions."
}

Write-Host "Access Connector deployed. Principal ID: $principalId  Client ID: $accessConnectorClientId"

# ── 2. Assign Storage Blob Data Contributor on the storage account ─────────────

$storageBlobDataContributorRoleId = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'

Write-Host "Assigning Storage Blob Data Contributor on '$StorageAccountName'..."

$storageAccount = Get-AzStorageAccount `
    -ResourceGroupName $StorageAccountResourceGroup `
    -Name              $StorageAccountName

$existingAssignment = Get-AzRoleAssignment `
    -ObjectId            $principalId `
    -RoleDefinitionId    $storageBlobDataContributorRoleId `
    -Scope               $storageAccount.Id `
    -ErrorAction SilentlyContinue

if (-not $existingAssignment) {
    New-AzRoleAssignment `
        -ObjectId         $principalId `
        -RoleDefinitionId $storageBlobDataContributorRoleId `
        -Scope            $storageAccount.Id | Out-Null
    Write-Host "Role assigned."
} else {
    Write-Host "Role assignment already exists, skipping."
}

# ── 3. Patch Databricks cluster ───────────────────────────────────────────────
#
# azure_attributes.access_connector links the Access Connector MSI to the cluster
# nodes, so no credentials are stored anywhere.
#
# spark_conf tells the ABFS driver to use OAuth/MSI for the specific storage account.

$headers = @{ Authorization = "Bearer $DatabricksToken" }
$baseUrl  = $DatabricksWorkspaceUrl.TrimEnd('/')

# ── Resolve cluster ID from name if not supplied ───────────────────────────────

if (-not $DatabricksClusterId) {
    Write-Host "Resolving cluster ID for name '$DatabricksClusterName'..."

    $allClusters = Invoke-RestMethod `
        -Uri     "$baseUrl/api/2.0/clusters/list" `
        -Headers $headers `
        -Method  Get

    $matchingClusters = @($allClusters.clusters | Where-Object { $_.cluster_name -eq $DatabricksClusterName })

    if ($matchingClusters.Count -eq 0) {
        throw "No cluster found with name '$DatabricksClusterName'."
    }
    if ($matchingClusters.Count -gt 1) {
        $ids = $matchingClusters.cluster_id -join ', '
        throw "Multiple clusters found with name '$DatabricksClusterName': $ids. Use -DatabricksClusterId to specify one."
    }

    $DatabricksClusterId = $matchingClusters[0].cluster_id
    Write-Host "Resolved cluster ID: $DatabricksClusterId"
}

Write-Host "Fetching current cluster config for '$DatabricksClusterId'..."

$getResponse = Invoke-RestMethod `
    -Uri     "$baseUrl/api/2.0/clusters/get?cluster_id=$DatabricksClusterId" `
    -Headers $headers `
    -Method  Get

# clusters/edit requires the full cluster spec, not just changed fields.
# Round-trip through JSON to get a mutable hashtable from the PSObject, then overlay our changes.
$clusterConfig = $getResponse | ConvertTo-Json -Depth 20 | ConvertFrom-Json -AsHashtable

$sparkConf = $clusterConfig['spark_conf'] ?? @{}
$sparkConf["spark.hadoop.fs.azure.account.auth.type.$StorageAccountName.dfs.core.windows.net"]              = "OAuth"
$sparkConf["spark.hadoop.fs.azure.account.oauth.provider.type.$StorageAccountName.dfs.core.windows.net"]    = "org.apache.hadoop.fs.azurebfs.oauth2.MsiTokenProvider"
$sparkConf["spark.hadoop.fs.azure.account.oauth2.msi.tenant.$StorageAccountName.dfs.core.windows.net"]      = (Get-AzContext).Tenant.Id
$sparkConf["spark.hadoop.fs.azure.account.oauth2.client.id.$StorageAccountName.dfs.core.windows.net"]       = $accessConnectorClientId

$clusterConfig['spark_conf']       = $sparkConf
$clusterConfig['azure_attributes'] = @{
    access_connector = @{
        resource_id     = $accessConnectorId
        credential_type = "ManagedIdentity"
    }
}

$editBody = $clusterConfig | ConvertTo-Json -Depth 20

Write-Host "Patching cluster with Access Connector and Spark MSI config..."

Invoke-RestMethod `
    -Uri         "$baseUrl/api/2.0/clusters/edit" `
    -Headers     $headers `
    -Method      Post `
    -Body        $editBody `
    -ContentType 'application/json' | Out-Null

Write-Host ""
Write-Host "Done. Cluster '$DatabricksClusterId' is now configured to access"
Write-Host "'$StorageAccountName' via Managed Identity"
Write-Host ""


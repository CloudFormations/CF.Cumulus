#Assigining the parameters for the environment
param(
    [Parameter(Mandatory=$true)]
    [string] $keyVaultId,

    [Parameter(Mandatory=$true)]
    [string] $keyVaultUri,

    [Parameter(Mandatory=$false)]
    [string] $secretScopeName = "CumulusScope01",

    [Parameter(Mandatory=$true)]
    [string] $databricksWorkspaceURL,

    [Parameter(Mandatory=$true)]
    [string] $storageAccountName
)


# Get Databricks Access Token
$DATABRICKS_AAD_TOKEN = az account get-access-token --resource 2ff814a6-3304-4ab8-85cb-cd0e6f879c1d --query accessToken --output tsv

# Configure databricks config profile
$databrickscfgPath = "$($env:USERPROFILE)\.databrickscfg"
Write-Output "[DEFAULT]" | Out-File $databrickscfgPath -Encoding ASCII
Write-Output "host = https://$($databricksWorkspaceURL)" | Out-File $databrickscfgPath -Encoding ASCII -Append
Write-Output "token = $($DATABRICKS_AAD_TOKEN)" | Out-File $databrickscfgPath -Encoding ASCII -Append

$json = @"
{
    "scope": "$secretScopeName",
    "scope_backend_type": "AZURE_KEYVAULT",
    "backend_azure_keyvault": {
        "resource_id": "$keyVaultId",
        "dns_name": "$keyVaultUri"
    }
}
"@

# Create Databricks Secret Scope
# TODO: Make command idempotent in event that the scope already exists
databricks secrets create-scope --json $json --profile DEFAULT

# Create Databricks Cluster
$sparkConfig = @"
{
    "spark.sql.ansi.enabled": "true",
    "fs.azure.account.key.$storageAccountName.dfs.core.windows.net": "{{secrets/$secretScopeName/$($storageAccountName)rawaccesskey}}"
}
"@

$clusterJSON = @"
{
    "cluster_name": "General Purpose Cluster",
    "spark_version": "15.4.x-scala2.12",
    "spark_conf": $sparkConfig,
    "azure_attributes": {
        "availability": "SPOT_WITH_FALLBACK_AZURE"
    },
    "node_type_id": "Standard_D4ds_v5",
    "autotermination_minutes": 20,
    "data_security_mode": "DATA_SECURITY_MODE_AUTO",
    "runtime_engine": "STANDARD",
    "kind": "CLASSIC_PREVIEW",
    "is_single_node": false,
    "autoscale": {
        "min_workers": 1,
        "max_workers": 4
    }
}
"@

databricks clusters create --json $clusterJSON --profile DEFAULT


# Programmatically find databricks folder path in Repo
$scriptPath = (Join-Path -Path (Get-Location) -ChildPath "src/azure.databricks") 
$scriptPath = (Get-Location).Path -replace 'infrastructure\\deployment',''
$scriptPath += "\src\azure.databricks"
$revertPath = Get-Location

# Deploy Notebooks to Workspace 
$sourcePath = $scriptPath + '\python\notebooks'
Set-Location -Path $sourcePath
databricks bundle deploy --target DEFAULT
Set-Location -Path $revertPath



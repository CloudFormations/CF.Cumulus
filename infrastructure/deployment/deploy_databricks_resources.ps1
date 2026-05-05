# ============================================
# Input Parameters
# ============================================
param(
    [Parameter(Mandatory = $true)]
    [string] $subscriptionId,

    [Parameter(Mandatory = $true)]
    [string] $resourceGroupName,

    [Parameter(Mandatory = $true)]
    [string] $keyVaultName,

    [Parameter(Mandatory = $true)]
    [string] $keyVaultId,

    [Parameter(Mandatory = $true)]
    [string] $keyVaultUri,

    [Parameter(Mandatory = $true)]
    [string] $databricksWorkspaceURL,

    [Parameter(Mandatory = $true)]
    [string] $storageAccountName,

    [Parameter(Mandatory = $false)]
    [string] $secretScopeName = "CumulusScope01",

    [Parameter(Mandatory = $false)]
    [string] $clusterName = "CF.Cumulus.Ingest.Compute"
)

# ============================================
# Assign RBAC: "Key Vault Secrets User" to Databricks
# ============================================

Write-Host "🔍 Retrieving AzureDatabricks service principal..."
$databricksDetails = az ad sp list --display-name "AzureDatabricks" | ConvertFrom-Json

Write-Host "🔐 Assigning Key Vault Secrets User role..."
az role assignment create `
    --assignee-object-id $databricksDetails.id `
    --role "Key Vault Secrets User" `
    --scope "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.KeyVault/vaults/$keyVaultName"

# Verify role assignment
$assignments = az role assignment list `
    --assignee-object-id $databricksDetails.id `
    --scope "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.KeyVault/vaults/$keyVaultName" `
    -o json | ConvertFrom-Json

$role = $assignments | Where-Object { $_.roleDefinitionName -eq "Key Vault Secrets User" }

if ($role) {
    Write-Host "`n============================================" -ForegroundColor Green
    Write-Host "   ✅ PASS — Key Vault Secrets User assigned" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
    Write-Host (" Principal Name:   {0}" -f $role.principalName)
    Write-Host (" Principal Type:   {0}" -f $role.principalType)
    Write-Host (" Scope:            {0}" -f $role.scope)
    Write-Host "============================================`n" -ForegroundColor Green
}
else {
    Write-Host "`n============================================" -ForegroundColor Red
    Write-Host "   ❌ FAIL — Role NOT assigned" -ForegroundColor Red
    Write-Host "============================================" -ForegroundColor Red
    Write-Host " The identity does NOT have the 'Key Vault Secrets User' role."
    Write-Host ""
    Write-Host " Assign manually using:" -ForegroundColor Yellow
    Write-Host " az role assignment create --assignee-object-id <id> --role 'Key Vault Secrets User' --scope <scope>"
    Write-Host "============================================`n" -ForegroundColor Red
}

# ============================================
# Configure Databricks Authentication
# ============================================
Write-Host "🔐 Requesting Databricks AAD access token..."
$DATABRICKS_AAD_TOKEN = az account get-access-token `
    --resource 2ff814a6-3304-4ab8-85cb-cd0e6f879c1d `
    --query accessToken --output tsv

$databrickscfgPath = "$($env:USERPROFILE)\.databrickscfg"

Write-Host "📝 Writing Databricks CLI config..."
@"
[DEFAULT]
host = https://$databricksWorkspaceURL
token = $DATABRICKS_AAD_TOKEN
"@ | Out-File $databrickscfgPath -Encoding ASCII

# ============================================
# Create Databricks Secret Scope (Idempotent)
# ============================================

Write-Host "🔍 Checking if secret scope '$secretScopeName' already exists..."

# Get raw table output (text)
$scopeListText = databricks secrets list-scopes --profile DEFAULT 2>$null

# Extract scope names (skip header line)
$scopeNames = $scopeListText -split "`n" |
    Select-Object -Skip 1 |     # skip header row
    ForEach-Object { ($_ -split "\s+")[0] } |
    Where-Object { $_ -ne "" }

$scopeExists = $scopeNames -contains $secretScopeName

if ($scopeExists) {
    Write-Host "ℹ️ Secret scope '$secretScopeName' already exists — skipping creation." -ForegroundColor Yellow
}
else {
    Write-Host "🔐 Creating secret scope '$secretScopeName'..."

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

    databricks secrets create-scope --json $json --profile DEFAULT

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Secret scope '$secretScopeName' created successfully." -ForegroundColor Green
    }
    else {
        Write-Host "❌ Failed to create secret scope '$secretScopeName'." -ForegroundColor Red
        exit 1
    }
}

# ============================================
# Create Databricks Cluster
# ============================================

$sparkConfig = @"
{
    "spark.sql.ansi.enabled": "true",
    "fs.azure.account.key.$storageAccountName.dfs.core.windows.net":
        "{{secrets/$secretScopeName/$($storageAccountName)rawaccesskey}}"
}
"@

$clusterJSON = @"
{
    "cluster_name": "$clusterName",
    "spark_version": "17.3.x-scala2.13",
    "kind": "CLASSIC_PREVIEW",
    "runtime_engine": "STANDARD",
    "spark_conf": $sparkConfig,
    "azure_attributes": {
        "availability": "SPOT_WITH_FALLBACK_AZURE"
    },
    "node_type_id": "Standard_DS3_v2",
    "autotermination_minutes": 20,
    "is_single_node": true
}
"@

Write-Host "⚙️ Creating Databricks cluster..."
databricks clusters create --json $clusterJSON --profile DEFAULT

# ============================================
# Deploy Notebooks
# ============================================

Write-Host "📁 Locating Databricks repo folder..."
$scriptPath = (Get-Location).Path -replace 'infrastructure\\deployment', ''
$scriptPath = Join-Path $scriptPath "src\azure.databricks"

$sourcePath = Join-Path $scriptPath "python\notebooks"
$revertPath = Get-Location

Write-Host "📤 Deploying notebooks..."
Set-Location -Path $sourcePath
databricks bundle deploy --target DEFAULT
Set-Location -Path $revertPath
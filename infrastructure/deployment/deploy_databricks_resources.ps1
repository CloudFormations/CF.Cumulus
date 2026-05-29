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
    [string] $clusterName = "CF.Cumulus.Ingest.Compute",

    [Parameter(Mandatory = $false)]
    [string] $nodeTypeId = "Standard_D4s_v3",

    [Parameter(Mandatory = $false)]
    [string] $sparkVersion = "17.3.x-scala2.13",

    [Parameter(Mandatory = $true)]
    [string] $dataFactoryName

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
$env:DATABRICKS_HOST = "https://$databricksWorkspaceURL"
$env:DATABRICKS_TOKEN = az account get-access-token `
    --resource 2ff814a6-3304-4ab8-85cb-cd0e6f879c1d `
    --query accessToken `
    --output tsv

if (-not $env:DATABRICKS_TOKEN) {
    throw "Failed to acquire Databricks access token."
}

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
    "spark_version": "$sparkVersion",
    "kind": "CLASSIC_PREVIEW",
    "runtime_engine": "STANDARD",
    "spark_conf": $sparkConfig,
    "azure_attributes": {
        "availability": "SPOT_WITH_FALLBACK_AZURE"
    },
    "node_type_id": "$nodeTypeId",
    "autotermination_minutes": 20,
    "is_single_node": true
}
"@

Write-Host "🔍 Checking if cluster '$clusterName' already exists..."
$existingClusters = databricks clusters list --output json 2>$null | ConvertFrom-Json
$existingCluster  = $existingClusters | Where-Object { $_.cluster_name -eq $clusterName }

if ($existingCluster) {
    Write-Host "ℹ️ Cluster '$clusterName' already exists — skipping creation." -ForegroundColor Yellow
}
else {
    Write-Host "⚙️ Creating Databricks cluster '$clusterName'..."
    databricks clusters create --json $clusterJSON --profile DEFAULT --no-wait
}

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

# ============================================
# Add ADF Managed Identity to Databricks Workspace
# ============================================

Write-Host "🔍 Retrieving ADF managed identity application ID..."
$adfResource   = az datafactory show `
    --name           $dataFactoryName `
    --resource-group $resourceGroupName `
    -o json 2>$null | ConvertFrom-Json

$adfPrincipalId = $adfResource.identity.principalId
$adfAppId       = az ad sp show --id $adfPrincipalId --query appId --output tsv 2>$null

if (-not $adfAppId) {
    Write-Host "`n============================================" -ForegroundColor Red
    Write-Host "   ❌ FAIL — Could not resolve ADF MI application ID" -ForegroundColor Red
    Write-Host "============================================" -ForegroundColor Red
    Write-Host (" Principal ID: {0}" -f $adfPrincipalId)
    Write-Host "============================================`n" -ForegroundColor Red
}
else {
    Write-Host "🔍 Checking if ADF service principal already exists in Databricks workspace..."
    $allSPs     = databricks service-principals list --output json 2>$null | ConvertFrom-Json
    $resolvedSP = $allSPs | Where-Object { $_.applicationId -eq [string]$adfAppId }

    if ($resolvedSP) {
        Write-Host "`n============================================" -ForegroundColor Yellow
        Write-Host "   ℹ️  SKIP — ADF service principal already registered" -ForegroundColor Yellow
        Write-Host "============================================" -ForegroundColor Yellow
        Write-Host (" Application ID: {0}" -f $adfAppId)
        Write-Host "============================================`n" -ForegroundColor Yellow
    }
    else {
        Write-Host "➕ Adding ADF managed identity as service principal..."
        $spJson = @{ applicationId = [string]$adfAppId; displayName = $dataFactoryName } | ConvertTo-Json
        databricks service-principals create --json $spJson --profile DEFAULT 2>$null | Out-Null

        $allSPs     = databricks service-principals list --output json 2>$null | ConvertFrom-Json
        $resolvedSP = $allSPs | Where-Object { $_.applicationId -eq [string]$adfAppId }

        if ($resolvedSP) {
            Write-Host "`n============================================" -ForegroundColor Green
            Write-Host "   ✅ PASS — ADF service principal registered in Databricks" -ForegroundColor Green
            Write-Host "============================================" -ForegroundColor Green
            Write-Host (" Factory:        {0}" -f $dataFactoryName)
            Write-Host (" Application ID: {0}" -f $adfAppId)
            Write-Host "============================================`n" -ForegroundColor Green
        }
        else {
            Write-Host "`n============================================" -ForegroundColor Red
            Write-Host "   ❌ FAIL — Could not register ADF service principal" -ForegroundColor Red
            Write-Host "============================================" -ForegroundColor Red
            Write-Host (" Application ID: {0}" -f $adfAppId)
            Write-Host "============================================`n" -ForegroundColor Red
        }
    }

    # ============================================
    # Grant allow-cluster-create Entitlement
    # ============================================

    if ($resolvedSP) {
        Write-Host "🔐 Granting 'allow-cluster-create' entitlement to ADF service principal..."

        $patch = @{
            schemas    = @("urn:ietf:params:scim:api:messages:2.0:PatchOp")
            Operations = @(@{
                op    = "add"
                path  = "entitlements"
                value = @(@{ value = "allow-cluster-create" })
            })
        } | ConvertTo-Json -Depth 5

        databricks service-principals patch --id $resolvedSP.id --json $patch --profile DEFAULT 2>$null | Out-Null

        $spDetails     = databricks service-principals get $resolvedSP.id --output json 2>$null | ConvertFrom-Json
        $hasEntitlement = $spDetails.entitlements | Where-Object { $_.value -eq "allow-cluster-create" }

        if ($hasEntitlement) {
            Write-Host "`n============================================" -ForegroundColor Green
            Write-Host "   ✅ PASS — allow-cluster-create entitlement granted" -ForegroundColor Green
            Write-Host "============================================" -ForegroundColor Green
            Write-Host (" Factory:        {0}" -f $dataFactoryName)
            Write-Host (" Application ID: {0}" -f $adfAppId)
            Write-Host "============================================`n" -ForegroundColor Green
        }
        else {
            Write-Host "`n============================================" -ForegroundColor Red
            Write-Host "   ❌ FAIL — Could not grant allow-cluster-create entitlement" -ForegroundColor Red
            Write-Host "============================================" -ForegroundColor Red
            Write-Host (" Application ID: {0}" -f $adfAppId)
            Write-Host "============================================`n" -ForegroundColor Red
        }

        # ============================================
        # Add ADF Service Principal to Databricks Admins Group
        # ============================================

        Write-Host "🔍 Resolving Databricks admins group..."
        $adminGroup = databricks groups list --output json 2>$null | ConvertFrom-Json |
            Where-Object { $_.displayName -eq "admins" }

        if (-not $adminGroup) {
            Write-Host "`n============================================" -ForegroundColor Red
            Write-Host "   ❌ FAIL — Could not resolve Databricks admins group" -ForegroundColor Red
            Write-Host "============================================`n" -ForegroundColor Red
        }
        else {
            Write-Host "➕ Adding ADF service principal to admins group..."

            $patch = @{
                schemas    = @("urn:ietf:params:scim:api:messages:2.0:PatchOp")
                Operations = @(@{
                    op    = "add"
                    path  = "members"
                    value = @(@{ value = "$($resolvedSP.id)" })
                })
            } | ConvertTo-Json -Depth 5

            databricks groups patch $adminGroup.id --json $patch --profile DEFAULT 2>$null | Out-Null

            $groupDetails = databricks groups get $adminGroup.id --output json 2>$null | ConvertFrom-Json
            $isMember     = $groupDetails.members | Where-Object { $_.value -eq $resolvedSP.id }

            if ($isMember) {
                Write-Host "`n============================================" -ForegroundColor Green
                Write-Host "   ✅ PASS — ADF service principal added to admins group" -ForegroundColor Green
                Write-Host "============================================" -ForegroundColor Green
                Write-Host (" Factory:        {0}" -f $dataFactoryName)
                Write-Host (" Application ID: {0}" -f $adfAppId)
                Write-Host "============================================`n" -ForegroundColor Green
            }
            else {
                Write-Host "`n============================================" -ForegroundColor Red
                Write-Host "   ❌ FAIL — Could not add ADF service principal to admins group" -ForegroundColor Red
                Write-Host "============================================" -ForegroundColor Red
                Write-Host (" Application ID: {0}" -f $adfAppId)
                Write-Host "============================================`n" -ForegroundColor Red
            }
        }
    }
}
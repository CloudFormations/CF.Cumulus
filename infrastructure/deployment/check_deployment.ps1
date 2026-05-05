# ============================================
# Parameters
# ============================================
param(
    [Parameter(Mandatory = $true)]
    [string] $subscriptionId,

    [Parameter(Mandatory = $true)]
    [string] $resourceGroupName,

    [Parameter(Mandatory = $true)]
    [string] $functionAppName,

    [Parameter(Mandatory = $true)]
    [string] $dataFactoryName,

    [Parameter(Mandatory = $true)]
    [string] $databricksWorkspaceName,

    [Parameter(Mandatory = $true)]
    [string[]] $keyVaultNames,

    [Parameter(Mandatory = $true)]
    [string[]] $storageAccountNames,

    [Parameter(Mandatory = $true)]
    [string] $sqlServerName,

    [Parameter(Mandatory = $true)]
    [string] $sqlDatabaseName,

    [Parameter(Mandatory = $false)]
    [string] $orchestratorType = "ADF",

    [Parameter(Mandatory = $false)]
    [string] $pipelineName = "Wait 1",

    [Parameter(Mandatory = $false)]
    [string] $clusterName = "CF.Cumulus.Ingest.Compute",

    [Parameter(Mandatory = $false)]
    [string] $secretScopeName = "CumulusScope01",

    [Parameter(Mandatory = $false)]
    [boolean] $generateReport = $true
)

# ============================================
# Result Tracking
# ============================================
$checkResults = [System.Collections.Generic.List[hashtable]]::new()

function Add-CheckResult {
    param(
        [string] $Name,
        [bool]   $Passed,
        [string] $Detail = "",
        [switch] $WarnOnly
    )
    $script:checkResults.Add(@{ Name = $Name; Passed = $Passed; WarnOnly = $WarnOnly.IsPresent; Detail = $Detail })
    $colour = if ($Passed) { "Green" } elseif ($WarnOnly) { "Yellow" } else { "Red" }
    $status = if ($Passed) { "PASS" } elseif ($WarnOnly) { "WARN" } else { "FAIL" }
    Write-Host "  [$status] $Name" -ForegroundColor $colour
    if ($Detail) {
        Write-Host "         $Detail" -ForegroundColor $(if ($Passed) { "Gray" } else { "Yellow" })
    }
}

# ============================================
# Helper: Test-RoleAssignment
# ============================================
function Test-RoleAssignment {
    param(
        [string] $PrincipalId,
        [string] $Role,
        [string] $Scope,
        [string] $SubscriptionId
    )
    $assignments = az role assignment list `
        --assignee-object-id $PrincipalId `
        --role               $Role `
        --scope              $Scope `
        --include-inherited `
        --subscription       $SubscriptionId `
        -o json 2>$null | ConvertFrom-Json

    return ($null -ne $assignments -and $assignments.Count -gt 0)
}

# ============================================
# Resolve Managed Identity Principal IDs
# ============================================
Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "  Resolving Managed Identity Principal IDs  " -ForegroundColor Cyan
Write-Host "============================================`n" -ForegroundColor Cyan

$functionAppResource = az resource show `
    --resource-group $resourceGroupName `
    --name           $functionAppName `
    --resource-type  "Microsoft.Web/sites" 2>$null | ConvertFrom-Json

$dataFactoryResource = az resource show `
    --resource-group $resourceGroupName `
    --name           $dataFactoryName `
    --resource-type  "Microsoft.DataFactory/factories" 2>$null | ConvertFrom-Json

$databricksResource = az resource show `
    --resource-group $resourceGroupName `
    --name           $databricksWorkspaceName `
    --resource-type  "Microsoft.Databricks/workspaces" 2>$null | ConvertFrom-Json

$functionAppMIId = $functionAppResource.identity.principalId
$adfMIId         = $dataFactoryResource.identity.principalId
$databricksMIId  = $databricksResource.identity.principalId

if (-not $databricksMIId) {
    Write-Host "  Databricks workspace has no system-assigned MI — falling back to AzureDatabricks service principal." -ForegroundColor Yellow
    $databricksSP   = az ad sp list --display-name "AzureDatabricks" 2>$null | ConvertFrom-Json
    $databricksMIId = $databricksSP[0].id
}

Write-Host "  Function App MI  : $functionAppMIId"
Write-Host "  Data Factory MI  : $adfMIId"
Write-Host "  Databricks MI    : $databricksMIId"

# ============================================
# Resolve Resource Scopes
# ============================================
Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "  Resolving Resource Scopes                 " -ForegroundColor Cyan
Write-Host "============================================`n" -ForegroundColor Cyan

$adfScope = $dataFactoryResource.id

$keyVaultScopes = @()
foreach ($kvName in $keyVaultNames) {
    $kv = az keyvault show `
        --name           $kvName `
        --resource-group $resourceGroupName 2>$null | ConvertFrom-Json
    if ($kv) {
        $keyVaultScopes += $kv.id
        Write-Host "  Key Vault  : $($kv.id)"
    }
    else {
        Write-Host "  WARNING: Could not resolve Key Vault '$kvName'" -ForegroundColor Yellow
    }
}

$storageScopes = @()
foreach ($saName in $storageAccountNames) {
    $sa = az storage account show `
        --name           $saName `
        --resource-group $resourceGroupName 2>$null | ConvertFrom-Json
    if ($sa) {
        $storageScopes += $sa.id
        Write-Host "  Storage    : $($sa.id)"
    }
    else {
        Write-Host "  WARNING: Could not resolve Storage Account '$saName'" -ForegroundColor Yellow
    }
}

# ============================================
# Role Assignment Checks
# ============================================
Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "  Checking Role Assignments                 " -ForegroundColor Cyan
Write-Host "============================================`n" -ForegroundColor Cyan

# Functions App MI -> Data Factory: Data Factory Contributor
Add-CheckResult `
    -Name   "Functions App MI -> ADF '$dataFactoryName': Data Factory Contributor" `
    -Passed ($null -ne $functionAppMIId -and (Test-RoleAssignment `
        -PrincipalId    $functionAppMIId `
        -Role           "Data Factory Contributor" `
        -Scope          $adfScope `
        -SubscriptionId $subscriptionId))

# Databricks MI -> Both Key Vaults: Key Vault Secrets User
foreach ($kvScope in $keyVaultScopes) {
    $kvLabel = $kvScope.Split('/')[-1]
    Add-CheckResult `
        -Name   "Databricks MI -> KV '$kvLabel': Key Vault Secrets User" `
        -Passed ($null -ne $databricksMIId -and (Test-RoleAssignment `
            -PrincipalId    $databricksMIId `
            -Role           "Key Vault Secrets User" `
            -Scope          $kvScope `
            -SubscriptionId $subscriptionId))
}

# Databricks MI -> Both Data Lakes: Storage Blob Data Contributor
foreach ($saScope in $storageScopes) {
    $saLabel = $saScope.Split('/')[-1]
    Add-CheckResult `
        -Name     "Databricks MI -> Storage '$saLabel': Storage Blob Data Contributor" `
        -Passed   ($null -ne $databricksMIId -and (Test-RoleAssignment `
            -PrincipalId    $databricksMIId `
            -Role           "Storage Blob Data Contributor" `
            -Scope          $saScope `
            -SubscriptionId $subscriptionId)) `
        -Detail   "Optional: Databricks accesses storage via cluster Spark config (secret scope key) rather than MI role assignment" `
        -WarnOnly
}

# Data Factory MI -> Both Data Lakes: Storage Blob Data Contributor
foreach ($saScope in $storageScopes) {
    $saLabel = $saScope.Split('/')[-1]
    Add-CheckResult `
        -Name   "Data Factory MI -> Storage '$saLabel': Storage Blob Data Contributor" `
        -Passed ($null -ne $adfMIId -and (Test-RoleAssignment `
            -PrincipalId    $adfMIId `
            -Role           "Storage Blob Data Contributor" `
            -Scope          $saScope `
            -SubscriptionId $subscriptionId))
}

# Data Factory MI -> Both Key Vaults: Key Vault Secrets User
foreach ($kvScope in $keyVaultScopes) {
    $kvLabel = $kvScope.Split('/')[-1]
    Add-CheckResult `
        -Name   "Data Factory MI -> KV '$kvLabel': Key Vault Secrets User" `
        -Passed ($null -ne $adfMIId -and (Test-RoleAssignment `
            -PrincipalId    $adfMIId `
            -Role           "Key Vault Secrets User" `
            -Scope          $kvScope `
            -SubscriptionId $subscriptionId))
}

# ============================================
# SQL db_cumulususer Check (Data Factory MI)
# ============================================
Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "  Checking SQL db_cumulususer (Data Factory MI)" -ForegroundColor Cyan
Write-Host "============================================`n" -ForegroundColor Cyan

$sqlToken = $null
try {
    $encryptedToken = (Get-AzAccessToken -ResourceUrl "https://database.windows.net" -AsSecureString).token
    $sqlToken       = [PSCredential]::new("token", $encryptedToken)
    $sqlFqdn        = "$sqlServerName.database.windows.net"
}
catch {
    Add-CheckResult `
        -Name   "SQL '$sqlDatabaseName': db_cumulususer role exists" `
        -Passed $false `
        -Detail $_.Exception.Message
    Add-CheckResult `
        -Name   "Data Factory MI -> SQL '$sqlDatabaseName': db_cumulususer member" `
        -Passed $false `
        -Detail $_.Exception.Message
}

if ($null -ne $sqlToken) {

    # Check 1: db_cumulususer role exists
    $roleExistsQuery = @"
SELECT CASE
    WHEN EXISTS (
        SELECT 1 FROM sys.database_principals
        WHERE name = 'db_cumulususer' AND type = 'R'
    ) THEN 1 ELSE 0
END AS RoleExists
"@
    try {
        $roleResult = Invoke-Sqlcmd `
            -ServerInstance $sqlFqdn `
            -Database       $sqlDatabaseName `
            -AccessToken    $sqlToken.GetNetworkCredential().Password `
            -Query          $roleExistsQuery `
            -ErrorAction    Stop

        Add-CheckResult `
            -Name   "SQL '$sqlDatabaseName': db_cumulususer role exists" `
            -Passed ($roleResult.RoleExists -eq 1)
    }
    catch {
        Add-CheckResult `
            -Name   "SQL '$sqlDatabaseName': db_cumulususer role exists" `
            -Passed $false `
            -Detail $_.Exception.Message
    }

    # Check 2: ADF MI is member of db_cumulususer
    $memberQuery = @"
SELECT COUNT(*) AS IsMember
FROM sys.database_role_members  drm
JOIN sys.database_principals    dp  ON dp.principal_id = drm.member_principal_id
JOIN sys.database_principals    dr  ON dr.principal_id = drm.role_principal_id
WHERE dp.name = '$dataFactoryName'
  AND dr.name = 'db_cumulususer'
"@
    try {
        $memberResult = Invoke-Sqlcmd `
            -ServerInstance $sqlFqdn `
            -Database       $sqlDatabaseName `
            -AccessToken    $sqlToken.GetNetworkCredential().Password `
            -Query          $memberQuery `
            -ErrorAction    Stop

        Add-CheckResult `
            -Name   "Data Factory MI -> SQL '$sqlDatabaseName': db_cumulususer member" `
            -Passed ($memberResult.IsMember -gt 0)
    }
    catch {
        Add-CheckResult `
            -Name   "Data Factory MI -> SQL '$sqlDatabaseName': db_cumulususer member" `
            -Passed $false `
            -Detail $_.Exception.Message
    }
}

# ============================================
# Databricks Checks
# ============================================
Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "  Checking Databricks Resources            " -ForegroundColor Cyan
Write-Host "============================================`n" -ForegroundColor Cyan

$databricksHost  = "https://$($databricksResource.properties.workspaceUrl)"
$databricksToken = $null
try {
    $databricksToken = az account get-access-token `
        --resource "2ff814a6-3304-4ab8-85cb-cd0e6f879c1d" `
        --query accessToken --output tsv 2>$null
}
catch {
    Write-Host "  WARNING: Could not obtain Databricks AAD token — skipping Databricks checks." -ForegroundColor Yellow
}

function Invoke-DatabricksNotebook {
    param(
        [string]    $NotebookPath,
        [string]    $ClusterId,
        [hashtable] $Params = @{},
        [int]       $TimeoutSeconds = 120
    )
    $body = @{
        run_name            = "DeploymentCheck"
        existing_cluster_id = $ClusterId
        notebook_task       = @{
            notebook_path    = $NotebookPath
            base_parameters  = $Params
        }
    } | ConvertTo-Json -Depth 5

    $run      = Invoke-RestMethod -Uri "$databricksHost/api/2.1/jobs/runs/submit" `
        -Headers $script:dbHeaders -Method Post -Body $body -ContentType "application/json" -ErrorAction Stop
    $runId    = $run.run_id
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)

    do {
        Start-Sleep -Seconds 5
        $status = Invoke-RestMethod -Uri "$databricksHost/api/2.1/jobs/runs/get?run_id=$runId" `
            -Headers $script:dbHeaders -Method Get
    } while ($status.state.life_cycle_state -notin @("TERMINATED", "SKIPPED", "INTERNAL_ERROR") -and (Get-Date) -lt $deadline)

    return @{
        Passed = ($status.state.result_state -eq "SUCCESS")
        Detail = $status.state.state_message
    }
}

if ($null -ne $databricksToken) {
    $script:dbHeaders = @{ Authorization = "Bearer $databricksToken" }
    $notebookRoot     = "/Workspace/Shared/Live/files/deploymentchecks"
    $clusterId        = $null
    $clusterState     = $null

    # Check 1: Cluster exists (reports current state in detail)
    try {
        $clusterList    = Invoke-RestMethod -Uri "$databricksHost/api/2.0/clusters/list" `
            -Headers $script:dbHeaders -Method Get -ErrorAction Stop
        $matchedCluster = $clusterList.clusters | Where-Object { $_.cluster_name -eq $clusterName }
        $clusterId      = $matchedCluster.cluster_id
        $clusterState   = $matchedCluster.state

        Add-CheckResult `
            -Name   "Databricks cluster '$clusterName' exists" `
            -Passed ($null -ne $matchedCluster)
    }
    catch {
        Add-CheckResult `
            -Name   "Databricks cluster '$clusterName' exists" `
            -Passed $false `
            -Detail $_.Exception.Message
    }

    # Check 2: Secret scope exists
    try {
        $scopeList    = Invoke-RestMethod -Uri "$databricksHost/api/2.0/secrets/scopes/list" `
            -Headers $script:dbHeaders -Method Get -ErrorAction Stop
        $matchedScope = $scopeList.scopes | Where-Object { $_.name -eq $secretScopeName }

        Add-CheckResult `
            -Name   "Databricks secret scope '$secretScopeName' exists" `
            -Passed ($null -ne $matchedScope)
    }
    catch {
        Add-CheckResult `
            -Name   "Databricks secret scope '$secretScopeName' exists" `
            -Passed $false `
            -Detail $_.Exception.Message
    }

    # Ensure cluster is RUNNING before notebook checks (checks 3 & 4)
    $clusterReady = $false
    if ($null -ne $clusterId) {
        if ($clusterState -eq "RUNNING") {
            $clusterReady = $true
        }
        elseif ($clusterState -in @("TERMINATED", "PENDING", "RESTARTING", "RESIZING")) {

            if ($clusterState -eq "TERMINATED") {
                Write-Host "  Cluster '$clusterName' is TERMINATED — starting it for notebook checks..." -ForegroundColor Yellow
                try {
                    Invoke-RestMethod -Uri "$databricksHost/api/2.0/clusters/start" `
                        -Headers      $script:dbHeaders `
                        -Method       Post `
                        -Body         (@{ cluster_id = $clusterId } | ConvertTo-Json) `
                        -ContentType  "application/json" `
                        -ErrorAction  Stop | Out-Null
                }
                catch {
                    Write-Host "  WARNING: Could not start cluster — $($_.Exception.Message)" -ForegroundColor Yellow
                }
            }
            else {
                Write-Host "  Cluster '$clusterName' is $clusterState — waiting for it to be RUNNING..." -ForegroundColor Yellow
            }

            Write-Host "  NOTE: Notebook checks 3 & 4 will run once the cluster is RUNNING. Waiting up to 10 minutes..." -ForegroundColor Yellow
            $clusterDeadline = (Get-Date).AddMinutes(10)
            do {
                Start-Sleep -Seconds 30
                $clusterInfo  = Invoke-RestMethod -Uri "$databricksHost/api/2.0/clusters/get?cluster_id=$clusterId" `
                    -Headers $script:dbHeaders -Method Get
                $clusterState = $clusterInfo.state
                Write-Host "    ... cluster state: $clusterState" -ForegroundColor Gray
            } while ($clusterState -ne "RUNNING" -and (Get-Date) -lt $clusterDeadline)

            $clusterReady = ($clusterState -eq "RUNNING")
            if (-not $clusterReady) {
                Write-Host "  WARNING: Cluster did not reach RUNNING within 10 minutes — skipping notebook checks." -ForegroundColor Yellow
            }
        }
        else {
            Write-Host "  WARNING: Cluster '$clusterName' is in state '$clusterState' — skipping notebook checks." -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "  Skipping notebook checks — cluster '$clusterName' not found." -ForegroundColor Yellow
    }

    if ($clusterReady) {

        # Check 3: CheckSecretScope notebook
        try {
            $result = Invoke-DatabricksNotebook `
                -NotebookPath "$notebookRoot/CheckSecretScope" `
                -ClusterId    $clusterId `
                -Params       @{ scope_name = $secretScopeName }
            Add-CheckResult `
                -Name   "Databricks notebook: CheckSecretScope ('$secretScopeName')" `
                -Passed $result.Passed `
                -Detail $result.Detail
        }
        catch {
            Add-CheckResult `
                -Name   "Databricks notebook: CheckSecretScope ('$secretScopeName')" `
                -Passed $false `
                -Detail $_.Exception.Message
        }

        # Check 4: CheckStorageAccount notebook (per storage account)
        foreach ($saName in $storageAccountNames) {
            try {
                $result = Invoke-DatabricksNotebook `
                    -NotebookPath "$notebookRoot/CheckStorageAccount" `
                    -ClusterId    $clusterId `
                    -Params       @{ storage_account_name = $saName }
                Add-CheckResult `
                    -Name   "Databricks notebook: CheckStorageAccount ('$saName')" `
                    -Passed $result.Passed `
                    -Detail $result.Detail
            }
            catch {
                Add-CheckResult `
                    -Name   "Databricks notebook: CheckStorageAccount ('$saName')" `
                    -Passed $false `
                    -Detail $_.Exception.Message
            }
        }
    }
}

# ============================================
# Function App Key Vault + PipelineValidate Check
# ============================================
Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "  Checking Function App via Key Vault Key   " -ForegroundColor Cyan
Write-Host "============================================`n" -ForegroundColor Cyan

$secretName  = "cumulusfunctionsKey"
$functionKey = $null

try {
    $secret      = az keyvault secret show `
        --vault-name $keyVaultNames[0] `
        --name       $secretName 2>$null | ConvertFrom-Json
    $functionKey = $secret.value.Trim("'")

    Add-CheckResult `
        -Name   "Key Vault secret '$secretName' accessible" `
        -Passed (-not [string]::IsNullOrEmpty($functionKey))
}
catch {
    Add-CheckResult `
        -Name   "Key Vault secret '$secretName' accessible" `
        -Passed $false `
        -Detail $_.Exception.Message
}

if (-not [string]::IsNullOrEmpty($functionKey)) {

    $validateUrl = "https://$functionAppName.azurewebsites.net/api/PipelineValidate?code=$functionKey"
    $requestBody = @{
        subscriptionId    = $subscriptionId
        resourceGroupName = $resourceGroupName
        orchestratorName  = $dataFactoryName
        orchestratorType  = $orchestratorType
        pipelineName      = $pipelineName
    } | ConvertTo-Json

    try {
        $response = Invoke-RestMethod `
            -Uri         $validateUrl `
            -Method      Get `
            -Body        $requestBody `
            -ContentType "application/json" `
            -ErrorAction Stop

        Add-CheckResult `
            -Name   "PipelineValidate '$pipelineName' via Function App" `
            -Passed $true `
            -Detail ($response | ConvertTo-Json -Compress -Depth 3)
    }
    catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        $passed     = ($null -ne $statusCode -and [int]$statusCode -lt 500)
        Add-CheckResult `
            -Name   "PipelineValidate '$pipelineName' via Function App" `
            -Passed $passed `
            -Detail "HTTP $statusCode — $($_.Exception.Message)"
    }
}

# ============================================
# Summary Report
# ============================================
$total      = $checkResults.Count
$passCount  = ($checkResults | Where-Object { $_.Passed }).Count
$warnCount  = ($checkResults | Where-Object { -not $_.Passed -and $_.WarnOnly }).Count
$failCount  = ($checkResults | Where-Object { -not $_.Passed -and -not $_.WarnOnly }).Count
$allPassed  = $failCount -eq 0
$colour     = if ($allPassed) { "Green" } else { "Red" }

Write-Host "`n============================================" -ForegroundColor $colour
Write-Host "  Deployment Check Summary" -ForegroundColor $colour
Write-Host "  $passCount / $total checks passed" -ForegroundColor $colour

if ($warnCount -gt 0) {
    Write-Host ""
    Write-Host "  Warnings (optional):" -ForegroundColor Yellow
    $checkResults | Where-Object { -not $_.Passed -and $_.WarnOnly } | ForEach-Object {
        Write-Host "    ! $($_.Name)" -ForegroundColor Yellow
        if ($_.Detail) { Write-Host "      $($_.Detail)" -ForegroundColor Yellow }
    }
}

if (-not $allPassed) {
    Write-Host ""
    Write-Host "  Failed:" -ForegroundColor Red
    $checkResults | Where-Object { -not $_.Passed -and -not $_.WarnOnly } | ForEach-Object {
        Write-Host "    x $($_.Name)" -ForegroundColor Red
        if ($_.Detail) { Write-Host "      $($_.Detail)" -ForegroundColor Yellow }
    }
}

Write-Host "============================================`n" -ForegroundColor $colour

# ============================================
# Markdown Report
# ============================================
if ($generateReport) {
    $runTime     = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $overallText = if ($allPassed) { "PASSED" } else { "FAILED" }
    $warnSuffix  = if ($warnCount -gt 0) { " · $warnCount warning$(if ($warnCount -ne 1) { 's' })" } else { "" }
    $failSuffix  = if ($failCount -gt 0) { " · $failCount failure$(if ($failCount -ne 1) { 's' })" } else { "" }

    $md = [System.Text.StringBuilder]::new()
    [void]$md.AppendLine("# Deployment Check Report")
    [void]$md.AppendLine("")
    [void]$md.AppendLine("| | |")
    [void]$md.AppendLine("|---|---|")
    [void]$md.AppendLine("| **Run** | $runTime |")
    [void]$md.AppendLine("| **Result** | $overallText |")
    [void]$md.AppendLine("| **Summary** | $passCount / $total passed$warnSuffix$failSuffix |")
    [void]$md.AppendLine("")
    [void]$md.AppendLine("## Checks")
    [void]$md.AppendLine("")
    [void]$md.AppendLine("| Status | Check | Detail |")
    [void]$md.AppendLine("|--------|-------|--------|")

    foreach ($r in $checkResults) {
        $icon   = if ($r.Passed) { "✅ PASS" } elseif ($r.WarnOnly) { "⚠️ WARN" } else { "❌ FAIL" }
        $detail = if ($r.Detail) { $r.Detail } else { "" }
        [void]$md.AppendLine("| $icon | $($r.Name) | $detail |")
    }

    if (-not $allPassed) {
        [void]$md.AppendLine("")
        [void]$md.AppendLine("## Failures")
        [void]$md.AppendLine("")
        $checkResults | Where-Object { -not $_.Passed -and -not $_.WarnOnly } | ForEach-Object {
            [void]$md.AppendLine("- ❌ **$($_.Name)**$(if ($_.Detail) { ": $($_.Detail)" })")
        }
    }

    $reportPath = Join-Path $PSScriptRoot "deployment-check-report.md"
    $md.ToString() | Out-File -FilePath $reportPath -Encoding utf8 -Force
    Write-Host "  Report written to: $reportPath" -ForegroundColor Cyan
}

if (-not $allPassed) {
    throw "Deployment check failed: $failCount of $total checks did not pass."
}

# ============================================
# Parameters
# ============================================
param(
    [Parameter(Mandatory = $true)]
    [string] $tenantId,

    [Parameter(Mandatory = $true)]
    [string] $subscriptionName,

    [Parameter(Mandatory = $true)]
    [string] $location,

    [Parameter(Mandatory = $false)]
    [string] $templateFile = "infrastructure/main.bicep",

    [Parameter(Mandatory = $false)]
    [string] $parametersFile = "infrastructure/configuration/_installation/main.bicepparam"
)
# ============================================
# Determine script location
# ============================================
$currentLocation    = Split-Path -Path $MyInvocation.MyCommand.Path -Parent

# ============================================
# Pre-execution module checks
# ============================================
$checkImportsScript = Join-Path $currentLocation "check_imports.ps1"
& $checkImportsScript

# ============================================
# Authenticate Azure CLI
# ============================================
az login --tenant $tenantId

$subscriptionId = az account list `
    --all `
    --query "[?name=='$subscriptionName'].id" `
    --output tsv

# ============================================
# Authenticate Azure PowerShell
# ============================================
Connect-AzAccount -Tenant $tenantId -SubscriptionId $subscriptionId

# ============================================
# Validate parameters
# ============================================
$checkParamsScript = Join-Path $currentLocation "check_params_from_file.ps1"
& $checkParamsScript -parametersFile $parametersFile

$acceptInput = Read-Host "Are the utilised parameters correct? (Y to confirm, anything else to cancel)"

if ($acceptInput.ToUpper() -eq "Y") {
    Write-Host "Proceeding with deployment..."
}
else {
    Write-Host "Cancelling deployment."
    exit
}

# ============================================
# Start Timer + Module Timing Tracking
# ============================================
$processTimerStart     = [System.Diagnostics.Stopwatch]::StartNew()
$processTimerStartDate = Get-Date

$timings = [System.Collections.Generic.List[hashtable]]::new()

function Add-Timing {
    param([string]$Module, [datetime]$StartTime, [timespan]$Elapsed)
    $duration = "{0:00}:{1:00}:{2:00}" -f $Elapsed.Hours, $Elapsed.Minutes, $Elapsed.Seconds
    $entry = [ordered]@{
        Module          = $Module
        StartTime       = $StartTime.ToString("yyyy-MM-dd HH:mm:ss")
        EndTime         = $StartTime.Add($Elapsed).ToString("yyyy-MM-dd HH:mm:ss")
        DurationSeconds = [math]::Round($Elapsed.TotalSeconds, 1)
        Duration        = $duration
    }
    $script:timings.Add($entry)
}

# ============================================
# Deploy Bicep Template
# ============================================
$_modStart = Get-Date; $_modSw = [System.Diagnostics.Stopwatch]::StartNew()
$bicepDeployment = az deployment sub create `
    --subscription $subscriptionName `
    --location $location `
    --template-file $templateFile `
    --parameters $parametersFile |
    ConvertFrom-Json
$_modSw.Stop(); Add-Timing "Bicep Template Deployment" $_modStart $_modSw.Elapsed

# ============================================
# Extract Bicep Outputs
# ============================================
$resourceGroupName       = $bicepDeployment.properties.outputs.rgName.value
$keyVaultName            = $bicepDeployment.properties.outputs.keyVaultName.value
$keyVaultId              = $bicepDeployment.properties.outputs.keyVaultId.value
$keyVaultUri             = $bicepDeployment.properties.outputs.keyVaultUri.value
$databricksWorkspaceName = $bicepDeployment.properties.outputs.databricksWorkspaceName.value
$databricksWorkspaceURL  = $bicepDeployment.properties.outputs.databricksWorkspaceURL.value
$storageAccountName      = $bicepDeployment.properties.outputs.storageAccountName.value
$functionAppName         = $bicepDeployment.properties.outputs.functionAppName.value
$dataFactoryName         = $bicepDeployment.properties.outputs.dataFactoryName.value
$sqlServerName           = $bicepDeployment.properties.outputs.sqlServerName.value
$sqlDatabaseName         = $bicepDeployment.properties.outputs.sqlDatabaseName.value

# ============================================
# Grant Key Vault Secrets Officer to User
# ============================================
$userDetails = az ad signed-in-user show | ConvertFrom-Json
$userId      = $userDetails.id

az role assignment create `
    --role "Key Vault Secrets Officer" `
    --assignee $userId `
    --scope "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.KeyVault/vaults/$keyVaultName"

# ============================================
# Set environment variables for ADF deployments
# ============================================
$Env:SQLSERVER   = $sqlServerName
$Env:SQLDATABASE = $sqlDatabaseName
$Env:DATAFACTORY = $dataFactoryName
$Env:FUNCTIONAPP = $functionAppName
$Env:KEYVAULT    = $keyVaultName

# ============================================
# Resolve script paths before spawning jobs
# ============================================
$deployAzureFunctionsScript      = Join-Path $currentLocation "deploy_azure_functions.ps1"
$deployDatabricksResourcesScript = Join-Path $currentLocation "deploy_databricks_resources.ps1"
$deploySQLDacPacsScript          = Join-Path $currentLocation "deploy_sql_dacpacs.ps1"

# ============================================
# Deploy Azure Functions + Databricks Resources + SQL DACPACs (parallel)
# Each job returns a timing object as its last output item.
# ============================================
Write-Host "`nStarting parallel deployment: Azure Functions, Databricks Resources, SQL DACPACs..." -ForegroundColor Yellow

$parallelJobs = @(
    Start-Job -Name "deploy-functions" -ScriptBlock {
        $sw = [System.Diagnostics.Stopwatch]::StartNew(); $start = Get-Date
        & $using:deployAzureFunctionsScript `
            -currentLocation $using:currentLocation `
            -resourceGroupName $using:resourceGroupName `
            -functionAppName $using:functionAppName `
            -keyVaultName $using:keyVaultName
        $sw.Stop()
        [PSCustomObject]@{ _timing = $true; Module = "Azure Functions"; StartTime = $start; Elapsed = $sw.Elapsed }
    }
    Start-Job -Name "deploy-databricks" -ScriptBlock {
        $sw = [System.Diagnostics.Stopwatch]::StartNew(); $start = Get-Date
        & $using:deployDatabricksResourcesScript `
            -subscriptionId $using:subscriptionId `
            -resourceGroupName $using:resourceGroupName `
            -keyVaultName $using:keyVaultName `
            -keyVaultId $using:keyVaultId `
            -keyVaultUri $using:keyVaultUri `
            -dataFactoryName $using:dataFactoryName `
            -databricksWorkspaceURL $using:databricksWorkspaceURL `
            -storageAccountName $using:storageAccountName
        $sw.Stop()
        [PSCustomObject]@{ _timing = $true; Module = "Databricks Resources"; StartTime = $start; Elapsed = $sw.Elapsed }
    }
    Start-Job -Name "deploy-sqldacpacs" -ScriptBlock {
        $sw = [System.Diagnostics.Stopwatch]::StartNew(); $start = Get-Date
        & $using:deploySQLDacPacsScript `
            -tenantId $using:tenantId `
            -subscriptionId $using:subscriptionId `
            -keyVaultName $using:keyVaultName `
            -sqlServerName $using:sqlServerName `
            -sqlDatabaseName $using:sqlDatabaseName `
            -databricksWorkspaceName $using:databricksWorkspaceName `
            -databricksWorkspaceURL $using:databricksWorkspaceURL `
            -storageAccountName $using:storageAccountName `
            -resourceGroupName $using:resourceGroupName `
            -dataFactoryName $using:dataFactoryName
        $sw.Stop()
        [PSCustomObject]@{ _timing = $true; Module = "SQL DACPACs"; StartTime = $start; Elapsed = $sw.Elapsed }
    }
)

$parallelResults = $parallelJobs | Wait-Job | Receive-Job
$parallelJobs | Remove-Job
$parallelResults | Where-Object { $_._timing -eq $true } | ForEach-Object {
    Add-Timing $_.Module $_.StartTime $_.Elapsed
}

# ============================================
# Deploy Data Factory Components
# ============================================
$deployDataFactoryComponentsScript = Join-Path $currentLocation "deploy_data_factory_components.ps1"

$_modStart = Get-Date; $_modSw = [System.Diagnostics.Stopwatch]::StartNew()
& $deployDataFactoryComponentsScript `
    -tenantId $tenantId `
    -subscriptionName $subscriptionName `
    -location $location `
    -resourceGroupName $resourceGroupName `
    -dataFactoryName $dataFactoryName
$_modSw.Stop(); Add-Timing "Data Factory Components" $_modStart $_modSw.Elapsed

# ============================================
# Final Deployment Timer
# ============================================
$processTimerEnd = $processTimerStart.Elapsed
$elapsedTime = "{0:00}:{1:00}:{2:00}.{3:00}" -f `
    $processTimerEnd.Hours, `
    $processTimerEnd.Minutes, `
    $processTimerEnd.Seconds, `
    ($processTimerEnd.Milliseconds / 10)

Write-Host "Deployment Complete! Elapsed Time $elapsedTime`r`n"

# ============================================
# Export Module Timing CSV
# ============================================
$timingCsvPath = Join-Path $currentLocation "deployment-timing.csv"

$totalRow = [PSCustomObject][ordered]@{
    Module          = "Total"
    StartTime       = $processTimerStartDate.ToString("yyyy-MM-dd HH:mm:ss")
    EndTime         = $processTimerStartDate.Add($processTimerEnd).ToString("yyyy-MM-dd HH:mm:ss")
    DurationSeconds = [math]::Round($processTimerEnd.TotalSeconds, 1)
    Duration        = $elapsedTime
}

$timingRows = @($timings | ForEach-Object { [PSCustomObject]$_ }) + $totalRow
$timingRows | Export-Csv -Path $timingCsvPath -NoTypeInformation -Encoding utf8
Write-Host "Module timings written to: $timingCsvPath" -ForegroundColor Cyan

# ============================================
# Post Deployment Checks and Report
# ============================================
$checkDeployment = Join-Path $currentLocation "check_deployment.ps1"

& $checkDeployment `
    -tenantId $tenantId `
    -subscriptionId $subscriptionId `
    -resourceGroupName $resourceGroupName `
    -functionAppName $functionAppName `
    -dataFactoryName $dataFactoryName `
    -databricksWorkspaceName $databricksWorkspaceName `
    -keyVaultNames @($keyVaultName) `
    -storageAccountNames @($storageAccountName) `
    -sqlServerName $sqlServerName `
    -sqlDatabaseName $sqlDatabaseName `
    -timingCsvPath $timingCsvPath

# ============================================
# Cleanup - Clear environment variables
# ============================================
$Env:SQLSERVER   = ""
$Env:SQLDATABASE = ""
$Env:DATAFACTORY = ""
$Env:FUNCTIONAPP = ""
$Env:KEYVAULT    = ""

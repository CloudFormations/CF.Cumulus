# ============================================
# Parameters
# ============================================
param(
    [Parameter(Mandatory = $true)]
    [string] $tenantId,

    [Parameter(Mandatory = $true)]
    [string] $subscriptionId,

    [Parameter(Mandatory = $true)]
    [string] $keyVaultName,

    [Parameter(Mandatory = $true)]
    [string] $sqlServerName,

    [Parameter(Mandatory = $true)]
    [string] $sqlDatabaseName,

    [Parameter(Mandatory = $true)]
    [string] $dataFactoryName

)

# ============================================
# Determine script location
# ============================================
$currentLocation = Split-Path -Path $MyInvocation.MyCommand.Path -Parent

# ============================================
# Authenticate Azure CLI
# ============================================
az login --tenant $tenantId

# ============================================
# Start Timer
# ============================================
$processTimerStart = [System.Diagnostics.Stopwatch]::StartNew()

# ============================================
# Deploy SQL DACPACs
# ============================================
Write-Host "Deploying SQL DACPACs..." -ForegroundColor Green
$deploySQLDacPacsScript = Join-Path $currentLocation "deploy_sample_sql_dacpacs.ps1"

& $deploySQLDacPacsScript `
    -tenantId $tenantId `
    -subscriptionId $subscriptionId `
    -keyVaultName $keyVaultName `
    -sqlServerName $sqlServerName `
    -sqlDatabaseName $sqlDatabaseName `
    -dataFactoryName $dataFactoryName

# ============================================
# Final Deployment Timer
# ============================================
$processTimerEnd = $processTimerStart.Elapsed
$elapsedTime = "{0:00}:{1:00}:{2:00}.{3:00}" -f `
    $processTimerEnd.Hours, `
    $processTimerEnd.Minutes, `
    $processTimerEnd.Seconds, `
    ($processTimerEnd.Milliseconds / 10)

Write-Host "Deployment Complete! Elapsed Time $elapsedTime`r`n" -ForegroundColor Green
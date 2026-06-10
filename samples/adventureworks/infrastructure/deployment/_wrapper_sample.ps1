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
    [string] $templateFile = "samples/adventureworks/infrastructure/main.bicep",
    
    [Parameter(Mandatory = $false)]
    [string] $parametersFile = "samples/adventureworks/infrastructure/configuration/_installation/main.bicepparam"
)

# ============================================
# Determine script location
# ============================================
$currentLocation = Split-Path -Path $MyInvocation.MyCommand.Path -Parent

# ============================================
# Authenticate Azure CLI
# ============================================
az login --tenant $tenantId

$subscriptionId = az account list `
    --all `
    --query "[?name=='$subscriptionName'].id" `
    --output tsv

# ============================================
# Start Timer
# ============================================
$processTimerStart = [System.Diagnostics.Stopwatch]::StartNew()

# ============================================
# Deploy Bicep Template
# ============================================
Write-Host "Deploying Bicep Template..." -ForegroundColor Green
$bicepDeployment = az deployment sub create `
    --subscription $subscriptionName `
    --location $location `
    --template-file $templateFile `
    --parameters $parametersFile |
    ConvertFrom-Json

# ============================================
# Extract Bicep Outputs
# ============================================
$resourceGroupName      = $bicepDeployment.properties.outputs.rgName.value
$keyVaultName           = $bicepDeployment.properties.outputs.keyVaultName.value
$dataFactoryName        = $bicepDeployment.properties.outputs.dataFactoryName.value
$sqlServerName          = $bicepDeployment.properties.outputs.sqlServerName.value
$sqlDatabaseName        = $bicepDeployment.properties.outputs.sqlDatabaseName.value
$sampleSqlDatabaseName  = $bicepDeployment.properties.outputs.sampleSqlDatabaseName.value

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
    -sampleSqlServerName $sqlServerName `
    -sampleSqlDatabaseName $sampleSqlDatabaseName `
    -resourceGroupName $resourceGroupName `
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
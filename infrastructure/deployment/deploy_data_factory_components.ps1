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
    
    [Parameter(Mandatory = $true)]
    [string] $resourceGroupName,
    
    [Parameter(Mandatory = $true)]
    [string] $dataFactoryName
)

# ============================================
# Import Required Modules
# ============================================
Import-Module -Name "Az.DataFactory"
Import-Module -Name "azure.datafactory.tools"   # https://github.com/Azure-Player/azure.datafactory.tools/

# ============================================
# Resolve ADF Source Folder
# ============================================
$repoRoot     = (Get-Location).Path -replace 'infrastructure\\deployment', ''
$scriptPath   = Join-Path $repoRoot "src\azure.datafactory"

# ============================================
# Configure Publish Options
# ============================================
$options = New-AdfPublishOption
$options.CreateNewInstance = $false      # Not a fresh workspace deployment
$options.Excludes.Add("trigger.*", "")   # Exclude triggers
$options.Excludes.Add("factory.*", "")   # Exclude factory definition

# ============================================
# Set Azure Context
# ============================================
Set-AzContext -Subscription $subscriptionName

# ============================================
# Publish ADF from JSON Files
# ============================================
Publish-AdfV2FromJson `
    -RootFolder        $scriptPath `
    -ResourceGroupName $resourceGroupName `
    -DataFactoryName   $dataFactoryName `
    -Location          $location `
    -Option            $options `
    -Stage             "install"

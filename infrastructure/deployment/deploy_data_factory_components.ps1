#Assigining the parameters for the environment
param(
    [Parameter(Mandatory=$true)]
    [string] $tenantId,

    [Parameter(Mandatory=$true)]
    [string] $location,
    
    [Parameter(Mandatory=$true)]
    [string] $resourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string] $dataFactoryName
)
# Modules
# Install-Module -Name "Az"
# Import-Module -Name "Az"

# Install-Module -Name "Az.DataFactory"
Import-Module -Name "Az.DataFactory"

# https://github.com/Azure-Player/azure.datafactory.tools/
# Install-Module -Name azure.datafactory.tools -Scope CurrentUser
Import-Module -Name azure.datafactory.tools

# Get Deployment Objects and Params files
$scriptPath = (Join-Path -Path (Get-Location) -ChildPath "src/azure.datafactory") 
$scriptPath = (Get-Location).Path -replace 'infrastructure\\deployment',''
$scriptPath += "\src\azure.datafactory"

$options = New-AdfPublishOption
$options.CreateNewInstance = $false # New ADF workspace deployment not required.
$options.Excludes.Add("trigger.*","")
$options.Excludes.Add("factory.*","")


Publish-AdfV2FromJson -RootFolder "$scriptPath" -ResourceGroupName "$resourceGroupName" -DataFactoryName "$dataFactoryName" -Location "$location" -Option $options -Stage "install"

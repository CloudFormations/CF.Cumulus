#Assigining the parameters for the environment
param(
    [Parameter(Mandatory=$true)]
    [string] $parametersFile
)

Get-Content -Path infrastructure\configuration\_installation\main.bicepparam


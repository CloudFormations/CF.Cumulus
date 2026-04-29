param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $instanceName,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $databaseName,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $query
)

Import-Module SQLServer
Import-Module Az.Accounts -MinimumVersion 2.2.0

$encryptedToken = (Get-AzAccessToken -ResourceUrl "https://database.windows.net" -AsSecureString).token
$accessToken = [PSCredential]::new("token", $encryptedToken)

$instanceNameFull = "$instanceName.database.windows.net"

Invoke-Sqlcmd -ServerInstance $instanceNameFull `
    -Database $databaseName `
    -AccessToken $accessToken.GetNetworkCredential().Password `
    -Query $query

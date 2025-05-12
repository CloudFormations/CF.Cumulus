param(
    $subscriptionID,

    $instanceName,

    $databaseName,

    $inputFile
)


Import-Module SQLServer
Import-Module Az.Accounts -MinimumVersion 2.2.0

$accessToken = (Get-AzAccessToken -ResourceUrl https://database.windows.net).Token

$instanceNameFull = "$instanceName.database.windows.net"

Invoke-Sqlcmd -ServerInstance $instanceNameFull -Database $databaseName -AccessToken $accessToken -inputFile $inputFile

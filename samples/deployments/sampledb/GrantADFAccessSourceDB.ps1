param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $ADFResource,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $subscriptionID,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $instanceName,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $databaseName
)

Import-Module SQLServer
Import-Module Az.Accounts -MinimumVersion 2.2.0

# Connect-AzAccount -SubscriptionId $subscriptionID

$accessToken = (Get-AzAccessToken -ResourceUrl https://database.windows.net).Token

$instanceNameFull = "$instanceName.database.windows.net"

$query = @"
-- Create User
IF NOT EXISTS (SELECT TOP 1 1 FROM sys.database_principals WHERE type = 'E' AND name = '$ADFResource')
	BEGIN
		EXEC('CREATE USER [$ADFResource] FROM EXTERNAL PROVIDER');
	END

-- Create Role
	IF NOT EXISTS (SELECT TOP 1 1 FROM sys.database_principals WHERE type = 'R' AND name = 'db_cumulususer')
	BEGIN
		CREATE ROLE [db_cumulususer];
	END

-- Grant permissions
GRANT 
	SELECT
ON SCHEMA::[SalesLT] TO [db_cumulususer];

-- Add User to Role
ALTER ROLE [db_cumulususer] 
ADD MEMBER [$ADFResource];
"@

Invoke-Sqlcmd -ServerInstance $instanceNameFull -Database $databaseName -AccessToken $accessToken -Query $query

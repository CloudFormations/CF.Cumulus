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

# Uncomment the below commands for independent executions of the script.
# Import-Module SQLServer
# Import-Module Az.Accounts -MinimumVersion 2.2.0
# Connect-AzAccount -SubscriptionId $subscriptionID

$accessToken = (Get-AzAccessToken -ResourceUrl https://database.windows.net).Token

$instanceNameFull = "$instanceName.database.windows.net"

$query = @"
-- Cumulus Additional Database Data Source Pre-requisites
IF NOT EXISTS (SELECT * FROM sys.sysusers WHERE name = '$ADFResource')
BEGIN
	CREATE USER [$ADFResource] FROM EXTERNAL PROVIDER;
	PRINT 'Created ADF user'
END

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE type = 'R' AND name = 'db_cumulususer')
BEGIN
	CREATE ROLE [db_cumulususer];
	PRINT 'Created db_cumulususer role'
END

GRANT 
	EXECUTE, 
	SELECT,
	CONTROL,
	ALTER
ON SCHEMA::[control] TO [db_cumulususer];
GO

GRANT 
	EXECUTE, 
	SELECT,
	CONTROL,
	ALTER
ON SCHEMA::[ingest] TO [db_cumulususer];
GO

GRANT 
	EXECUTE, 
	SELECT,
	CONTROL,
	ALTER
ON SCHEMA::[transform] TO [db_cumulususer];
GO

ALTER ROLE [db_cumulususer] 
ADD MEMBER [$ADFResource];
"@


Invoke-Sqlcmd -ServerInstance $instanceNameFull -Database $databaseName -AccessToken $accessToken -Query $query

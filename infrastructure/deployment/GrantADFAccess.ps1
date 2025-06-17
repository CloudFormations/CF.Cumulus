param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $dataFactoryName,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $subscriptionIdValue,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $sqlServerName,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $sqlDatabaseName
)

# Uncomment the below commands for independent executions of the script.
Import-Module SQLServer
Import-Module Az.Accounts -MinimumVersion 2.2.0
Connect-AzAccount -SubscriptionId $subscriptionIdValue

$accessToken = (Get-AzAccessToken -ResourceUrl https://database.windows.net).Token

$sqlServerNameFull = "$sqlServerName.database.windows.net"

$query = @"
-- Cumulus Additional Database Data Source Pre-requisites
IF NOT EXISTS (SELECT * FROM sys.sysusers WHERE name = '$dataFactoryName')
BEGIN
	CREATE USER [$dataFactoryName] FROM EXTERNAL PROVIDER;
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
ADD MEMBER [$dataFactoryName];
"@


Invoke-Sqlcmd -ServerInstance $sqlServerNameFull -Database $sqlDatabaseName -AccessToken $accessToken -Query $query

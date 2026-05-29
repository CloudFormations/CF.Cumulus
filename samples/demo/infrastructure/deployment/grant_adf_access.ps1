# ============================================
# Parameters
# ============================================
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $dataFactoryName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $sqlServerName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $sqlDatabaseName
)

# ============================================
# Acquire Access Token for SQL Authentication
# ============================================
$encryptedToken = (Get-AzAccessToken -ResourceUrl "https://database.windows.net" -AsSecureString).token
$accessToken = [PSCredential]::new("token", $encryptedToken)
$sqlServerNameFull = "$sqlServerName.database.windows.net"

# ============================================
# Database Setup Query
# ============================================
$query = @"
-- Cumulus Additional Database Data Source Pre-requisites

IF NOT EXISTS (SELECT * FROM sys.sysusers WHERE name = '$dataFactoryName')
BEGIN
    CREATE USER [$dataFactoryName] FROM EXTERNAL PROVIDER;
    PRINT 'Created ADF user';
END

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE type = 'R' AND name = 'db_cumulususer')
BEGIN
    CREATE ROLE [db_cumulususer];
    PRINT 'Created db_cumulususer role';
END

GRANT 
    EXECUTE,
    SELECT
ON SCHEMA::[SalesLT] TO [db_cumulususer];
GO

ALTER ROLE [db_cumulususer]
ADD MEMBER [$dataFactoryName];
"@

# ============================================
# Execute SQL Commands
# ============================================
Invoke-Sqlcmd `
    -ServerInstance $sqlServerNameFull `
    -Database       $sqlDatabaseName `
    -AccessToken    $accessToken.GetNetworkCredential().Password `
    -Query          $query
param(
    [Parameter(Mandatory=$true)]
    [string] $tenantId,

    [Parameter(Mandatory=$true)]
    [string] $subscriptionIdValue,

    [Parameter(Mandatory=$true)]
    [string] $keyVaultName,

    [Parameter(Mandatory=$true)]
    [string] $sqlServerName,

    [Parameter(Mandatory=$true)]
    [string] $sqlDatabaseName,

    [Parameter(Mandatory=$true)]
    [string] $databricksWorkspaceName,

    [Parameter(Mandatory=$true)]
    [string] $databricksWorkspaceURL,

    [Parameter(Mandatory=$true)]
    [string] $storageAccountName,

    [Parameter(Mandatory=$true)]
    [string] $resourceGroupName,

    [Parameter(Mandatory=$true)]
    [string] $dataFactoryName,

    [Parameter(Mandatory=$true)]
    [string] $sqlUsernameSecret,

    [Parameter(Mandatory=$true)]
    [string] $sqlPasswordSecret
)

$sqlLogin = az keyvault secret show --name $sqlUsernameSecret --vault-name $keyVaultName --query "value"

$sqlPassword = az keyvault secret show --name $sqlPasswordSecret --vault-name $keyVaultName --query "value"

$currentLocation = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
$sourceFolderPath = $currentLocation -replace '\\infrastructure\\deployment'

SqlPackage /Action:Publish /SourceFile:"$sourceFolderPath\src\metadata.common\metadata.common.dacpac" /TargetConnectionString:"Server=tcp:$sqlServerName.database.windows.net,1433;Initial Catalog=$sqlDatabaseName;Persist Security Info=False;User ID=$sqlLogin;Password=$sqlPassword;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;" /v:DatabricksWSName=$databricksWorkspaceName /v:DatabricksHost="https://$databricksWorkspaceURL" /v:DLSName=$storageAccountName  /v:Environment="Dev"  /v:KeyVaultName=$keyVaultName  /v:RGName=$resourceGroupName /v:SubscriptionID=$subscriptionIdValue 
SqlPackage /Action:Publish /SourceFile:"$sourceFolderPath\src\metadata.control\metadata.control.dacpac" /TargetConnectionString:"Server=tcp:$sqlServerName.database.windows.net,1433;Initial Catalog=$sqlDatabaseName;Persist Security Info=False;User ID=$sqlLogin;Password=$sqlPassword;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;" /v:Environment="Dev"  /v:RGName=$resourceGroupName /v:SubscriptionID=$subscriptionIdValue /v:ADFName=$dataFactoryName /v:TenantID=$tenantId
SqlPackage /Action:Publish /SourceFile:"$sourceFolderPath\src\metadata.ingest\metadata.ingest.dacpac" /TargetConnectionString:"Server=tcp:$sqlServerName.database.windows.net,1433;Initial Catalog=$sqlDatabaseName;Persist Security Info=False;User ID=$sqlLogin;Password=$sqlPassword;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;" 
SqlPackage /Action:Publish /SourceFile:"$sourceFolderPath\src\metadata.transform\metadata.transform.dacpac" /TargetConnectionString:"Server=tcp:$sqlServerName.database.windows.net,1433;Initial Catalog=$sqlDatabaseName;Persist Security Info=False;User ID=$sqlLogin;Password=$sqlPassword;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;" 


$createADFUserScript = $currentLocation + '\GrantADFAccess.ps1'
& $createADFUserScript `
    -subscriptionIdValue $subscriptionIdValue `
    -sqlServerName $sqlServerName `
    -sqlDatabaseName $sqlDatabaseName `
    -dataFactoryName $dataFactoryName

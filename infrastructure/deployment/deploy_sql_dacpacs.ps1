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

    [Parameter(Mandatory=$false)]
    [string] $sqlUsernameSecret = $sqlServerName + '-adminusername',

    [Parameter(Mandatory=$false)]
    [string] $sqlValueSecret = $sqlServerName + '-adminpassword'

)


# Get SQL User and Password from Key Vault to deploy DacPacs
$sqlLogin = az keyvault secret show --name $sqlUsernameSecret --vault-name $keyVaultName --query "value"

$sqlPassword = az keyvault secret show --name $sqlValueSecret --vault-name $keyVaultName --query "value"

$currentLocation = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
$sourceFolderPath = $currentLocation -replace '\\infrastructure\\deployment'

# Publish the common schema DacPac
SqlPackage /Action:Publish /SourceFile:"$sourceFolderPath\src\metadata.common\metadata.common.dacpac" /TargetConnectionString:"Server=tcp:$sqlServerName.database.windows.net,1433;Initial Catalog=$sqlDatabaseName;Persist Security Info=False;User ID=$sqlLogin;Password=$sqlPassword;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;" /v:DatabricksWSName=$databricksWorkspaceName /v:DatabricksHost="https://$databricksWorkspaceURL" /v:DLSName=$storageAccountName  /v:Environment="Dev"  /v:KeyVaultName=$keyVaultName  /v:RGName=$resourceGroupName /v:SubscriptionID=$subscriptionIdValue 

# Publish the control schema DacPac
SqlPackage /Action:Publish /SourceFile:"$sourceFolderPath\src\metadata.control\metadata.control.dacpac" /TargetConnectionString:"Server=tcp:$sqlServerName.database.windows.net,1433;Initial Catalog=$sqlDatabaseName;Persist Security Info=False;User ID=$sqlLogin;Password=$sqlPassword;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;" /v:Environment="Dev"  /v:RGName=$resourceGroupName /v:SubscriptionID=$subscriptionIdValue /v:ADFName=$dataFactoryName /v:TenantID=$tenantId

# Publish the ingest schema DacPac
SqlPackage /Action:Publish /SourceFile:"$sourceFolderPath\src\metadata.ingest\metadata.ingest.dacpac" /TargetConnectionString:"Server=tcp:$sqlServerName.database.windows.net,1433;Initial Catalog=$sqlDatabaseName;Persist Security Info=False;User ID=$sqlLogin;Password=$sqlPassword;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;" 

# Publish the transform schema DacPac
SqlPackage /Action:Publish /SourceFile:"$sourceFolderPath\src\metadata.transform\metadata.transform.dacpac" /TargetConnectionString:"Server=tcp:$sqlServerName.database.windows.net,1433;Initial Catalog=$sqlDatabaseName;Persist Security Info=False;User ID=$sqlLogin;Password=$sqlPassword;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;" 


# Set Entra AD admin to myself for this:
$userDetails = az ad signed-in-user show --query userPrincipalName --output tsv
$userId = az ad signed-in-user show --query id --output tsv
az sql server ad-admin create --resource-group $resourceGroupName --server $sqlServerName --display-name $userDetails --object-id $userId

# Create permissions for ADF on the SQL Instance, including a user, role and assigment of user to the role
$createADFUserScript = $currentLocation + '\grant_adf_access.ps1'
& $createADFUserScript `
    -subscriptionIdValue $subscriptionIdValue `
    -sqlServerName $sqlServerName `
    -sqlDatabaseName $sqlDatabaseName `
    -dataFactoryName $dataFactoryName

$sqlPassword = $null


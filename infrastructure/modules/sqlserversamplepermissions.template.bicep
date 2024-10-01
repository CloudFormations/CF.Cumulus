param location string = resourceGroup().location


param namePrefix string 
param nameSuffix string 

param databaseName string

var subscriptionId = subscription().subscriptionId
var name = '${namePrefix}sqldb2${nameSuffix}'




// resource sqlServer 'Microsoft.Sql/servers@2023-05-01-preview' existing = {
//   name: name
// }
// // Create database resources
// resource database 'Microsoft.Sql/servers/databases@2023-05-01-preview' existing = {
//   name: '${databaseName}-db'
// }

// depends on ADF and SQL DB deployments
resource deploymentScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'Create ADF access to DB'
  location: location
  kind: 'AzurePowerShell'
  properties: {
    azPowerShellVersion: '9.0'
    retentionInterval: 'P1D'
    scriptContent: '''
      Import-Module SQLServer
      Import-Module Az.Accounts -MinimumVersion 2.2.0

      $subscriptionID = '1b2b1db2-3735-4a51-86a5-18fa41b8bb49'
      #Connect-AzAccount -SubscriptionId $subscriptionID

      az account show --query user.name --output tsv

      $accessToken = (Get-AzAccessToken -ResourceUrl https://database.windows.net).Token

      $instanceName = 'cfcinternaldevsqldb2uks02.database.windows.net'
      $databaseName = 'dummy-db'
      $query = 'create user [cfcinternaldevfactoryuks02] from external provider;'
      $query2 = 'CREATE SCHEMA [control] AUTHORIZATION [dbo];'
      $query3 = 'CREATE SCHEMA [ingest] AUTHORIZATION [dbo];'
      $query4 = 'CREATE SCHEMA [transform] AUTHORIZATION [dbo];'
      $query5 = '

      CREATE ROLE [db_cumulususer];
      GO


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
      ADD MEMBER [cfcinternaldevfactoryuks02];

      '

      # Invoke-Sqlcmd -ServerInstance $instanceName -Database $databaseName -AccessToken $accessToken -Query $query
      Invoke-Sqlcmd -ServerInstance $instanceName -Database $databaseName -AccessToken $accessToken -Query $query2
      Invoke-Sqlcmd -ServerInstance $instanceName -Database $databaseName -AccessToken $accessToken -Query $query3
      Invoke-Sqlcmd -ServerInstance $instanceName -Database $databaseName -AccessToken $accessToken -Query $query4
      Invoke-Sqlcmd -ServerInstance $instanceName -Database $databaseName -AccessToken $accessToken -Query $query5
    '''
  }
}

resource deploymentScriptStored 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'create-spn-for-kv'
  location: location
  kind: 'AzurePowerShell'
  properties: {
    azPowerShellVersion: '9.0'
    retentionInterval: 'P1D'
    primaryScriptUri: 'https://<storage-account-name>.blob.core.windows.net/<container-name>/<script-name>.ps1'
    arguments: '-SubscriptionId ${subscriptionId} -InstanceName ${name}.database.windows.net -DatabaseName ${databaseName}'
  }
}

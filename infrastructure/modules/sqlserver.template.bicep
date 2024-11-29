param location string = resourceGroup().location

param namePrefix string 
param nameSuffix string 

param databaseName string

param randomGuid string = newGuid()

var servername = '${namePrefix}sql${nameSuffix}'

var specialChars = '!@#$%^&*' // Special characters to be used in the password
var sqlPassword = '${take(randomGuid, 16)}${take(specialChars, 2)}1A'

// Create the SQL Server
resource sqlServer 'Microsoft.Sql/servers@2023-05-01-preview' = {
  name: servername
  location: location
  properties: {
    administratorLogin: 'sqladmin'
    administratorLoginPassword: sqlPassword
    version: '12.0'
    publicNetworkAccess: 'Enabled'
    primaryUserAssignedIdentityId: null
  }
}

var keyVaultName = '${namePrefix}kv${nameSuffix}'

// Validate Key Vault exists 
resource sqlServerVault 'Microsoft.KeyVault/vaults@2024-04-01-preview' existing = {
  name: keyVaultName
}

// Generate a random password for the SQL Server and put it in the Key Vault
module sqlServerkeyVault 'secret.template.bicep' = if (sqlServerVault.name != null) {
  name: '${sqlServer.name}-kv-secrets'
  scope: resourceGroup()
  params: {
    keyVaultName: sqlServerVault.name
    secrets: [
      {
        name: '${sqlServer.name}-adminusername'
        value: 'sqladmin'
      }
      {
        name: '${sqlServer.name}-adminpassword'
        value: sqlPassword
      }
    ]
  }
}

// Create database
resource rDatabase 'Microsoft.Sql/servers/databases@2023-05-01-preview' = {
  name: databaseName
  parent: sqlServer
  location: location
  properties: {

    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 2147483648

  }
  sku: {
    name: 'Basic'
    tier: 'Basic'
    capacity: 5
  }
}

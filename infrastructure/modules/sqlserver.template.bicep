@description('Resource group location.')
param location string = resourceGroup().location

@description('SQL Server Logical Instance name.')
param sqlServerName string

@description('SQL Server Database name.')
param sqlDatabaseName string

@description('Key Vault name.')
param keyVaultName string

@description('Log Analytics Workspace name.')
param logAnalyticsWorkspaceName string


@description('Add firewall rule for user\'s local IP Address.')
@secure()
param myIPAddress string = ''

@description('Add firewall rule for Azure Resources.')
param allowAzureServices bool = false // For allowing Azure services access to Azure SQL Server


@description('Random GUID used to create a SQL Server admin password.')
param randomGuid string = newGuid()


var specialChars = '!@#$%^&*' // Special characters to be used in the password
var sqlPassword = '${take(randomGuid, 16)}${take(specialChars, 2)}1A'

// Create the SQL Server
resource sqlServer 'Microsoft.Sql/servers@2023-05-01-preview' = {
  name: sqlServerName
  location: location
  properties: {
    administratorLogin: 'sqladmin'
    administratorLoginPassword: sqlPassword
    version: '12.0'
    publicNetworkAccess: 'Enabled'
    primaryUserAssignedIdentityId: null
  }
}

// Define a firewall rule to allow your IP address
resource myIpFirewallRule 'Microsoft.Sql/servers/firewallRules@2024-05-01-preview' = if (myIPAddress != '') {
  name: 'AllowMyIP'
  parent: sqlServer
  properties: {
    startIpAddress: myIPAddress
    endIpAddress: myIPAddress
  }
}

// Define a firewall rule to allow Azure Resources Access
resource allowAzureResourcesFirewallRule 'Microsoft.Sql/servers/firewallRules@2024-05-01-preview' = if (allowAzureServices) {
  name: 'AllowAzureResources'
  parent: sqlServer
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}



// Validate Key Vault exists 
resource sqlServerVault 'Microsoft.KeyVault/vaults@2024-04-01-preview' existing = {
  name: keyVaultName
}

// Generate a random password for the SQL Server and store in the Key Vault
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
resource database 'Microsoft.Sql/servers/databases@2023-05-01-preview' = {
  name: sqlDatabaseName
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

// Get existing Log Analytics Resource for Id value
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {  
  name: logAnalyticsWorkspaceName
}

// Enable Diagnostic Settings to send logs to Log Analytics
resource sqlServerDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'sqlServerDiagnostics'
  scope: database
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        category: 'SQLSecurityAuditEvents'
        enabled: true
      }
      {
        category: 'SQLInsights'
        enabled: true
      }
      {
        category: 'Errors'
        enabled: true
      }
      {
        category: 'Timeouts'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

// Output key properties for reference by other resources
output sqlServerName string = sqlServerName
output databaseName string = sqlDatabaseName

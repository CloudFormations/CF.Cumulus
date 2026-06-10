@description('Resource group location.')
param location string = resourceGroup().location

@description('SQL Server Logical Instance name.')
param sqlServerName string

@description('SQL Server Database name.')
param sqlDatabaseName string

@description('Add firewall rule for user\'s local IP Address.')
@secure()
param myIPAddress string = ''

@description('Add firewall rule for Azure Resources.')
param allowAzureServices bool = false // For allowing Azure services access to Azure SQL Server

// Validate the SQL Server
resource sqlServer 'Microsoft.Sql/servers@2023-05-01-preview' existing =  {
  name: sqlServerName
}

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


// Create database
resource database 'Microsoft.Sql/servers/databases@2023-05-01-preview' = {
  name: sqlDatabaseName
  parent: sqlServer
  location: location
  properties: {

    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 2147483648
    sampleName: 'AdventureWorksLT'

  }
  sku: {
    name: 'Basic'
    tier: 'Basic'
    capacity: 5
  }
}

output sqlServerName string = sqlServerName
output databaseName string = sqlDatabaseName

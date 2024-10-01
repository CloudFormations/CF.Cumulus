param location string = resourceGroup().location

param namePrefix string 
param nameSuffix string 

param databaseName string

param randomGuid string = newGuid()

@secure()
param adminSid string
@secure()
param adminName string

param useFirewall bool = false
param startIP string = ''
param endIP string = ''

var name = '${namePrefix}sqldb2${nameSuffix}'

var specialChars = '!@#$%^&*' // Special characters to be used in the password
var sqlPassword = '${take(randomGuid, 16)}${take(specialChars, 2)}1A'



resource sqlServer 'Microsoft.Sql/servers@2023-05-01-preview' = {
  name: name
  location: location
  properties: {
    administrators: {
      azureADOnlyAuthentication: true
      administratorType: 'ActiveDirectory'
      principalType: 'User'
      sid: adminSid
      login: adminName
    }
    restrictOutboundNetworkAccess: 'Disabled'
    minimalTlsVersion: '1.2'
    version: '12.0'
    publicNetworkAccess: 'Enabled'
    primaryUserAssignedIdentityId: null
  }
  identity: {
    type: 'SystemAssigned'
  }
  
}

resource firewall 'Microsoft.Sql/servers/firewallRules@2023-08-01-preview' = if (useFirewall) {
  name: 'MyFirewallRule'
  parent: sqlServer
  properties: {
    startIpAddress: startIP
    endIpAddress: endIP
  }

}




// Create database resources
resource rDatabase 'Microsoft.Sql/servers/databases@2023-05-01-preview' = {
  name: '${databaseName}-db'
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


targetScope = 'subscription'

param location string = 'uksouth'
param envName string
param domainName string = 'cfc'
param orgName string = 'internal'
param uniqueIdentifier string = '02'
param nameStorage string = 'dls'

param functionStorageName string = 'fst'

param deploymentTimestamp string = utcNow('yy-MM-dd-HHmm')

param firstDeployment bool = false

var locationShortCodes = {
  uksouth: 'uks'
  ukwest: 'ukw'
  eastus: 'eus'
}

var locationShortCode = locationShortCodes[location]

var namePrefix = '${domainName}${orgName}${envName}'
var nameSuffix = '${locationShortCode}${uniqueIdentifier}'
var rgName = '${namePrefix}rg${nameSuffix}'

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: rgName
  location: location
}

module sqlServerDeploy 'modules/sqlserversample.template.bicep' = {
  scope: rg
  name: 'sql-server${deploymentTimestamp}'
  params: {
    adminName: 'matthew.collins@cloudformations.org'
    adminSid: 'ec9f7400-e769-4198-b9d4-cb556962b397'
    databaseName: 'dummy'
    namePrefix: namePrefix
    nameSuffix: nameSuffix
    useFirewall: true
    startIP: '90.211.72.84'
    endIP:'90.211.72.84'
    location: location
    }
}

// permissions deploy TODO
module sqlServerPermissionsDeploy 'modules/sqlserversample.template.bicep' = {
  scope: rg
  name: 'sql-server${deploymentTimestamp}'
  params: {
    adminName: 'matthew.collins@cloudformations.org'
    adminSid: 'ec9f7400-e769-4198-b9d4-cb556962b397'
    databaseName: 'dummy'
    namePrefix: namePrefix
    nameSuffix: nameSuffix
    useFirewall: true
    startIP: '90.211.72.84'
    endIP:'90.211.72.84'
    location: location
    }
}

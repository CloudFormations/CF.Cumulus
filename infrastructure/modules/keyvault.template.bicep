param location string = resourceGroup().location

param tenantId string = subscription().tenantId

param namePrefix string 
param nameSuffix string 

// param envName string = 'dev'

param keyVaultExists bool


var name = '${namePrefix}kv${nameSuffix}'

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' = if (!keyVaultExists) {
  name: name
  location: location
  properties:{
    enableRbacAuthorization: true
    sku: {
      name: 'premium'
      family: 'A'
    }
    tenantId: tenantId
    accessPolicies: []
  }
}

output location string = location
output name string = kv.name
output resourceGroupName string = resourceGroup().name
output keyVaultId string = kv.id
output keyVaultURI string = kv.properties.vaultUri

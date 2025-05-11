@description('Key Vault Name for the Key Vault to be created')
param keyVaultName string

@description('Array of secrets to be created in the Key Vault')
param secrets array


resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: keyVaultName
}

resource keyVaultSecrets 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = [for secret in secrets: {
  name: secret.name
  parent: keyVault
  properties: {
    value: secret.value
  }
}]


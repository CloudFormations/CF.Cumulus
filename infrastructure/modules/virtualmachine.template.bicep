param location string = resourceGroup().location
param envName string
param namePrefix string 
param nameSuffix string 
param vmPurpose string = 'SHIR' // < 5 chars long

@secure()
param adminUsername string
param randomGuid string = newGuid()

var vmName = '${vmPurpose}${envName}vm${nameSuffix}' // 15 character limit
var nicName = '${namePrefix}nic${nameSuffix}'
var vnetName = '${namePrefix}vnet${nameSuffix}'
var subnetName = '${namePrefix}subnet${nameSuffix}'
var ipName = '${namePrefix}ip${nameSuffix}'

var keyVaultName = '${namePrefix}kv${nameSuffix}'

var specialChars = '!@#$%^&*' // Special characters to be used in the password
var adminPassword = '${take(randomGuid, 16)}${take(specialChars, 2)}1A'

// Validate Key Vault exists 
resource keyVault 'Microsoft.KeyVault/vaults@2024-04-01-preview' existing = {
  name: keyVaultName
}



resource publicIP 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: ipName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: ['10.0.0.0/16']
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '10.0.0.0/24'
        }
      }
    ]
  }
}

resource networkInterface 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: virtualNetwork.properties.subnets[0].id
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIP.id
          }
        }
      }
    ]
  }
}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2024-03-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_DS1_v2'
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-Datacenter'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
        }
      ]
    }
  }
}

// Generate a random password for the SQL Server and put it in the Key Vault
module vmKeyVault 'secret.template.bicep' = if (keyVault.name != null) {
  name: '${virtualMachine.name}-kv-secrets'
  scope: resourceGroup()
  params: {
    keyVaultName: keyVault.name
    secrets: [
      {
        name: '${virtualMachine.name}-adminusername'
        value: adminUsername
      }
      {
        name: '${virtualMachine.name}-adminpassword'
        value: adminPassword
      }
    ]
  }
}


output virtualMachineId string = virtualMachine.id

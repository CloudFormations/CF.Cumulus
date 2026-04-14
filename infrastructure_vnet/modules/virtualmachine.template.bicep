@description('Deployment location')
param location string = resourceGroup().location

@description('Environment name')
param envName string = 'dev'

@description('Virtual machine name')
param vmName string = 'cfmattdevxuks01'

@description('Local admin username for the VM')
param adminUsername string = 'shiradmin'

@description('Existing VNet name')
param vnetName string = 'cfmattdevvnetuks01'

@description('Existing subnet name')
param subnetName string = 'mattnwk-dev-pep-01'

@description('Existing Network Security Group name')
param nsgName string = 'cfmattdevvmnsguks01'

@description('NIC name')
param nicName string = 'cfmattdevvmnicuks01'

@description('Existing Key Vault name')
param keyVaultName string = 'cfmattdevkvuks01'

@description('Virtual Machine Size')
param vmSize string = 'Standard_DS1_v2'
var osDiskSizeGB = 128

// Password generation
@secure()
param randomGuid string= newGuid()
var specialChars = '!@#$%^&*'
var adminPassword = '${take(randomGuid, 16)}${take(specialChars, 2)}1A'

// ---------- EXISTING RESOURCES ----------

resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' existing = {
  name: vnetName
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' existing = {
  parent: vnet
  name: subnetName
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-11-01' existing = {
  name: nsgName
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

// ---------- KEY VAULT SECRETS ----------

resource kvAdminUser 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: '${keyVault.name}/vm-${vmName}-admin-username'
  properties: {
    value: adminUsername
  }
}

resource kvAdminPassword 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: '${keyVault.name}/vm-${vmName}-admin-password'
  properties: {
    value: adminPassword
  }
}

// ---------- NETWORK INTERFACE ----------

resource nic 'Microsoft.Network/networkInterfaces@2023-11-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnet.id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: nsg.id
    }
  }
}

// ---------- VIRTUAL MACHINE ----------

resource vm 'Microsoft.Compute/virtualMachines@2024-03-01' = {
  name: vmName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: true
        provisionVMAgent: true
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-Datacenter'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
        diskSizeGB: osDiskSizeGB
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}

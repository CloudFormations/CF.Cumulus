@description('Resource group location.')
param location string = resourceGroup().location

@description('Resource group containing the Function App')
param resourceGroupName string

// Construct resource names using prefix and suffix
@description('Function App Name.')
param functionAppName string

// Create the Function App with isolated .NET runtime
resource existingFunctionApp 'Microsoft.Web/sites@2024-11-01' existing =  {
  name: functionAppName
  scope: resourceGroup(resourceGroupName)
}

// Create the Function App with isolated .NET runtime
resource functionApp 'Microsoft.Web/sites@2024-11-01' =  {
  name: functionAppName
  location: existingFunctionApp.location
  kind: existingFunctionApp.kind
  properties: {
    publicNetworkAccess: 'Disabled'
  }
}

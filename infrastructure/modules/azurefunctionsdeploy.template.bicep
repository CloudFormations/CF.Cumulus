@description('Resource group location.')
param location string = resourceGroup().location

@description('Resource name prefix as per template naming concatenated in the main file.')
@minLength(3) // "logAnalyticsWorkspaceName" within the resource has a min length of 4. Adding this decorator constraint removes the warning.
param namePrefix string 

@description('Resource name suffix as per template naming concatenated in the main file.')
param nameSuffix string 


var resourceGroupName = '${namePrefix}rg${nameSuffix}'
var functionAppName = '${namePrefix}func${nameSuffix}'

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  name: 'matt-managed-identity'
  location: location
}

// resource deploymentScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
//   name: 'deploy-azure-functions'
//   location: location
//   kind: 'AzurePowerShell'
//   identity: {
//     type: 'UserAssigned'
//     userAssignedIdentities: {
//       '${managedIdentity.id}' : {}
//     }
//   }
//   properties: {
//     azPowerShellVersion: '9.0'
//     retentionInterval: 'PT1H'
//     arguments: '-resourceGroupName ${resourceGroupName} -functionAppName ${functionAppName}'
//     scriptContent: '''
//       param(
//       [string] $resourceGroupName,
//       [string] $functionAppName
//       )

//       # Ensure .NET SDK is installed before using dotnet commands
//       if (-Not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
//         Write-Output "Installing .NET SDK..."
//         Invoke-WebRequest -Uri "https://dotnet.microsoft.com/en-us/download/dotnet/8.0" -OutFile "dotnet-installer.exe"
// Start-Process -FilePath ".\dotnet-installer.exe" -ArgumentList "/quiet" -Wait
//       }
      
//       # Validate .NET installation
//       dotnet --version

//       # Clean the project
//       dotnet clean src/azure.functionapp --configuration Release /property:GenerateFullPaths=true /consoleloggerparameters:NoSummary

//       # Publish the function app
//       dotnet publish ./src/azure.functionapp --configuration Release --output ./publishFunctions

//       # Compress the function app into a zip file
//       Compress-Archive -Path ./publishFunctions/* -DestinationPath ./funcapp.zip -Update

//       # Deploy the zip package to Azure Function App
//       az functionapp deployment source config-zip --resource-group $resourceGroupName --name $functionAppName --src ./funcapp.zip
//     '''
//     cleanupPreference: 'Always'
//   }
// }

resource deploymentScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'install-dotnet'
  location: location
  kind: 'AzurePowerShell'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}' : {}
    }
  }
  properties: {
    azPowerShellVersion: '9.0'
    retentionInterval: 'PT1H'
    scriptContent: '''
      Write-Output "Downloading .NET installer..."
      
      # Download .NET SDK installer
      Invoke-WebRequest -Uri "https://download.visualstudio.microsoft.com/download/pr/dotnet-sdk-8.0.4-win-x64.exe" -OutFile "dotnet-installer.exe"
      
      # Install .NET silently
      Write-Output "Installing .NET SDK..."
      Start-Process -FilePath ".\dotnet-installer.exe" -ArgumentList "/quiet" -Wait

      # Verify installation
      Write-Output "Checking .NET version..."
      dotnet --version
    '''
    cleanupPreference: 'Always'
  }
}

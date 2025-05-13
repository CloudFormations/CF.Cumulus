#Assigining the parameters for the environment
param(
    [Parameter(Mandatory=$true)]
    [string] $currentLocation,
    
    [Parameter(Mandatory=$true)]
    [string] $resourceGroupName,

    [Parameter(Mandatory=$true)]
    [string] $functionAppName
)

# This command cleans the build output of the specified project using the Release configuration.
# Generates full paths in the output, and suppresses the summary in the console logger
$sourceFolderPath = $currentLocation -replace '\\infrastructure\\deployment'
$functionAppPath = $sourceFolderPath + '\src\azure.functionapp'
dotnet clean $functionAppPath --configuration Release /property:GenerateFullPaths=true /consoleloggerparameters:NoSummary

# Package the function app including the functions into a folder for deployment
$publishPath = $currentLocation + '\publishFunctions'
dotnet publish $functionAppPath --configuration Release --output $publishPath

# Compressing the publish folder into a zip file
$sourcePath = $publishPath + '/*'
Compress-Archive -Path $sourcePath -DestinationPath ./funcapp.zip -Update

# Deploying the zip to the functionapp
az functionapp deployment source config-zip --resource-group $resourceGroupName --name $functionAppName --src ./funcapp.zip

# Add Function App Key to Azure Key Vault secrets with the name cumulusfunctionsKey
$functionAppKeys = az functionapp keys list -g $resourceGroupName -n $functionAppName | ConvertFrom-Json 
$functionAppMasterKey = $functionAppKeys.masterKey
az keyvault secret set --vault-name $keyVaultName --name "cumulusfunctionsKey" --value $functionAppMasterKey
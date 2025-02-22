param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $subscriptionID,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $tenantID,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $resourceGroup, 

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $factoryDataFactory,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $workersDataFactory,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $directoryPath,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $databricksWorkspaceURL,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $databricksClusterId,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $databricksWorkspaceName
)

$scriptRoot = (Resolve-Path -Path ".\").Path

$directory = $directoryPath
Write-Output $directory
$targetDirectory = Join-Path -Path $scriptRoot -ChildPath "\ExecutableCopies"
Write-Output $targetDirectory

if (Test-Path -Path $targetDirectory -PathType Container) {
    Remove-Item -Path $targetDirectory -Recurse -Force
    Write-Output "Directory '$targetDirectory' has been removed."
} else {
    Write-Output "Directory '$targetDirectory' does not exist."
}

$files = Get-ChildItem $directory
New-Item -Path $targetDirectory -ItemType Directory

# Define your placeholder and replacement values
$replacements = @{
    "CF.Cumulus.Samples" = $resourceGroup
    "subscriptionID-12345678-1234-1234-1234-012345678910" = $subscriptionID
    "tenantID-12345678-1234-1234-1234-012345678910" = $tenantID
    "FrameworkDataFactory" = $factoryDataFactory
    "WorkersDataFactory" = $workersDataFactory
    "https://adb-XXX.azuredatabricks.net" = $databricksWorkspaceURL
    "databrickscomputeguid" = $databricksClusterId
    "databricksworkspacename" = $databricksWorkspaceName
}

foreach ($f in $files.Name) {

    # Read the content of the file
    $content = Get-Content -Path "$directory\$f"

    # Perform the replacements
    foreach ($placeholder in $replacements.Keys) {
        $content = $content -replace $placeholder, $replacements[$placeholder]
    }

    # Write the updated content to the target file
    Set-Content -Path "$targetDirectory\$f" -Value $content

    Write-Host "Added $targetDirectory\$f to the targetDirectory."

}
Write-Host 'Finished moving files to the targetDirectory.'

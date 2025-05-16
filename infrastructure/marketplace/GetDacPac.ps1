# Copies a file from a URL and writes it to a local file path using PowerShell

$SourceUrl = "https://raw.githubusercontent.com/CloudFormations/CF.Cumulus/refs/heads/develop_marketplace/infrastructure/marketplace/db.dacpac"
$DestinationPath = "E:\Temp\db.dacpac"

Invoke-WebRequest -Uri $SourceUrl -OutFile $DestinationPath
# Copies a file from a URL and writes it to a local file path using PowerShell

$SourceUrl = ""
$DestinationPath = ""

Invoke-WebRequest -Uri $SourceUrl -OutFile $DestinationPath
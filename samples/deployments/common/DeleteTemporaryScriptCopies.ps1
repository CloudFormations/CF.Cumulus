# Assuming the relative path is from the script's directory
$scriptRoot = (Resolve-Path -Path ".\").Path
$targetDirectory = Join-Path -Path $scriptRoot -ChildPath ".\ExecutableCopies"

# Remove folder, add as new cleanup script.
Remove-Item -Path $targetDirectory -Recurse -Force

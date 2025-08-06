# Assigning variables for databricks workspace and deployment artifact paths
$workspacepath = "/Workspace/Shared/Live/files"

$scriptPath = (Join-Path -Path (Get-Location) -ChildPath "src/azure.databricks") 
$scriptPath = (Get-Location).Path -replace 'infrastructure\\deployment',''
$scriptPath += "\src\azure.databricks"
$sourcePath = $scriptPath + '\python\notebooks'

# Recursive function to find all notebooks in the workspace
function Get-ExistingNotebooks {
    param (
        [string]$workspacePath
    )
    $workspacedirectory = databricks workspace list $workspacepath -o json | ConvertFrom-Json
    for ($i = 0; $i -lt $workspacedirectory.Count; $i++) {
        # Check if the object is a notebook or directory
        if ($workspacedirectory[$i].object_type -eq "NOTEBOOK") {
            $notebookPath = ($workspacedirectory[$i].path).Replace("/Workspace/Shared/Live/files", "").Replace("/", "\")
            Write-Output $notebookPath
        } elseif ($workspacedirectory[$i].object_type -eq "DIRECTORY") {
            Get-ExistingNotebooks -workspacePath $workspacedirectory[$i].path
        }
    }
}

# Create variables containing all notebook paths from the workspace and the deployment artifacts
$validPaths = Get-ExistingNotebooks -workspacePath $workspacepath | 
    ForEach-Object { Join-Path -Path $sourcePath -ChildPath $_ }

$folderPaths = Get-ChildItem -Path $sourcePath -Recurse -File |
    Where-Object {
        $_.FullName -notmatch "\\utils\\" -and $_.FullName -notmatch "\\__pycache__\\" -and $_.BaseName -notcontains "__init__" -and $_.BaseName -notmatch "databricks" -and $_.BaseName -notmatch "requirements"} | 
    ForEach-Object {[System.IO.Path]::Combine($_.DirectoryName, $_.BaseName)}

# Check if the workspace contains the notebooks from the deployment artifacts and throw an error if not
$errors = $false
foreach ($path in $folderPaths) {
    if (-not ($validPaths -contains $path)) {
        Write-host "Notebook $path not found in the Databricks workspace." -ForegroundColor Red
        $errors = $true
    }
}

if ($errors) {
    Write-Error "Not all notebooks were found in the Databricks workspace. Please check the deployment."
    exit 1
}
else {
    Write-Host "All notebooks are present in the Databricks workspace." -ForegroundColor Green
}
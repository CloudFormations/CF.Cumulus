Write-Host "Checking dependencies..."
 
# Define checks for both PowerShell modules and CLI tools, including install instructions
$checks = @(
    @{ Name = "az";                         Type = "CLI";    Install = 'winget install -e --id Microsoft.AzureCLI or manually via: https://learn.microsoft.com/cli/azure/install-azure-cli' }
    @{ Name = "databricks";                Type = "CLI";    Install = 'winget install -e --id Databricks.DatabricksCLI   (or)  pip install databricks-cli' }

    @{ Name = "Az";                         Type = "Module"; Install = 'Install-Module -Name Az -Repository PSGallery -Force -AllowClobber' }
    @{ Name = "Az.DataFactory";             Type = "Module"; Install = 'Install-Module -Name Az.DataFactory -Scope CurrentUser' }
    @{ Name = "Az.Accounts";                Type = "Module"; Install = 'Install-Module -Name Az.Accounts -Scope CurrentUser' }
    @{ Name = "azure.datafactory.tools";   Type = "Module"; Install = 'Install-Module -Name azure.datafactory.tools -Repository PSGallery -Force -Scope CurrentUser' }
)

$missing = @()

foreach ($item in $checks) {

    switch ($item.Type) {

        "Module" {
            $found = Get-Module -ListAvailable -Name $item.Name
            if ($found) {
                Write-Host "$($item.Name) module is installed." -ForegroundColor Green
            } else {
                Write-Host "$($item.Name) module is NOT installed." -ForegroundColor Red
                $missing += $item
            }
        }

        "CLI" {
            $found = Get-Command $item.Name -ErrorAction SilentlyContinue
            if ($found) {
                Write-Host "$($item.Name) CLI is installed." -ForegroundColor Green
            } else {
                Write-Host "$($item.Name) CLI is NOT installed." -ForegroundColor Red
                $missing += $item
            }
        }
    }
}

# Final stop condition with detailed remediation
if ($missing.Count -gt 0) {

    Write-Host "`nThe following required components are missing:" -ForegroundColor Yellow

    foreach ($item in $missing) {
        Write-Host " - $($item.Name)" -ForegroundColor Red
        Write-Host "   To install: $($item.Install)" -ForegroundColor Magenta
    }

    throw "Environment validation failed. Install missing components and re-run the script."
}

Write-Host "Done."
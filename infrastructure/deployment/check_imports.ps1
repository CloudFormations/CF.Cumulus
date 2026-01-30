Write-Host "Checking dependencies..."
 
# Define checks for both PowerShell modules and CLI tools, including install instructions
$checks = @(
    # CLI checks
    @{ Name = "winget";                    Type = "CLI";            Install = 'Install App Installer from Microsoft Store (includes winget): https://aka.ms/getwinget' }
    @{ Name = "dotnet";                    Type = "CLI";            Install = 'Install .NET SDK: https://dotnet.microsoft.com/en-us/download' }
    @{ Name = "az";                         Type = "CLI";           Install = 'winget install -e --id Microsoft.AzureCLI or manually via: https://learn.microsoft.com/cli/azure/install-azure-cli' }
    @{ Name = "databricks";                 Type = "CLI";           Install = 'winget install -e --id Databricks.DatabricksCLI   (or)  pip install databricks-cli' }

    # PowerShell Module checks
    @{ Name = "Az";                         Type = "Module";        Install = 'Install-Module -Name Az -Repository PSGallery -Force -AllowClobber' }
    @{ Name = "Az.DataFactory";             Type = "Module";        Install = 'Install-Module -Name Az.DataFactory -Scope CurrentUser' }
    @{ Name = "Az.Accounts";                Type = "Module";        Install = 'Install-Module -Name Az.Accounts -Scope CurrentUser' }
    @{ Name = "azure.datafactory.tools";    Type = "Module";        Install = 'Install-Module -Name azure.datafactory.tools -Repository PSGallery -Force -Scope CurrentUser' }

    # Executable checks
    @{ Name = "SqlPackage";                 Type = "Executable";    Install = 'Download from: https://aka.ms/sqlpackage' }
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

        "Executable" {
            $exeName = if ($item.Name -match '\.exe$') { $item.Name } else { "$($item.Name).exe" }
            $found = Get-Command $exeName -ErrorAction SilentlyContinue

            if ($found) {
                Write-Host "$exeName is installed at: $($found.Source)" -ForegroundColor Green
            } else {
                Write-Host "$exeName is NOT installed or not in PATH." -ForegroundColor Red
                $missing += $item
            }
        }

        Default {
            Write-Host "Unknown item type '$($item.Type)' for '$($item.Name)'. Skipping." -ForegroundColor Yellow
        }
    }
}

# -----------------------------
# Additional .NET SDK validation
# -----------------------------
$dotnet = Get-Command dotnet -ErrorAction SilentlyContinue
if ($dotnet) {
    $sdks = dotnet --list-sdks 2>$null
    if (-not $sdks) {
        Write-Host "dotnet is installed but NO .NET SDKs are available." -ForegroundColor Red
        Write-Host "   Install the SDK from: https://dotnet.microsoft.com/en-us/download" -ForegroundColor Magenta

        $missing += @{
            Name = "dotnet-sdk"
            Type = "SDK"
            Install = "Install .NET SDK: https://dotnet.microsoft.com/en-us/download"
        }
    } else {
        Write-Host ".NET SDK detected: $sdks" -ForegroundColor Green
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
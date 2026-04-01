#Assigining the parameters for the environment
param(
    [Parameter(Mandatory=$false)]
    [string] $parametersFile
)

# Read all lines, ignore comments and 'using' statements
$lines = Get-Content $parametersFile | Where-Object {
    $_ -notmatch '^\s*//' -and $_ -notmatch '^\s*using'
}

# Extract param name and value
$params = foreach ($line in $lines) {
    if ($line -match 'param\s+(\w+)\s*=\s*(.+)') {
        [PSCustomObject]@{
            Name  = $matches[1]
            Value = $matches[2].Trim()
        }
    }
}

# Render as table
$params | Format-Table -AutoSize
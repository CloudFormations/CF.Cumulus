# ============================================
# Parameters
# ============================================
param(
    [Parameter(Mandatory = $false)]
    [string] $parametersFile
)

# ============================================
# Read parameter file and ignore comments / using statements
# ============================================
$lines = Get-Content $parametersFile | Where-Object {
    $_ -notmatch '^\s*//' -and
    $_ -notmatch '^\s*using'
}

# ============================================
# Extract parameter names and values
# ============================================
$params = foreach ($line in $lines) {
    if ($line -match 'param\s+(\w+)\s*=\s*(.+)') {
        [PSCustomObject]@{
            Name  = $matches[1]
            Value = $matches[2].Trim()
        }
    }
}

# ============================================
# Output in table format
# ============================================
$params | Format-Table -AutoSize

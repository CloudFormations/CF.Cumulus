[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string] $SubscriptionId,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $StorageAccountName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string[]] $Containers,

    [Parameter(Mandatory = $false)]
    [ValidateSet("Off","Blob","Container")]
    [string] $PublicAccess = "Off",

    [Parameter(Mandatory = $false)]
    [switch] $DryRun,

    [Parameter(Mandatory = $false)]
    [switch] $FailOnMissingStorageAccount
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Set-SubscriptionContextIfNeeded {
    param([string] $SubscriptionId)

    if (-not [string]::IsNullOrWhiteSpace($SubscriptionId)) {
        # Only set context if the caller provides a subscription id.
        Set-AzContext -Subscription $SubscriptionId | Out-Null
    }
}

function Get-StorageAccountOrNull {
    param(
        [string] $ResourceGroupName,
        [string] $StorageAccountName
    )

    try {
        return Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
    }
    catch {
        return $null
    }
}

function New-StorageContextFromKey {
    param(
        [string] $ResourceGroupName,
        [string] $StorageAccountName
    )

    $keys = Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
    if (-not $keys -or -not $keys[0].Value) {
        throw "Could not retrieve storage account keys for '$StorageAccountName'. Ensure permissions allow key access."
    }

    return New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $keys[0].Value
}

function Ensure-Containers {
    param(
        [Microsoft.Azure.Commands.Common.Authentication.Abstractions.IStorageContext] $Context,
        [string[]] $Containers,
        [string] $PublicAccess,
        [switch] $DryRun
    )

    $results = New-Object System.Collections.Generic.List[object]

    foreach ($c in $Containers) {
        $nameRaw = ($c ?? "").Trim()

        if ([string]::IsNullOrWhiteSpace($nameRaw)) {
            continue
        }

        # Container naming rules require lowercase
        $name = $nameRaw.ToLowerInvariant()

        $result = [PSCustomObject]@{
            Container = $name
            Exists    = $false
            Created   = $false
            Action    = $null
            Success   = $true
            Message   = $null
        }

        try {
            $existing = Get-AzStorageContainer -Context $Context -Name $name -ErrorAction SilentlyContinue
            if ($null -ne $existing) {
                $result.Exists  = $true
                $result.Action  = "None"
                $result.Message = "Container exists."
                $results.Add($result)
                continue
            }

            # Missing
            if ($DryRun) {
                $result.Exists  = $false
                $result.Created = $false
                $result.Action  = "WouldCreate"
                $result.Message = "DryRun: container would be created (PublicAccess=$PublicAccess)."
                $results.Add($result)
                continue
            }

            # Create
            New-AzStorageContainer -Context $Context -Name $name -Permission $PublicAccess | Out-Null

            $result.Exists  = $true
            $result.Created = $true
            $result.Action  = "Created"
            $result.Message = "Container created (PublicAccess=$PublicAccess)."
            $results.Add($result)
        }
        catch {
            $result.Success = $false
            $result.Action  = "Failed"
            $result.Message = $_.Exception.Message
            $results.Add($result)
        }
    }

    return $results
}

# -------------------------
# Main
# -------------------------

Set-SubscriptionContextIfNeeded -SubscriptionId $SubscriptionId

$sa = Get-StorageAccountOrNull -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName

if ($null -eq $sa) {
    $msg = "Storage account '$StorageAccountName' not found in resource group '$ResourceGroupName' (or insufficient permissions)."

    if ($FailOnMissingStorageAccount) {
        throw $msg
    }

    return @([PSCustomObject]@{
        Container = $null
        Exists    = $false
        Created   = $false
        Action    = "Failed"
        Success   = $false
        Message   = $msg
    })
}

# Build storage context (key-based by default)
$ctx = New-StorageContextFromKey -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName

# Ensure containers
Ensure-Containers -Context $ctx -Containers $Containers -PublicAccess $PublicAccess -DryRun:$DryRun
<#
.SYNOPSIS
    Edition Manager module for anywin11.
    Detects current Windows edition, checks embedded OEM keys, and maps target Windows 11 upgrade keys.
#>

$script:GenericUpgradeKeys = @{
    "Pro"           = "VK7JG-NPHTM-C97JM-9MPGT-3V66T"
    "Professional"  = "VK7JG-NPHTM-C97JM-9MPGT-3V66T"
    "Home"          = "YTMG3-N6DKC-DKB77-7M9GH-8HVX7"
    "Core"          = "YTMG3-N6DKC-DKB77-7M9GH-8HVX7"
    "Education"     = "YNMGQ-8RYV3-4PGQ3-C8XTP-7CFBY"
    "Workstation"   = "DXG7C-N36C4-C4HTG-X4T3X-2YV77"
    "Enterprise"    = "XGVPP-NMH47-7TTHJ-W3FW7-8HV2C"
}

function Get-SystemEditionInfo {
    [CmdletBinding()]
    param()

    $cv = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction SilentlyContinue

    # Check BIOS / ACPI MSDM Table
    $biosKey = $null
    $biosDesc = $null
    try {
        $lic = Get-CimInstance -Namespace root/cimv2 -ClassName SoftwareLicensingService -ErrorAction SilentlyContinue
        if ($lic) {
            $biosKey  = $lic.OA3xOriginalProductKey
            $biosDesc = $lic.OA3xOriginalProductKeyDescription
        }
    } catch {}

    $installedEdition = if ($cv.EditionID) { $cv.EditionID } else { "Unknown" }
    $productName      = if ($cv.ProductName) { $cv.ProductName } else { "Windows" }
    $currentBuild     = if ($cv.CurrentBuild) { $cv.CurrentBuild } else { "0" }
    $ubr              = if ($cv.UBR) { $cv.UBR } else { "0" }
    $displayVersion   = if ($cv.DisplayVersion) { $cv.DisplayVersion } else { "" }

    # Detect recommended target edition
    $targetEdition = "Pro"
    if ($installedEdition -match "Core|Home" -and [string]::IsNullOrWhiteSpace($biosKey)) {
        $targetEdition = "Home"
    }

    return [PSCustomObject]@{
        ProductName      = $productName
        DisplayVersion   = $displayVersion
        CurrentBuild     = "$currentBuild.$ubr"
        EditionID        = $installedEdition
        BiosKey          = $biosKey
        BiosKeyType      = $biosDesc
        DefaultTarget    = $targetEdition
        HasEmbeddedKey   = (-not [string]::IsNullOrWhiteSpace($biosKey))
    }
}

function Get-UpgradeProductKey {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$TargetEdition = "Pro",

        [Parameter(Mandatory = $false)]
        [string]$CustomKey = ""
    )

    if (-not [string]::IsNullOrWhiteSpace($CustomKey)) {
        return $CustomKey.Trim()
    }

    if ($script:GenericUpgradeKeys.ContainsKey($TargetEdition)) {
        return $script:GenericUpgradeKeys[$TargetEdition]
    }

    # Default to Pro
    return $script:GenericUpgradeKeys["Pro"]
}

Export-ModuleMember -Function Get-SystemEditionInfo, Get-UpgradeProductKey

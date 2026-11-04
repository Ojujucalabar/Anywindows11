<#
.SYNOPSIS
    anywin11 - Automated Windows 11 Readiness, Health Scan & Upgrade Tool
.DESCRIPTION
    Scans Windows systems for registry corruption, dangling services, and hardware compatibility,
    auto-downloads the official Microsoft Windows 11 ISO, applies necessary bypasses, and
    upgrades any PC to Windows 11 cleanly while preserving all personal files and apps.
.EXAMPLE
    .\anywin11.ps1 -Scan
.EXAMPLE
    .\anywin11.ps1 -Audit
.EXAMPLE
    .\anywin11.ps1 -DownloadOnly
.EXAMPLE
    .\anywin11.ps1 -Upgrade -Edition Pro
.EXAMPLE
    .\anywin11.ps1 -Upgrade -Edition Pro -BypassHardware
#>

[CmdletBinding(DefaultParameterSetName = "Interactive")]
param(
    [Parameter(ParameterSetName = "Scan")]
    [switch]$Scan,

    [Parameter(ParameterSetName = "Fix")]
    [switch]$Fix,

    [Parameter(ParameterSetName = "Audit")]
    [switch]$Audit,

    [Parameter(ParameterSetName = "DownloadOnly")]
    [switch]$DownloadOnly,

    [Parameter(ParameterSetName = "Upgrade")]
    [switch]$Upgrade,

    [Parameter(ParameterSetName = "Upgrade")]
    [ValidateSet("Pro", "Home", "Education", "Workstation", "Enterprise")]
    [string]$Edition = "Pro",

    [Parameter(ParameterSetName = "Upgrade")]
    [string]$IsoPath = "",

    [Parameter(ParameterSetName = "Upgrade")]
    [string]$ProductKey = "",

    [Parameter(ParameterSetName = "Upgrade")]
    [switch]$BypassHardware,

    [Parameter(ParameterSetName = "Upgrade")]
    [switch]$Unattended
)

$ErrorActionPreference = "Continue"
$scriptRoot = $PSScriptRoot
if (-not $scriptRoot) { $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path }

# Import Modules
Get-ChildItem -Path (Join-Path $scriptRoot "modules") -Filter "*.psm1" | ForEach-Object {
    Import-Module -Name $_.FullName -Force
}

function Show-Banner {
    Clear-Host
    Write-Host @"
   ___  _  ____ _____      _____ _  _ _ 
  / _ \| \| \ \ / / \ \    / /_ _| \| / |
 | (_) | .` |\ V /| |\ \/\/ / | || .` | |
  \___/|_|\_| |_| |_| \_/\_/ |___|_|\_|_|
  Automated System Health, Audit & Upgrade Tool
"@ -ForegroundColor Cyan
    Write-Host "  --------------------------------------------------------" -ForegroundColor DarkGray
}

function Show-SystemSummary {
    $sys = Get-SystemEditionInfo
    Write-Host "  [i] Operating System : $($sys.ProductName) ($($sys.EditionID))" -ForegroundColor Gray
    Write-Host "  [i] Build Version    : $($sys.CurrentBuild) ($($sys.DisplayVersion))" -ForegroundColor Gray
    if ($sys.HasEmbeddedKey) {
        Write-Host "  [i] BIOS OEM Key     : $($sys.BiosKeyType)" -ForegroundColor Gray
    }
    Write-Host "  --------------------------------------------------------`n" -ForegroundColor DarkGray
}

function Run-ScanWorkflow {
    Show-Banner
    Write-Host "  === [1/2] REGISTRY & SYSTEM INTEGRITY SCAN ===" -ForegroundColor Yellow
    $diag = Invoke-RegistryScan

    Write-Host "`n  Scan Summary:" -ForegroundColor White
    Write-Host "  - Core Hives Accessible    : $($diag.HivesAccessible) / $($diag.HivesChecked)" -ForegroundColor $(if($diag.HivesAccessible -eq $diag.HivesChecked){'Green'}else{'Yellow'})
    Write-Host "  - Dangling Service Entries : $($diag.DanglingServices.Count)" -ForegroundColor $(if($diag.DanglingServices.Count -eq 0){'Green'}else{'Red'})
    Write-Host "  - Pending Rename Backlog   : $($diag.PendingRenames)" -ForegroundColor Gray
    Write-Host "  - Hive Corruption Events   : $($diag.CorruptionEvents)" -ForegroundColor $(if($diag.CorruptionEvents -eq 0){'Green'}else{'Red'})

    if ($diag.DanglingServices.Count -gt 0) {
        Write-Host "`n  [!] Broken Service Entries Found:" -ForegroundColor Red
        foreach ($s in $diag.DanglingServices) {
            Write-Host "      * $($s.ServiceName) -> $($s.MissingFile)" -ForegroundColor Yellow
        }
        Write-Host "`n  Run 'anywin11 -Fix' to clean up these broken entries." -ForegroundColor Cyan
    } else {
        Write-Host "`n  [+] Registry integrity is clean and healthy." -ForegroundColor Green
    }

    return $diag
}

function Run-AuditWorkflow {
    Show-Banner
    Write-Host "  === [2/2] HARDWARE COMPATIBILITY AUDIT ===" -ForegroundColor Yellow
    $audit = Get-Win11HardwareReadiness

    Write-Host "`n  Hardware Audit Results:" -ForegroundColor White
    Write-Host "  - CPU Processor      : $($audit.CpuName)" -ForegroundColor $(if($audit.CpuPass){'Green'}else{'Yellow'})
    Write-Host "  - CPU Cores/Threads  : $($audit.CpuCores) Cores / $($audit.CpuThreads) Threads" -ForegroundColor Gray
    Write-Host "  - Memory (RAM)       : $($audit.TotalRamGB) GB [Req: >= 4 GB]" -ForegroundColor $(if($audit.RamPass){'Green'}else{'Red'})
    Write-Host "  - System Drive (C:)  : $($audit.FreeDiskGB) GB Free [Req: >= 30 GB]" -ForegroundColor $(if($audit.StoragePass){'Green'}else{'Red'})
    Write-Host "  - TPM Security Chip  : $($audit.TpmVersion)" -ForegroundColor $(if($audit.TpmPass){'Green'}else{'Yellow'})
    Write-Host "  - Secure Boot State  : $(if($audit.SecureBoot){'Enabled'}else{'Disabled/Unchecked'})" -ForegroundColor Gray
    Write-Host "  - Partition Style    : $($audit.PartitionStyle) [Req: GPT/UEFI]" -ForegroundColor $(if($audit.UefiPass){'Green'}else{'Yellow'})

    Write-Host "`n  Compatibility Verdict:" -ForegroundColor White
    if ($audit.FullyCompliant) {
        Write-Host "  [+] PASSED: This system meets all official Windows 11 hardware requirements!" -ForegroundColor Green
    } else {
        Write-Host "  [!] NOTICE: This system requires anywin11 hardware bypasses to upgrade." -ForegroundColor Yellow
        Write-Host "      anywin11 will automatically configure LabConfig & MoSetup bypasses during upgrade." -ForegroundColor Cyan
    }

    return $audit
}

function Run-UpgradeWorkflow {
    param(
        [string]$TargetEdition,
        [string]$IsoFile,
        [string]$CustomKey,
        [switch]$Bypass,
        [switch]$Silent
    )

    Show-Banner
    Write-Host "  === WINDOWS 11 UPGRADE WORKFLOW ===" -ForegroundColor Yellow

    # 1. Resolve Target Key
    $key = Get-UpgradeProductKey -TargetEdition $TargetEdition -CustomKey $CustomKey
    Write-Host "`n  [+] Target Edition : Windows 11 $TargetEdition" -ForegroundColor Green
    Write-Host "  [+] Product Key    : $key" -ForegroundColor Gray

    # 2. Locate or Auto-Download ISO
    $iso = $null
    if (-not [string]::IsNullOrWhiteSpace($IsoFile) -and (Test-Path $IsoFile)) {
        $iso = Get-Item $IsoFile
    } else {
        Write-Host "`n  [*] Checking for existing Windows 11 ISO..." -ForegroundColor Cyan
        $found = Find-Windows11Iso
        if ($found -and $found.Count -gt 0) {
            $iso = $found[0]
            Write-Host "  [+] Found existing ISO: $($iso.FullName) ({0:N2} GB)" -f ($iso.Length / 1GB) -ForegroundColor Green
        }
    }

    # Auto-download ISO if none found locally
    if (-not $iso) {
        Write-Host "`n  [*] No local Windows 11 ISO found." -ForegroundColor Yellow
        Write-Host "  [*] Automatically downloading official Windows 11 ISO directly from Microsoft..." -ForegroundColor Cyan
        $iso = Invoke-Windows11IsoDownload
    }

    if (-not $iso) {
        Write-Host "`n  [X] Error: Could not acquire Windows 11 ISO image." -ForegroundColor Red
        Write-Host "      Please check your internet connection or supply -IsoPath <path>." -ForegroundColor Yellow
        return $false
    }

    # 3. Mount ISO
    $mounted = Mount-WindowsIso -IsoPath $iso.FullName
    if (-not $mounted.SetupExists) {
        Write-Host "  [X] Error: Mounted image does not contain setup.exe" -ForegroundColor Red
        Dismount-WindowsIso -IsoPath $iso.FullName
        return $false
    }

    # 4. Check available WIM editions
    Write-Host "`n  [*] Inspecting WIM Image Editions..." -ForegroundColor Cyan
    $editions = Get-WimImageEditions -DriveLetter $mounted.DriveLetter
    if ($editions) {
        foreach ($ed in $editions) {
            $matchMarker = if ($ed.Name -match $TargetEdition) { " <-- SELECTED" } else { "" }
            Write-Host ("      Index {0,-2}: {1,-28} ({2}){3}" -f $ed.Index, $ed.Name, $ed.EditionID, $matchMarker) -ForegroundColor $(if($matchMarker){'Green'}else{'Gray'})
        }
    }

    # 5. Check bypass requirement
    $audit = Get-Win11HardwareReadiness
    $applyBypass = ($Bypass -or $audit.RequiresBypass)
    if ($applyBypass) {
        Write-Host "`n  [*] Applying automated hardware bypasses for CPU/TPM/RAM/SecureBoot..." -ForegroundColor Cyan
        Set-Win11HardwareBypass
    }

    # 6. Launch Setup
    Start-Windows11Upgrade -DriveLetter $mounted.DriveLetter -ProductKey $key -Unattended:$Silent -BypassChecks:$applyBypass
}

# Execution Router
if ($Scan) {
    Run-ScanWorkflow | Out-Null
} elseif ($Fix) {
    $diag = Run-ScanWorkflow
    if ($diag.DanglingServices.Count -gt 0) {
        Write-Host "`n  [*] Repairing $($diag.DanglingServices.Count) broken service entries..." -ForegroundColor Cyan
        $repaired = Repair-DanglingServices -Services $diag.DanglingServices
        Write-Host "  [+] Repaired: $($repaired.Count) services." -ForegroundColor Green
    } else {
        Write-Host "`n  [+] No broken services to repair." -ForegroundColor Green
    }
} elseif ($Audit) {
    Run-AuditWorkflow | Out-Null
} elseif ($DownloadOnly) {
    Show-Banner
    Invoke-Windows11IsoDownload | Out-Null
} elseif ($Upgrade) {
    Run-UpgradeWorkflow -TargetEdition $Edition -IsoFile $IsoPath -CustomKey $ProductKey -Bypass:$BypassHardware -Silent:$Unattended
} else {
    # Interactive Console Menu
    while ($true) {
        Show-Banner
        Show-SystemSummary

        Write-Host "  Main Menu:" -ForegroundColor White
        Write-Host "  [1] 🚀 1-Click Upgrade (Auto-Download ISO -> Scan -> Bypass -> Install Pro)" -ForegroundColor Green
        Write-Host "  [2] Run Full Health & Compatibility Scan" -ForegroundColor Cyan
        Write-Host "  [3] Fix Broken Registry & Dangling Services" -ForegroundColor Cyan
        Write-Host "  [4] Hardware Compatibility Audit" -ForegroundColor Cyan
        Write-Host "  [5] Download Official Windows 11 ISO Only" -ForegroundColor Yellow
        Write-Host "  [6] Upgrade to Windows 11 Home" -ForegroundColor Green
        Write-Host "  [7] Apply Hardware Bypasses Only" -ForegroundColor Yellow
        Write-Host "  [Q] Exit`n" -ForegroundColor Gray

        $choice = Read-Host "  Select an option"
        switch ($choice) {
            "1" {
                # 1-Click Upgrade: Scan -> Fix if needed -> Upgrade to Pro
                $diag = Run-ScanWorkflow
                if ($diag.DanglingServices.Count -gt 0) {
                    Write-Host "`n  [*] Automatically cleaning broken services..." -ForegroundColor Cyan
                    Repair-DanglingServices -Services $diag.DanglingServices | Out-Null
                }
                Run-UpgradeWorkflow -TargetEdition "Pro" -Bypass:$true
                break
            }
            "2" {
                Run-ScanWorkflow | Out-Null
                Write-Host "`n  Press Enter to continue..." -ForegroundColor Gray
                [void][System.Console]::ReadLine()
            }
            "3" {
                $diag = Run-ScanWorkflow
                if ($diag.DanglingServices.Count -gt 0) {
                    $repaired = Repair-DanglingServices -Services $diag.DanglingServices
                    Write-Host "`n  [+] Repaired $($repaired.Count) broken service entries!" -ForegroundColor Green
                } else {
                    Write-Host "`n  [+] No broken services found." -ForegroundColor Green
                }
                Write-Host "`n  Press Enter to continue..." -ForegroundColor Gray
                [void][System.Console]::ReadLine()
            }
            "4" {
                Run-AuditWorkflow | Out-Null
                Write-Host "`n  Press Enter to continue..." -ForegroundColor Gray
                [void][System.Console]::ReadLine()
            }
            "5" {
                Invoke-Windows11IsoDownload | Out-Null
                Write-Host "`n  Press Enter to continue..." -ForegroundColor Gray
                [void][System.Console]::ReadLine()
            }
            "6" {
                Run-UpgradeWorkflow -TargetEdition "Home" -Bypass:$true
                break
            }
            "7" {
                Set-Win11HardwareBypass
                Write-Host "`n  Press Enter to continue..." -ForegroundColor Gray
                [void][System.Console]::ReadLine()
            }
            { $_ -match '^[Qq]' } {
                Write-Host "`n  Goodbye!`n" -ForegroundColor Cyan
                return
            }
            default {
                Write-Host "  Invalid choice." -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    }
}

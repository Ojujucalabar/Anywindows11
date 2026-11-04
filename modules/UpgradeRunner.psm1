<#
.SYNOPSIS
    Upgrade Runner module for anywin11.
    Sets hardware requirement bypasses and launches the Windows 11 upgrade setup.
#>

function Set-Win11HardwareBypass {
    [CmdletBinding()]
    param()

    Write-Host "`n  [*] Applying Windows 11 Hardware Compatibility Bypasses..." -ForegroundColor Cyan

    # 1. MoSetup bypass (Official Microsoft supported override for TPM 1.2+ and CPU)
    $moSetupPath = "HKLM:\SYSTEM\Setup\MoSetup"
    if (-not (Test-Path $moSetupPath)) {
        New-Item -Path $moSetupPath -Force | Out-Null
    }
    Set-ItemProperty -Path $moSetupPath -Name "AllowUpgradesWithUnsupportedTPMOrCPU" -Value 1 -Type DWord -Force
    Write-Host "  [+] Configured: MoSetup\AllowUpgradesWithUnsupportedTPMOrCPU = 1" -ForegroundColor Green

    # 2. LabConfig bypasses (Full bypass for TPM, SecureBoot, CPU, RAM, and Storage)
    $labConfigPath = "HKLM:\SYSTEM\Setup\LabConfig"
    if (-not (Test-Path $labConfigPath)) {
        New-Item -Path $labConfigPath -Force | Out-Null
    }

    $bypasses = @(
        "BypassTPMCheck",
        "BypassSecureBootCheck",
        "BypassCPUCheck",
        "BypassRAMCheck",
        "BypassStorageCheck"
    )

    foreach ($b in $bypasses) {
        Set-ItemProperty -Path $labConfigPath -Name $b -Value 1 -Type DWord -Force
        Write-Host "  [+] Configured: LabConfig\$b = 1" -ForegroundColor Green
    }

    Write-Host "  [+] System is now configured to install Windows 11 on any hardware." -ForegroundColor Green
}

function Start-Windows11Upgrade {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$DriveLetter,

        [Parameter(Mandatory = $true)]
        [string]$ProductKey,

        [switch]$Unattended,

        [switch]$BypassChecks
    )

    $setupExe = Join-Path $DriveLetter "setup.exe"
    if (-not (Test-Path $setupExe)) {
        throw "Setup executable not found at: $setupExe"
    }

    if ($BypassChecks) {
        Set-Win11HardwareBypass
    }

    Write-Host "`n  ========================================================" -ForegroundColor Cyan
    Write-Host "   Ready to Launch Windows 11 Setup" -ForegroundColor Cyan
    Write-Host "   Target Key : $ProductKey" -ForegroundColor Cyan
    Write-Host "   Setup Path : $setupExe" -ForegroundColor Cyan
    Write-Host "  ========================================================" -ForegroundColor Cyan

    $args = "/pkey $ProductKey"
    if ($Unattended) {
        $args += " /auto upgrade /quiet /migratedata all"
        Write-Host "  [*] Launching unattended upgrade in background..." -ForegroundColor Yellow
    } else {
        Write-Host "  [*] Launching Windows 11 Setup Wizard on your screen..." -ForegroundColor Green
        Write-Host "  [*] Please approve the UAC elevation prompt if it appears." -ForegroundColor Yellow
    }

    # Start process with RunAs elevation
    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $setupExe
        $psi.Arguments = $args
        $psi.UseShellExecute = $true
        $psi.Verb = "runas"

        $proc = [System.Diagnostics.Process]::Start($psi)
        Write-Host "  [+] Windows 11 Setup launched successfully! (PID: $($proc.Id))" -ForegroundColor Green
        return $true
    } catch {
        Write-Warning "Direct launch encountered an issue: $($_.Exception.Message)"
        Write-Host "  -> Creating desktop shortcut script fallback..." -ForegroundColor Yellow
        
        $launcherContent = @"
@echo off
title Launching Windows 11 Setup
echo Launching $setupExe with Product Key $ProductKey...
powershell.exe -NoProfile -Command "Start-Process '$setupExe' -ArgumentList '$args' -Verb RunAs"
"@
        $desktopLauncher = Join-Path ([System.Environment]::GetFolderPath("Desktop")) "Launch-Win11-Upgrade.cmd"
        Set-Content -Path $desktopLauncher -Value $launcherContent -Force
        Write-Host "  [+] Created launcher on Desktop: $desktopLauncher" -ForegroundColor Green
        return $false
    }
}

Export-ModuleMember -Function Set-Win11HardwareBypass, Start-Windows11Upgrade

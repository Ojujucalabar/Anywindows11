<#
.SYNOPSIS
    Hardware Auditor module for anywin11.
    Audits CPU, RAM, Storage, TPM 2.0, SecureBoot, and UEFI partitioning for Windows 11 readiness.
#>

function Get-Win11HardwareReadiness {
    [CmdletBinding()]
    param()

    Write-Host "`n  [*] Auditing Hardware for Windows 11 Compatibility..." -ForegroundColor Cyan

    $cpu = Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1
    $cs  = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
    $diskC = Get-PSDrive C -ErrorAction SilentlyContinue

    # Check TPM via Win32_Tpm or PnP devices
    $tpmVersion = "Not Detected"
    $tpmStatus = $false

    try {
        $tpm = Get-CimInstance -Namespace "Root\CIMv2\Security\MicrosoftTpm" -ClassName Win32_Tpm -ErrorAction SilentlyContinue
        if ($tpm) {
            $tpmVersion = $tpm.SpecVersion
            $tpmStatus  = [bool]$tpm.IsEnabled_InitialValue
        }
    } catch {}

    if ($tpmVersion -eq "Not Detected") {
        $pnpTpm = Get-PnpDevice -ErrorAction SilentlyContinue | Where-Object { $_.FriendlyName -match 'Trusted Platform Module' -or $_.Class -match 'SecurityDevices' } | Select-Object -First 1
        if ($pnpTpm) {
            if ($pnpTpm.FriendlyName -match '2\.0') {
                $tpmVersion = "2.0 (via PnP)"
                $tpmStatus  = ($pnpTpm.Status -eq "OK")
            } elseif ($pnpTpm.FriendlyName -match '1\.2') {
                $tpmVersion = "1.2 (via PnP)"
                $tpmStatus  = ($pnpTpm.Status -eq "OK")
            } else {
                $tpmVersion = $pnpTpm.FriendlyName
                $tpmStatus  = ($pnpTpm.Status -eq "OK")
            }
        }
    }

    # Check Secure Boot & UEFI
    $secureBoot = $false
    try {
        $secureBoot = Confirm-SecureBootUEFI -ErrorAction SilentlyContinue
    } catch {
        # Non-elevated fallback check via Registry
        $sbKey = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\State' -Name UEFISecureBootEnabled -ErrorAction SilentlyContinue
        if ($sbKey) {
            $secureBoot = [bool]$sbKey.UEFISecureBootEnabled
        }
    }

    # Check Partition Style (GPT vs MBR)
    $partitionStyle = "Unknown"
    $disk0 = Get-Disk -Number 0 -ErrorAction SilentlyContinue
    if ($disk0) {
        $partitionStyle = $disk0.PartitionStyle
    }

    # Calculate metrics
    $ramGB  = if ($cs) { [math]::Round($cs.TotalPhysicalMemory / 1GB, 2) } else { 0 }
    $freeGB = if ($diskC) { [math]::Round($diskC.Free / 1GB, 2) } else { 0 }
    $cpuCores = if ($cpu) { $cpu.NumberOfCores } else { 0 }
    $cpuThreads = if ($cpu) { $cpu.NumberOfLogicalProcessors } else { 0 }

    # Checks
    $tpmPass       = ($tpmVersion -match '2\.0')
    $ramPass       = ($ramGB -ge 3.8) # Allow slight RAM reservation variance
    $storagePass   = ($freeGB -ge 30) # 30GB free space minimum recommended for in-place upgrade
    $cpuPass       = ($cpuCores -ge 2 -and ($cpu.Architecture -eq 9 -or $cpu.Architecture -eq 12))
    $uefiPass      = ($partitionStyle -eq 'GPT')

    $allPassed = ($tpmPass -and $ramPass -and $storagePass -and $cpuPass -and $uefiPass)
    $needsBypass = -not $allPassed

    return [PSCustomObject]@{
        CpuName         = $cpu.Name
        CpuCores        = $cpuCores
        CpuThreads      = $cpuThreads
        CpuPass         = $cpuPass
        TotalRamGB      = $ramGB
        RamPass         = $ramPass
        FreeDiskGB      = $freeGB
        StoragePass     = $storagePass
        TpmVersion      = $tpmVersion
        TpmPass         = $tpmPass
        SecureBoot      = $secureBoot
        PartitionStyle  = $partitionStyle
        UefiPass        = $uefiPass
        FullyCompliant  = $allPassed
        RequiresBypass  = $needsBypass
    }
}

Export-ModuleMember -Function Get-Win11HardwareReadiness

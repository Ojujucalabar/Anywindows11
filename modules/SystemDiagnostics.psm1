<#
.SYNOPSIS
    System Diagnostics module for anywin11.
    Scans registry hives, detects dangling services, checks pending renames and component store.
#>

function Invoke-RegistryScan {
    [CmdletBinding()]
    param()

    Write-Host "`n  [*] Scanning Registry Hives & System Integrity..." -ForegroundColor Cyan

    $results = [PSCustomObject]@{
        HivesChecked       = 0
        HivesAccessible    = 0
        DanglingServices   = @()
        PendingRenames     = 0
        CorruptionEvents   = 0
        Status             = "Clean"
    }

    # 1. Test Major Hives Accessibility
    $keys = @(
        'HKLM:\SOFTWARE',
        'HKLM:\SYSTEM',
        'HKLM:\HARDWARE',
        'HKLM:\SAM',
        'HKCU:\',
        'Registry::HKEY_USERS\.DEFAULT'
    )
    foreach ($k in $keys) {
        $results.HivesChecked++
        if (Test-Path $k -ErrorAction SilentlyContinue) {
            $results.HivesAccessible++
        }
    }

    # 2. Scan for Dangling Services (ImagePath pointing to missing binaries)
    Write-Host "  [*] Inspecting registered system services for broken image paths..." -ForegroundColor Gray
    $servicesPath = "HKLM:\SYSTEM\CurrentControlSet\Services"
    $serviceKeys = Get-ChildItem -Path $servicesPath -ErrorAction SilentlyContinue

    foreach ($s in $serviceKeys) {
        $props = Get-ItemProperty -Path $s.PSPath -ErrorAction SilentlyContinue
        $imagePath = $props.ImagePath
        $startType = $props.Start

        # Skip svchost, disabled services (Start=4), and drivers loaded by kernel
        if (-not [string]::IsNullOrWhiteSpace($imagePath) -and $startType -ne 4) {
            # Extract executable path
            $raw = $imagePath.Trim()
            if ($raw -match '^"([^"]+)"') {
                $exe = $matches[1]
            } elseif ($raw -match '^([a-zA-Z]:\\[^\s]+\.exe)') {
                $exe = $matches[1]
            } elseif ($raw -match '^([a-zA-Z]:\\[^"]+\.exe)') {
                $exe = $matches[1].Trim()
            } else {
                $exe = ($raw -split '(?=\s-|\s/)')[0].Trim('"').Trim()
            }

            # Check if it contains environment variables
            $expandedExe = [System.Environment]::ExpandEnvironmentVariables($exe)

            # Check if file exists (only flag local non-system paths)
            if ($expandedExe -match '^[a-zA-Z]:\\' -and -not ($expandedExe -match 'svchost\.exe$')) {
                if (-not (Test-Path -LiteralPath $expandedExe -ErrorAction SilentlyContinue)) {
                    # Skip if parent directory is driverstore and file might be virtualized
                    if (-not (Test-Path (Split-Path $expandedExe -Parent) -ErrorAction SilentlyContinue) -or ($expandedExe -notmatch 'system32\\drivers')) {
                        $results.DanglingServices += [PSCustomObject]@{
                            ServiceName = $s.PSChildName
                            DisplayName = $props.DisplayName
                            ImagePath   = $imagePath
                            MissingFile = $expandedExe
                            StartType   = $startType
                        }
                    }
                }
            }
        }
    }

    # 3. Scan Pending File Rename Operations
    $sessionMgr = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager"
    if (Test-Path $sessionMgr) {
        $ops = (Get-ItemProperty $sessionMgr -Name PendingFileRenameOperations -ErrorAction SilentlyContinue).PendingFileRenameOperations
        if ($ops) {
            $results.PendingRenames = $ops.Count
        }
    }

    # 4. Check for Hive Corruption in Event Logs
    $since = (Get-Date).AddDays(-30)
    $events = Get-WinEvent -FilterHashtable @{LogName='System'; StartTime=$since} -MaxEvents 1000 -ErrorAction SilentlyContinue |
        Where-Object { $_.Level -le 2 -and ($_.Message -match 'registry hive|corrupt.*hive') }
    if ($events) {
        $results.CorruptionEvents = $events.Count
    }

    if ($results.DanglingServices.Count -gt 0 -or $results.CorruptionEvents -gt 0) {
        $results.Status = "IssuesFound"
    }

    return $results
}

function Repair-DanglingServices {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Services,

        [string]$BackupDir = "$env:TEMP\anywin11\backups"
    )

    if (-not (Test-Path $BackupDir)) {
        New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
    }

    $repaired = @()
    $i = 0

    foreach ($svc in $Services) {
        $i++
        $keyName = $svc.ServiceName
        $regPath = "HKLM\SYSTEM\CurrentControlSet\Services\$keyName"
        $backupFile = Join-Path $BackupDir "backup-$keyName-$i.reg"

        Write-Host "    -> Exporting backup: $backupFile" -ForegroundColor Gray
        & reg.exe export $regPath $backupFile /y 2>&1 | Out-Null

        Write-Host "    -> Removing dangling service key: $keyName" -ForegroundColor Yellow
        $del = & reg.exe delete $regPath /f 2>&1

        if ($LASTEXITCODE -eq 0) {
            $repaired += $keyName
        } else {
            Write-Warning "Failed to remove ${keyName}: $del"
        }
    }

    return $repaired
}

function Invoke-ComponentHealthCheck {
    [CmdletBinding()]
    param(
        [switch]$RunLiveScan
    )

    $result = [PSCustomObject]@{
        DisimHealthy    = $true
        SfcHealthy      = $true
        Details         = @()
    }

    if ($RunLiveScan) {
        Write-Host "  [*] Executing DISM /Online /Cleanup-Image /ScanHealth (this may take several minutes)..." -ForegroundColor Cyan
        $dismOut = & dism.exe /Online /Cleanup-Image /ScanHealth 2>&1
        if ($LASTEXITCODE -ne 0 -or ($dismOut -match 'corruption detected')) {
            $result.DisimHealthy = $false
            $result.Details += "Component store corruption detected."
        } else {
            $result.Details += "DISM Component Store: Healthy."
        }
    } else {
        # Check logs
        $cbsLog = "$env:SystemRoot\Logs\CBS\CBS.log"
        if (Test-Path $cbsLog) {
            $recentErrors = Select-String -Path $cbsLog -Pattern 'Cannot repair member file|Corrupt' -ErrorAction SilentlyContinue | Select-Object -Last 5
            if ($recentErrors) {
                $result.SfcHealthy = $false
                $result.Details += "CBS log reports integrity anomalies."
            } else {
                $result.Details += "CBS log indicates clean verification records."
            }
        }
    }

    return $result
}

Export-ModuleMember -Function Invoke-RegistryScan, Repair-DanglingServices, Invoke-ComponentHealthCheck

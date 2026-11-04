<#
.SYNOPSIS
    ISO Engine module for anywin11.
    Handles ISO auto-discovery, SHA-256 checksum verification, mounting, and WIM inspection.
#>

function Find-Windows11Iso {
    [CmdletBinding()]
    param(
        [string]$SearchDirectory = ""
    )

    $searchDirs = @()
    if (-not [string]::IsNullOrWhiteSpace($SearchDirectory)) {
        $searchDirs += $SearchDirectory
    }

    $userProfile = $env:USERPROFILE
    $searchDirs += Join-Path $userProfile "Downloads"
    $searchDirs += Join-Path $userProfile "Desktop"
    $searchDirs += "C:\ISO"

    $candidates = @()
    foreach ($dir in $searchDirs) {
        if (Test-Path $dir) {
            $files = Get-ChildItem -Path $dir -Filter "*Win*11*.iso" -File -ErrorAction SilentlyContinue
            if ($files) {
                $candidates += $files
            }
        }
    }

    return $candidates | Sort-Object Length -Descending
}

function Test-IsoChecksum {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$IsoPath,

        [string]$ExpectedHash = ""
    )

    if (-not (Test-Path $IsoPath)) {
        throw "ISO file does not exist: $IsoPath"
    }

    Write-Host "`n  [*] Calculating SHA-256 hash for $(Split-Path $IsoPath -Leaf)..." -ForegroundColor Cyan
    Write-Host "      (This may take 1-2 minutes depending on storage speed)" -ForegroundColor Gray

    $hashResult = Get-FileHash -LiteralPath $IsoPath -Algorithm SHA256
    $computedHash = $hashResult.Hash

    $isMatch = $false
    if (-not [string]::IsNullOrWhiteSpace($ExpectedHash)) {
        $isMatch = ($computedHash.ToUpper() -eq $ExpectedHash.Trim().ToUpper())
    }

    return [PSCustomObject]@{
        IsoPath      = $IsoPath
        SizeGB       = [math]::Round((Get-Item $IsoPath).Length / 1GB, 2)
        ComputedHash = $computedHash
        ExpectedHash = $ExpectedHash
        IsMatch      = $isMatch
    }
}

function Mount-WindowsIso {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$IsoPath
    )

    if (-not (Test-Path $IsoPath)) {
        throw "ISO file not found: $IsoPath"
    }

    Write-Host "  [*] Mounting ISO: $(Split-Path $IsoPath -Leaf)..." -ForegroundColor Cyan
    $diskImage = Mount-DiskImage -ImagePath $IsoPath -PassThru -ErrorAction Stop
    $volume = $diskImage | Get-Volume -ErrorAction SilentlyContinue

    if (-not $volume -or -not $volume.DriveLetter) {
        # Fallback query
        Start-Sleep -Seconds 2
        $volume = Get-DiskImage -ImagePath $IsoPath | Get-Volume -ErrorAction SilentlyContinue
    }

    $driveLetter = "$($volume.DriveLetter):"
    Write-Host "  [+] Mounted successfully at drive: $driveLetter" -ForegroundColor Green

    return [PSCustomObject]@{
        DriveLetter = $driveLetter
        FileSystem  = $volume.FileSystem
        SizeGB      = [math]::Round($volume.Size / 1GB, 2)
        SetupExists = (Test-Path (Join-Path $driveLetter "setup.exe"))
    }
}

function Dismount-WindowsIso {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$IsoPath
    )

    try {
        Dismount-DiskImage -ImagePath $IsoPath -ErrorAction SilentlyContinue | Out-Null
        Write-Host "  [+] ISO dismounted cleanly." -ForegroundColor Green
    } catch {
        Write-Warning "Could not dismount ISO: $($_.Exception.Message)"
    }
}

function Get-WimImageEditions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$DriveLetter
    )

    $wimPath = Join-Path $DriveLetter "sources\install.wim"
    if (-not (Test-Path $wimPath)) {
        $wimPath = Join-Path $DriveLetter "sources\install.esd"
    }

    if (-not (Test-Path $wimPath)) {
        return @()
    }

    # Inspect XML metadata from end of file
    $editions = @()
    try {
        $fs = [IO.File]::OpenRead($wimPath)
        $searchSize = [Math]::Min($fs.Length, 512KB)
        $fs.Seek($fs.Length - $searchSize, [IO.SeekOrigin]::Begin) | Out-Null
        $buf = New-Object byte[] $searchSize
        [void]$fs.Read($buf, 0, $searchSize)
        $fs.Close()

        $text = [Text.Encoding]::Unicode.GetString($buf)
        $xmlStart = $text.IndexOf('<WIM>')
        $xmlEnd = $text.IndexOf('</WIM>')
        if ($xmlStart -ge 0 -and $xmlEnd -ge 0) {
            $xmlStr = $text.Substring($xmlStart, $xmlEnd - $xmlStart + 6)
            $xdoc = [xml]$xmlStr
            foreach ($img in $xdoc.WIM.IMAGE) {
                $editions += [PSCustomObject]@{
                    Index       = [int]$img.INDEX
                    Name        = $img.NAME
                    EditionID   = $img.WINDOWS.EDITIONID
                    Build       = "$($img.WINDOWS.BUILD).$($img.WINDOWS.SPBUILD)"
                    Arch        = if ($img.WINDOWS.ARCH -eq '9') { 'x64' } else { $img.WINDOWS.ARCH }
                    SizeGB      = [math]::Round([int64]$img.TOTALBYTES / 1GB, 2)
                }
            }
        }
    } catch {
        Write-Warning "Direct WIM XML parsing skipped: $($_.Exception.Message)"
    }

    return $editions
}

Export-ModuleMember -Function Find-Windows11Iso, Test-IsoChecksum, Mount-WindowsIso, Dismount-WindowsIso, Get-WimImageEditions

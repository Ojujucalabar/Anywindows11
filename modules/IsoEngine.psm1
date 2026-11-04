<#
.SYNOPSIS
    ISO Engine module for anywin11.
    Handles automated ISO downloading, auto-discovery, SHA-256 checksum verification, mounting, and WIM inspection.
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

function Invoke-Windows11IsoDownload {
    [CmdletBinding()]
    param(
        [string]$DestinationDir = (Join-Path $env:USERPROFILE "Downloads"),
        [string]$Architecture = "x64"
    )

    if (-not (Test-Path $DestinationDir)) {
        New-Item -ItemType Directory -Path $DestinationDir -Force | Out-Null
    }

    Write-Host "`n  ========================================================" -ForegroundColor Cyan
    Write-Host "   Automated Official Windows 11 ISO Downloader" -ForegroundColor Cyan
    Write-Host "  ========================================================" -ForegroundColor Cyan
    Write-Host "  [*] Requesting official direct download token from Microsoft..." -ForegroundColor Gray

    $fidoScript = Join-Path $env:TEMP "Fido.ps1"
    try {
        & curl.exe -s -L "https://raw.githubusercontent.com/pbatard/Fido/master/Fido.ps1" -o $fidoScript
    } catch {
        Write-Warning "Could not fetch Fido helper: $($_.Exception.Message)"
    }

    $downloadUrl = $null
    if (Test-Path $fidoScript) {
        try {
            Write-Host "  [*] Resolving genuine Windows 11 multi-edition image..." -ForegroundColor Gray
            $directUrl = & powershell.exe -ExecutionPolicy Bypass -File $fidoScript -Win "Windows 11" -Arch $Architecture -GetUrl 2>$null
            if ($directUrl) {
                # Find the URL line in case output had multiple lines
                $matchedLine = ($directUrl -split "`r?`n") | Where-Object { $_ -match '^https?://.*\.iso' } | Select-Object -Last 1
                if ($matchedLine) {
                    $downloadUrl = $matchedLine.Trim()
                }
            }
        } catch {
            Write-Warning "Direct API query failed: $($_.Exception.Message)"
        }
    }

    # Fallback if direct link could not be obtained
    if (-not $downloadUrl) {
        Write-Host "  [!] Could not generate direct session link. Using official Microsoft MediaCreationTool..." -ForegroundColor Yellow
        $mctUrl = "https://go.microsoft.com/fwlink/?linkid=2156295"
        $mctPath = Join-Path $DestinationDir "MediaCreationToolW11.exe"
        Write-Host "  [*] Downloading MediaCreationTool from Microsoft..." -ForegroundColor Cyan
        & curl.exe -L -o $mctPath $mctUrl
        if (Test-Path $mctPath) {
            Write-Host "  [+] MediaCreationTool downloaded: $mctPath" -ForegroundColor Green
            Write-Host "  [*] Launching MediaCreationTool to generate ISO..." -ForegroundColor Cyan
            Start-Process -FilePath $mctPath -ArgumentList "/Eula Accept /Retail /MediaArch x64 /MediaISO" -Wait
            return (Find-Windows11Iso -SearchDirectory $DestinationDir | Select-Object -First 1)
        }
        return $null
    }

    # Extract filename from URL
    $fileName = "Windows11_x64.iso"
    if ($downloadUrl -match '/([^/?]+\.iso)') {
        $fileName = $matches[1]
    }
    $targetPath = Join-Path $DestinationDir $fileName

    Write-Host "  [+] Direct Microsoft CDN URL acquired!" -ForegroundColor Green
    Write-Host "  [+] File name   : $fileName" -ForegroundColor Gray
    Write-Host "  [+] Save path   : $targetPath" -ForegroundColor Gray
    Write-Host "  [*] Downloading official ISO from Microsoft with resume support..." -ForegroundColor Cyan
    Write-Host "      (Progress is updated live below; downloads can be resumed if interrupted)`n" -ForegroundColor DarkGray

    # Use curl with progress bar, resume (-C -), and retries
    & curl.exe -L --retry 5 --retry-delay 3 -C - -# -o $targetPath $downloadUrl

    if (Test-Path $targetPath) {
        $downloadedFile = Get-Item $targetPath
        if ($downloadedFile.Length -gt 1GB) {
            Write-Host "`n  [+] Download complete! File size: {0:N2} GB" -f ($downloadedFile.Length / 1GB) -ForegroundColor Green
            return $downloadedFile
        } else {
            Write-Warning "Downloaded file is smaller than expected ({0:N2} MB)." -f ($downloadedFile.Length / 1MB)
        }
    }

    return $null
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

Export-ModuleMember -Function Find-Windows11Iso, Invoke-Windows11IsoDownload, Test-IsoChecksum, Mount-WindowsIso, Dismount-WindowsIso, Get-WimImageEditions

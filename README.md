# anywin11 🚀

> **Automated Windows 11 Readiness, System Health Scan, Hardware Audit & In-Place Upgrade Engine.**  
> Upgrade any compatible (or legacy) PC to Windows 11 cleanly while preserving your personal files, desktop, and applications.

---

```
   ___  _  ____ _____      _____ _  _ _ 
  / _ \| \| \ \ / / \ \    / /_ _| \| / |
 | (_) | .` |\ V /| |\ \/\/ / | || .` | |
  \___/|_|\_| |_| |_| \_/\_/ |___|_|\_|_|
```

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![PowerShell 5.1+](https://img.shields.io/badge/PowerShell-5.1%20%7C%207%2B-blue.svg)](https://microsoft.com/powershell)
[![Windows 10 / 11](https://img.shields.io/badge/Windows-10%20%7C%2011-0078D6.svg)](https://microsoft.com/windows)
[![Architecture: x64 | ARM64](https://img.shields.io/badge/Architecture-x64%20%7C%20ARM64-brightgreen.svg)]()

---

## 🌟 Highlights

- 🔍 **System Diagnostics & Registry Cleaner:** Scans core registry hives, detects dangling service entries pointing to deleted binaries (adware remnants, stale driver software), checks pending reboot backlogs, and inspects component store health.
- 🛡️ **Zero-Risk Automated Backups:** Exports `.reg` backup files before touching or removing any registry key.
- ⚡ **Windows 11 Hardware Auditor:** Evaluates CPU architecture, RAM, TPM 2.0 / 1.2 chip status, Secure Boot, UEFI partition style (GPT vs MBR), and storage capacity.
- 🔓 **Universal Hardware Bypass Mode:** Optional built-in `LabConfig` and `MoSetup` bypass engine (`BypassTPMCheck`, `BypassCPUCheck`, `BypassSecureBootCheck`, `BypassRAMCheck`, `BypassStorageCheck`), enabling smooth upgrades on unsupported hardware.
- 🎯 **Intelligent Edition Selection:** Detects motherboard BIOS OEM keys (`OA3xOriginalProductKey`), matching or upgrading between Windows Home and Windows Pro (Index 6) seamlessly with official generic setup keys.
- 💿 **ISO Verification & Mounting Engine:** Auto-discovers Windows 11 ISOs, verifies SHA-256 cryptographic checksums against Microsoft release databases, mounts virtual drives, and inspects `install.wim` / `install.esd` images.
- 🚀 **1-Click Execution:** Interactive graphical menu and command-line automation with automatic UAC elevation.

---

## 📂 Project Architecture

```
anywin11/
├── anywin11.cmd                  # One-click interactive runner with auto UAC elevation
├── anywin11.ps1                  # Primary CLI engine and interactive console menu
├── modules/
│   ├── SystemDiagnostics.psm1    # Scans registry hives, dangling services, pending renames
│   ├── HardwareAuditor.psm1      # Audits CPU, RAM, TPM 2.0, SecureBoot, UEFI/GPT, Storage
│   ├── EditionManager.psm1       # Resolves current Windows edition, BIOS keys & upgrade keys
│   ├── IsoEngine.psm1            # ISO auto-discovery, SHA-256 checksums, virtual drive mounting
│   └── UpgradeRunner.psm1        # Hardware bypass injection & Windows Setup launcher
├── README.md                     # Documentation
├── LICENSE                       # MIT License
└── .gitignore                    # Git exclusions
```

---

## 🚀 Quick Start

### Option 1: One-Click GUI Launcher
Double-click **`anywin11.cmd`** or run it from Command Prompt:
```cmd
anywin11.cmd
```
*It will automatically prompt for Administrator privileges (UAC) and display the interactive menu.*

### Option 2: PowerShell CLI

```powershell
# Run interactive menu
.\anywin11.ps1

# Run system integrity and dangling service scan
.\anywin11.ps1 -Scan

# Fix broken registry and dangling services (creates backups first)
.\anywin11.ps1 -Fix

# Audit hardware compatibility for Windows 11
.\anywin11.ps1 -Audit

# Upgrade directly to Windows 11 Pro (retaining personal files & apps)
.\anywin11.ps1 -Upgrade -Edition Pro

# Upgrade using a specific ISO path and force hardware bypasses
.\anywin11.ps1 -Upgrade -IsoPath "C:\path\to\Windows11.iso" -BypassHardware
```

---

## 🛠️ CLI Reference & Flags

| Flag | Description |
|---|---|
| `-Scan` | Performs a read-only audit of registry hives, services, and pending reboot queues. |
| `-Fix` | Automatically exports `.reg` backups and removes broken / orphaned service keys. |
| `-Audit` | Runs a comprehensive hardware readiness check for Windows 11 requirements. |
| `-Upgrade` | Mounts the Windows 11 ISO, applies bypasses if needed, and launches the upgrade wizard. |
| `-Edition <Pro\|Home>` | Sets target edition (defaults to `Pro`). |
| `-IsoPath <path>` | Specifies custom path to a Windows 11 `.iso` file. Auto-discovers if omitted. |
| `-ProductKey <key>` | Specifies a custom 25-character product key to install. |
| `-BypassHardware` | Forces `MoSetup` and `LabConfig` registry bypasses for legacy hardware. |
| `-Unattended` | Runs silent in-place upgrade in background (`/auto upgrade /quiet`). |

---

## 🖥️ Interactive Console Menu

When launched without arguments, `anywin11` presents an interactive dashboard:

```text
   ___  _  ____ _____      _____ _  _ _ 
  / _ \| \| \ \ / / \ \    / /_ _| \| / |
 | (_) | .` |\ V /| |\ \/\/ / | || .` | |
  \___/|_|\_| |_| |_| \_/\_/ |___|_|\_|_|
  Automated System Health, Audit & Upgrade Tool
  --------------------------------------------------------
  [i] Operating System : Microsoft Windows 10 Home (Core)
  [i] Build Version    : 18362.1256 (1903)
  [i] BIOS OEM Key     : [4.0] Core OEM:DM
  --------------------------------------------------------

  Main Menu:
  [1] Run Full Health & Compatibility Scan
  [2] Fix Broken Registry & Dangling Services
  [3] Hardware Audit for Windows 11
  [4] Upgrade to Windows 11 Pro (Index 6)
  [5] Upgrade to Windows 11 Home
  [6] Apply Hardware Bypasses (Install on ANY PC)
  [Q] Exit
```

---

## 🔒 Safety & Reversibility

1. **Registry Backups:** Every service deletion is backed up as a `.reg` file in `%TEMP%\anywin11\backups\` before removal.
2. **Data Preservation:** The upgrade command runs with `/migratedata all`, keeping all personal files, desktop items, and installed applications intact.
3. **Rollback Safeguard:** Windows Setup maintains the standard `C:\Windows.old` folder, allowing rollback via Windows Recovery within the 10-day safety period.

---

## 📜 License

This project is licensed under the [MIT License](LICENSE).

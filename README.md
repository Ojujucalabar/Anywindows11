# anywin11 🚀

> **Automated Windows 11 Readiness, System Health Scan, Hardware Audit & In-Place Upgrade Engine.**  
> Automatically downloads the official Microsoft ISO, applies hardware bypasses, and upgrades any PC to Windows 11 with 1 click while preserving all your personal files and applications.

---

```text
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

## 📋 Table of Contents
- [🌟 Highlights](#-highlights)
- [📥 1-Click Installation Guide](#-1-click-installation-guide)
  - [Prerequisites](#prerequisites)
  - [Step 1: Download anywin11](#step-1-download-anywin11)
  - [Step 2: Launch & Upgrade (Fully Automated)](#step-2-launch--upgrade-fully-automated)
- [🖥️ Interactive Console Menu](#️-interactive-console-menu)
- [🛠️ Advanced CLI Usage](#️-advanced-cli-usage)
- [📂 Project Architecture](#-project-architecture)
- [❓ Frequently Asked Questions & Troubleshooting](#-frequently-asked-questions--troubleshooting)
- [🔒 Safety & Rollback](#-safety--rollback)
- [📜 License](#-license)

---

## 🌟 Highlights

- ⚡ **Fully Automated ISO Downloader:** No manual downloads required. `anywin11` automatically negotiates and retrieves genuine, untampered Windows 11 ISOs directly from Microsoft's CDN with resumable download support (`curl.exe -C -`).
- 🔓 **Universal Hardware Bypass Engine:** Built-in `LabConfig` and `MoSetup` bypasses (`BypassTPMCheck`, `BypassCPUCheck`, `BypassSecureBootCheck`, `BypassRAMCheck`, `BypassStorageCheck`), enabling smooth upgrades on any older or unsupported PC.
- 🔍 **System Diagnostics & Registry Cleaner:** Scans core registry hives, detects dangling service entries pointing to deleted binaries (adware remnants, stale driver software), checks pending reboot backlogs, and inspects component store health.
- 🛡️ **Zero-Risk Automated Backups:** Exports `.reg` backup files to `%TEMP%\anywin11\backups\` before modifying or removing any registry key.
- 🎯 **Intelligent Edition Selection:** Detects motherboard BIOS OEM keys (`OA3xOriginalProductKey`), matching or upgrading between Windows Home and Windows Pro (Index 6) seamlessly with official generic setup keys.
- 💿 **ISO Verification & Mounting Engine:** Verifies SHA-256 cryptographic checksums, mounts virtual drives, and inspects `install.wim` / `install.esd` images automatically.
- 🚀 **Zero-Fuss Execution:** Double-click `anywin11.cmd` — it handles UAC elevation, PowerShell execution policy bypass, downloading, scanning, and launching the upgrade wizard.

---

## 📥 1-Click Installation Guide

You do **not** need to manually search for or download Windows 11 ISOs. `anywin11` handles everything end-to-end.

### Prerequisites
* **Supported OS:** Windows 10, Windows 8.1, or Windows 7 SP1 (64-bit recommended)
* **Storage Space:** At least **30–64 GB free disk space** on drive `C:`
* **Internet Connection:** To auto-download the official Windows 11 ISO directly from Microsoft

---

### Step 1: Download anywin11

Choose **either** Method A or Method B:

#### Method A: Download ZIP (No Git Required)
1. Download the repository ZIP:  
   👉 **[Click Here to Download anywin11 (ZIP)](https://github.com/Ojujucalabar/Anywindows11/archive/refs/heads/main.zip)**
2. Right-click `Anywindows11-main.zip` $\rightarrow$ select **Extract All...** $\rightarrow$ click **Extract**.

#### Method B: Clone via Git
```powershell
git clone https://github.com/Ojujucalabar/Anywindows11.git
cd Anywindows11
```

---

### Step 2: Launch & Upgrade (Fully Automated)

1. Open the extracted **`Anywindows11`** folder.
2. **Double-click `anywin11.cmd`**  
   *(Or right-click `anywin11.cmd` and select **Run as administrator**)*.
3. Click **Yes** when the Windows UAC permission prompt appears.
4. On the menu, press **`1`** for **1-Click Upgrade**:
   ```text
   Main Menu:
   [1] 🚀 1-Click Upgrade (Auto-Download ISO -> Scan -> Bypass -> Install Pro)
   ```
5. **Sit back and relax:**
   * `anywin11` scans and cleans any broken registry services or adware remnants.
   * `anywin11` automatically applies hardware bypasses so your PC qualifies regardless of age.
   * If you don't already have a Windows 11 ISO, `anywin11` downloads the official genuine ISO directly from Microsoft with live progress.
   * It mounts the ISO and launches the Windows 11 Setup wizard with **"Keep personal files and apps"** enabled.
6. Click **Install** in the Windows Setup wizard. Your PC will restart a few times and boot into your fresh Windows 11 installation with all your files intact!

---

## 🖥️ Interactive Console Menu

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
  [1] 🚀 1-Click Upgrade (Auto-Download ISO -> Scan -> Bypass -> Install Pro)
  [2] Run Full Health & Compatibility Scan
  [3] Fix Broken Registry & Dangling Services
  [4] Hardware Compatibility Audit
  [5] Download Official Windows 11 ISO Only
  [6] Upgrade to Windows 11 Home
  [7] Apply Hardware Bypasses Only
  [Q] Exit
```

---

## 🛠️ Advanced CLI Usage

For power users or automation scripts:

```powershell
# 1. Full automated upgrade (downloads ISO if missing, applies bypasses, launches setup)
.\anywin11.ps1 -Upgrade -Edition Pro

# 2. Download official Windows 11 ISO only (resumable)
.\anywin11.ps1 -DownloadOnly

# 3. Read-only registry and system integrity scan
.\anywin11.ps1 -Scan

# 4. Repair broken registry services and clean dangling paths
.\anywin11.ps1 -Fix

# 5. Audit hardware compatibility for Windows 11 requirements
.\anywin11.ps1 -Audit

# 6. Upgrade using an existing custom ISO path
.\anywin11.ps1 -Upgrade -IsoPath "D:\CustomISOs\Windows11.iso" -BypassHardware
```

### CLI Flags Reference

| Flag | Description |
|---|---|
| `-Upgrade` | Mounts (or auto-downloads) the Windows 11 ISO, applies bypasses, and launches Setup. |
| `-DownloadOnly` | Downloads the official Microsoft Windows 11 ISO to Downloads without installing. |
| `-Edition <Pro\|Home>` | Sets target edition (defaults to `Pro`). |
| `-BypassHardware` | Forces `MoSetup` and `LabConfig` registry bypasses for legacy hardware. |
| `-Scan` | Performs a read-only audit of registry hives, services, and pending reboot queues. |
| `-Fix` | Automatically exports `.reg` backups and removes broken / orphaned service keys. |
| `-Audit` | Runs a comprehensive hardware readiness check for Windows 11 requirements. |
| `-IsoPath <path>` | Specifies custom path to an existing `.iso` file. Auto-discovers/downloads if omitted. |
| `-ProductKey <key>` | Specifies a custom 25-character product key to install. |
| `-Unattended` | Runs silent in-place upgrade in background (`/auto upgrade /quiet`). |

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
│   ├── IsoEngine.psm1            # Automated Microsoft ISO downloader, checksums, virtual drive mounting
│   └── UpgradeRunner.psm1        # Hardware bypass injection & Windows Setup launcher
├── README.md                     # Documentation & user guide
├── LICENSE                       # MIT License
└── .gitignore                    # Git exclusions
```

---

## ❓ Frequently Asked Questions & Troubleshooting

#### Q: "Do I need to go to Microsoft's website to download anything?"
**A:** **No.** `anywin11` automatically negotiates and downloads the official Windows 11 ISO directly from Microsoft's CDN into your `Downloads` folder, with resume support if your connection drops.

#### Q: "My PC doesn't have TPM 2.0 or an officially supported 8th Gen+ CPU. Will this work?"
**A:** **Yes!** Option `1` automatically injects Microsoft's supported `MoSetup` and `LabConfig` bypass keys (`BypassTPMCheck`, `BypassCPUCheck`, `BypassSecureBootCheck`, `BypassRAMCheck`, `BypassStorageCheck`). This allows Windows 11 to install smoothly on older PCs.

#### Q: "Will I lose my files, pictures, or installed software?"
**A:** **No.** `anywin11` triggers an **in-place upgrade** with `/migratedata all`. All your desktop icons, documents, photos, games, and compatible applications remain untouched.

#### Q: "How do I activate Windows 11 Pro after upgrading?"
**A:** If you upgraded to Pro using the default setup key:
1. Open Windows **Settings** (`Win + I`) $\rightarrow$ **System** $\rightarrow$ **Activation**.
2. Click **Change product key** and enter your Windows 10/11 Pro key (or sign in with a Microsoft account that owns a digital Pro license).

#### Q: "Can I revert back to Windows 10 if I change my mind?"
**A:** **Yes.** Windows preserves your previous installation in `C:\Windows.old` for 10 days. To roll back:
Open **Settings** $\rightarrow$ **System** $\rightarrow$ **Recovery** $\rightarrow$ click **Go back**.

---

## 🔒 Safety & Rollback

1. **Automatic Registry Backups:** Every service deletion is backed up as a timestamped `.reg` file in `%TEMP%\anywin11\backups\` before removal.
2. **Data Preservation:** In-place upgrades preserve all personal files, desktop items, and installed applications.
3. **10-Day Rollback Safeguard:** Windows Setup maintains the standard `C:\Windows.old` folder, allowing rollback via Windows Recovery within the 10-day safety period.

---

## 📜 License

This project is licensed under the [MIT License](LICENSE).

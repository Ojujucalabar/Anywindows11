# anywin11 🚀

> **Automated Windows 11 Readiness, System Health Scan, Hardware Audit & In-Place Upgrade Engine.**  
> Upgrade any compatible (or legacy/unsupported) PC to Windows 11 cleanly while preserving all your personal files, desktop, and applications.

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
- [📥 Installation Guide](#-installation-guide)
  - [Prerequisites](#prerequisites)
  - [Step 1: Download anywin11](#step-1-download-anywin11)
  - [Step 2: Download the Windows 11 ISO](#step-2-download-the-windows-11-iso)
  - [Step 3: Run the Health Scan & Upgrade](#step-3-run-the-health-scan--upgrade)
- [🖥️ Interactive Console Menu](#️-interactive-console-menu)
- [🛠️ Advanced CLI Usage](#️-advanced-cli-usage)
- [📂 Project Architecture](#-project-architecture)
- [❓ Frequently Asked Questions & Troubleshooting](#-frequently-asked-questions--troubleshooting)
- [🔒 Safety & Rollback](#-safety--rollback)
- [📜 License](#-license)

---

## 🌟 Highlights

- 🔍 **System Diagnostics & Registry Cleaner:** Scans core registry hives, detects dangling service entries pointing to deleted binaries (adware remnants, stale driver software), checks pending reboot backlogs, and inspects component store health.
- 🛡️ **Zero-Risk Automated Backups:** Exports `.reg` backup files before touching or removing any registry key.
- ⚡ **Windows 11 Hardware Auditor:** Evaluates CPU architecture, RAM, TPM 2.0 / 1.2 chip status, Secure Boot, UEFI partition style (GPT vs MBR), and storage capacity.
- 🔓 **Universal Hardware Bypass Engine:** Built-in `LabConfig` and `MoSetup` bypasses (`BypassTPMCheck`, `BypassCPUCheck`, `BypassSecureBootCheck`, `BypassRAMCheck`, `BypassStorageCheck`), enabling smooth upgrades on unsupported hardware.
- 🎯 **Intelligent Edition Selection:** Detects motherboard BIOS OEM keys (`OA3xOriginalProductKey`), matching or upgrading between Windows Home and Windows Pro (Index 6) seamlessly with official generic setup keys.
- 💿 **ISO Verification & Mounting Engine:** Auto-discovers Windows 11 ISOs, verifies SHA-256 cryptographic checksums against Microsoft release databases, mounts virtual drives, and inspects `install.wim` / `install.esd` images.
- 🚀 **1-Click Execution:** Interactive graphical menu and command-line automation with automatic UAC elevation.

---

## 📥 Installation Guide

Follow these simple steps to download and run `anywin11` on your computer.

### Prerequisites
Before starting, ensure your system meets the following:
* **Operating System:** Windows 10, Windows 8.1, or Windows 7 SP1 (64-bit recommended)
* **Storage Space:** At least **30–64 GB free disk space** on drive `C:` for the Windows 11 installation
* **Account Rights:** Administrator privileges on your computer

---

### Step 1: Download anywin11

Choose **either** Method A (easiest) or Method B (Git):

#### Method A: Download ZIP (No Git Required)
1. At the top of this GitHub repository, click the green **Code** button and select **Download ZIP**  
   *(or [click here to download](https://github.com/Ojujucalabar/Anywindows11/archive/refs/heads/main.zip))*.
2. Right-click the downloaded `Anywindows11-main.zip` file and select **Extract All...**.
3. Choose an extraction folder (for example, on your Desktop or in `C:\anywin11`).

#### Method B: Clone via Git
Open PowerShell or Command Prompt and run:
```powershell
git clone https://github.com/Ojujucalabar/Anywindows11.git
cd Anywindows11
```

---

### Step 2: Download the Windows 11 ISO

`anywin11` automatically discovers any Windows 11 ISO placed in your **Downloads** or **Desktop** folder.

1. Go to the official [Microsoft Windows 11 Download Page](https://www.microsoft.com/software-download/windows11).
2. Scroll down to **Download Windows 11 Disk Image (ISO) for x64 devices**.
3. Select **Windows 11 (multi-edition ISO for x64 devices)** from the dropdown and click **Download Now**.
4. Choose your preferred product language (e.g., **English (United States)**) and click **Confirm**.
5. Click **64-bit Download** and save the `.iso` file directly into your standard **`Downloads`** folder.

> 💡 **Tip:** Keep the ISO inside your `Downloads` folder! `anywin11` will automatically detect, verify its checksum, and mount it for you.

---

### Step 3: Run the Health Scan & Upgrade

1. Open the extracted **`Anywindows11`** folder.
2. **Double-click `anywin11.cmd`**  
   *(Alternatively, right-click `anywin11.cmd` and select **Run as administrator**)*.
3. When the Windows User Account Control (UAC) prompt appears (*"Do you want to allow this app to make changes to your device?"*), click **Yes**.
4. The interactive terminal menu will appear on your screen:
   * **Press `1`** to run a complete system and registry health scan.
   * **Press `2`** if any broken registry services or adware leftovers were found, to clean them safely with automatic backups.
   * **Press `4`** to upgrade to **Windows 11 Pro** (or **`5`** for **Windows 11 Home**).
5. The Windows 11 Setup wizard will launch on your screen. Verify that **"Keep personal files and apps"** is checked, and click **Install**!

---

## 🖥️ Interactive Console Menu

When launched via `anywin11.cmd` or `.\anywin11.ps1`, you will see this interactive dashboard:

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

## 🛠️ Advanced CLI Usage

For advanced users or automation scripts, `anywin11` can be controlled directly via PowerShell command-line arguments:

```powershell
# 1. Run a read-only registry and system integrity scan
.\anywin11.ps1 -Scan

# 2. Repair broken registry services and clean dangling paths
.\anywin11.ps1 -Fix

# 3. Audit hardware compatibility for Windows 11 requirements
.\anywin11.ps1 -Audit

# 4. In-place upgrade to Windows 11 Pro (retaining files & apps)
.\anywin11.ps1 -Upgrade -Edition Pro

# 5. Upgrade using a custom ISO path with hardware bypasses enabled
.\anywin11.ps1 -Upgrade -IsoPath "D:\CustomISOs\Windows11.iso" -BypassHardware

# 6. Silent unattended upgrade
.\anywin11.ps1 -Upgrade -Edition Pro -BypassHardware -Unattended
```

### CLI Flags Reference

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
├── README.md                     # Documentation & user guide
├── LICENSE                       # MIT License
└── .gitignore                    # Git exclusions
```

---

## ❓ Frequently Asked Questions & Troubleshooting

#### Q: "PowerShell says running scripts is disabled on this system."
**A:** This is Windows' default execution policy. You do not need to change system settings—simply double-click **`anywin11.cmd`**, which automatically launches PowerShell with the `-ExecutionPolicy Bypass` parameter.

#### Q: "My PC doesn't have TPM 2.0 or an officially supported 8th Gen+ CPU. Can I still upgrade?"
**A:** **Yes!** When you choose Option `4` or `5` (or run with `-BypassHardware`), `anywin11` automatically injects Microsoft's supported `MoSetup` and `LabConfig` registry keys. This allows the official Windows 11 Setup wizard to bypass TPM, CPU generation, Secure Boot, and RAM checks safely.

#### Q: "Will I lose my files, pictures, or installed software?"
**A:** **No.** `anywin11` executes an **in-place upgrade** with `/migratedata all`, meaning your personal files, desktop shortcuts, documents, and compatible applications remain exactly where they are.

#### Q: "How do I activate Windows 11 Pro after upgrading?"
**A:** If you upgraded to Pro using the default setup key, your system will be in a grace period. To activate permanently:
1. Open Windows **Settings** (`Win + I`) $\rightarrow$ **System** $\rightarrow$ **Activation**.
2. Click **Change product key** and enter your Windows 10 or Windows 11 Pro key (or sign in with a Microsoft account that owns a digital Pro license).

#### Q: "Can I revert back to Windows 10 if I don't like Windows 11?"
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

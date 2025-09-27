---

## 🗂️ BackupConfig.ps1 — Automated Backup Script

### 📌 Overview
`BackupConfig.ps1` is a PowerShell script designed to automate backups of selected directories using 7-Zip. It supports configuration via text files or command-line parameters, and includes archive rotation, and cleanup of old logs.

---

### ⚙️ Features
- Backs up directories listed in a config file or passed via `-BackupDirs`
- Archives backups using 7-Zip and removes temporary folders
- Creates timestamped subfolders per machine (e.g. `KompPC_20250927_1055`)
- Logs all actions with `[INFO]`, `[WARN]`, `[ERROR]` levels
- Rotates logs when exceeding 512 KB
- Keeps only the 7 most recent archived logs
- Stores logs in a dedicated `Logs` subfolder
- You can use a script in the Windows Task Scheduler

---

### 📁 Default Configuration Files
If not provided via parameters, the script uses or creates:

| File              | Purpose                                | Default Value                          |
|-------------------|----------------------------------------|----------------------------------------|
| `BackupDirs.txt`  | List of directories to back up         | `C:\Program Files\7-Zip`               |
| `BackupDest.txt`  | Destination root for backups           | `C:\BackupConfig`                      |
| `BackupConfig.txt`| Path to `7z.exe` executable            | `C:\Program Files\7-Zip\7z.exe`        |

Each file is created automatically if missing.

---

### 🚀 Usage

#### Basic run (uses config files):
```powershell
.\BackupConfig.ps1
```

#### With custom directory list:
```powershell
.\BackupConfig.ps1 -BackupDirs "C:\MyDirs.txt"
```

#### With custom destination:
```powershell
.\BackupConfig.ps1 -BackupDest "D:\Backups"
```

#### With custom 7-Zip path:
```powershell
.\BackupConfig.ps1 -BackupConfig "D:\Tools\7z.exe"
```

#### Full example:
```powershell
.\BackupConfig.ps1 `
    -BackupDirs "C:\Config\Dirs.txt" `
    -BackupDest "E:\MyBackups" `
    -BackupConfig "C:\Apps\7-Zip\7z.exe"
```

---

### 📄 Log Format

Logs are saved in `Logs\BackupConfig_CurrentLog.txt` with entries like:

```
2025-09-27 10:55:30 [INFO] Backup script started
2025-09-27 10:55:30 [WARN] BackupDirs.txt not found. Creating...
2025-09-27 10:55:31 [ERROR] Specified path not found: D:\InvalidDir
```

When the log exceeds 512 KB, it is archived as:
```
Logs\BackupConfig_20250927_1055.txt
```

Only the 7 most recent archived logs are retained.

---

### 📦 Requirements
- PowerShell 5.1 or newer
- 7-Zip installed (or portable `7z.exe`)
- Permissions to read/write in configured paths

---

### 🧪 Testing Tips
- Try with a small test directory first
- Verify that `7z.exe` is accessible
- Check `Logs` folder for detailed output

---

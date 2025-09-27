# source https://github.com/obeliksgall/BackupConfig
# version 0.1

#how to run example without params
#powershell.exe -ExecutionPolicy Bypass -File ".\BackupConfig.ps1"

param (
    [string]$BackupDirs,
    [string]$BackupDest,
    [string]$BackupConfig
)

# === CONFIG ===
$default7ZipPath = "C:\Program Files\7-Zip\7z.exe"
$defaultDirsPath = "C:\Program Files\7-Zip"
$defaultDestPath = "C:\BackupConfig"
$dirsFile = "BackupDirs.txt"
$destFile = "BackupDest.txt"
$configFilePath = "BackupConfig.txt"
$logBaseName = "BackupConfig"
$logMaxSizeKB = 512

# === LOG SETUP ===
$scriptDir = Split-Path -Path $MyInvocation.MyCommand.Path
$logDir = Join-Path $scriptDir "Logs"
if (-not (Test-Path $logDir)) {
    New-Item -Path $logDir -ItemType Directory | Out-Null
}
$logCurrent = Join-Path $logDir "${logBaseName}_CurrentLog.txt"

function Write-Log {
    param (
        [string]$Message,
        [ValidateSet("INFO", "WARN", "ERROR", "DEBUG")]
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "$timestamp [$Level] $Message"

    switch ($Level) {
        "INFO" { $color = "Gray" }
        "WARN" { $color = "Yellow" }
        "ERROR" { $color = "Red" }
        "DEBUG" { $color = "DarkGray" }
    }
    Write-Host $entry -ForegroundColor $color

    if (Test-Path $logCurrent) {
        $sizeKB = (Get-Item $logCurrent).Length / 1KB
        if ($sizeKB -ge $logMaxSizeKB) {
            $stamp = Get-Date -Format "yyyyMMdd_HHmm"
            $archived = Join-Path $logDir "${logBaseName}_$stamp.txt"
            Rename-Item -Path $logCurrent -NewName $archived
            Add-Content -Path $archived -Value "$timestamp [INFO] Log file archived due to size limit."
        }
    }

    Add-Content -Path $logCurrent -Value $entry
}

# === CLEANUP OLD LOGS ===
$archivedLogs = Get-ChildItem -Path $logDir -Filter "${logBaseName}_????????_????.txt" | Sort-Object LastWriteTime
if ($archivedLogs.Count -gt 7) {
    $logsToDelete = $archivedLogs | Select-Object -First ($archivedLogs.Count - 7)
    foreach ($log in $logsToDelete) {
        try {
            Remove-Item -Path $log.FullName -Force
            Write-Log "Old log deleted: $($log.Name)" -Level "INFO"
        }
        catch {
            Write-Log "Failed to delete old log: $($log.Name)" -Level "WARN"
        }
    }
}

# === SCRIPT START ===
Write-Log "Backup script started"

# === VALIDATE BackupConfig ===
if ($BackupConfig) {
    Write-Log "Using 7-Zip path from parameter: $BackupConfig"
    $sevenZipExe = $BackupConfig
}
else {
    if (-not (Test-Path $configFilePath)) {
        Write-Log "BackupConfig.txt not found. Creating with default 7-Zip path..." -Level "WARN"
        Set-Content -Path $configFilePath -Value $default7ZipPath
    }
    $sevenZipExe = Get-Content $configFilePath
    Write-Log "7-Zip executable path: $sevenZipExe"
}

# === VERIFY 7-ZIP ===
if (-not (Test-Path $sevenZipExe)) {
    Write-Log "7-Zip executable not found: $sevenZipExe" -Level "ERROR"
    exit 1
}

try {
    $versionOutput = & "$sevenZipExe" | Out-String
    if ($versionOutput -notmatch "7-Zip") {
        Write-Log "Executable exists but does not appear to be 7-Zip: $sevenZipExe" -Level "ERROR"
        exit 1
    }
    Write-Log "Verified 7-Zip executable: $sevenZipExe" -Level "INFO"
}
catch {
    Write-Log "Failed to execute 7-Zip for verification: $($_.Exception.Message)" -Level "ERROR"
    exit 1
}

###### Weryfikacja podpisu cyfrowego (opcjonalna)
#try {
#    $sig = Get-AuthenticodeSignature $sevenZipExe
#    if ($sig.Status -eq "Valid") {
#        Write-Log "Executable is digitally signed by: $($sig.SignerCertificate.Subject)" -Level "DEBUG"
#    }
#    else {
#        Write-Log "Executable signature is invalid or missing." -Level "WARN"
#    }
#}
#catch {
#    Write-Log "Failed to verify digital signature: $($_.Exception.Message)" -Level "WARN"
#}
######

# === VALIDATE BackupDest ===
if ($BackupDest) {
    $backupRoot = $BackupDest
}
else {
    if (-not (Test-Path $destFile)) {
        Write-Log "BackupDest.txt not found. Creating with default destination path..." -Level "WARN"
        Set-Content -Path $destFile -Value $defaultDestPath
    }
    $backupRoot = Get-Content $destFile
}
if (-not (Test-Path $backupRoot)) {
    New-Item -Path $backupRoot -ItemType Directory | Out-Null
    Write-Log "Created backup destination directory: $backupRoot"
}
Write-Log "Backup destination root: $backupRoot"

# === VALIDATE BackupDirs ===
$backupDirsList = @()
Write-Log "BackupDirs raw value: '$BackupDirs'" -Level "DEBUG"

if ($PSBoundParameters.ContainsKey('BackupDirs')) {
    if ([string]::IsNullOrWhiteSpace($BackupDirs) -or -not (Test-Path $BackupDirs)) {
        Write-Log "BackupDirs parameter is empty or file does not exist: $BackupDirs" -Level "ERROR"
        exit 1
    }

    try {
        $backupDirsList = Get-Content $BackupDirs | Where-Object { $_.Trim() -ne "" }
    }
    catch {
        Write-Log "Failed to read BackupDirs file: $BackupDirs" -Level "ERROR"
        exit 1
    }

    if (-not $backupDirsList -or $backupDirsList.Count -eq 0) {
        Write-Log "BackupDirs file exists but is empty or contains only blank lines: $BackupDirs" -Level "ERROR"
        exit 1
    }

    Write-Log "Using backup directories from parameter: $BackupDirs"
}
else {
    if (-not (Test-Path $dirsFile)) {
        Write-Log "BackupDirs.txt not found. Creating with default directory..." -Level "WARN"
        Set-Content -Path $dirsFile -Value $defaultDirsPath
    }

    $backupDirsList = Get-Content $dirsFile | Where-Object { $_.Trim() -ne "" }

    if (-not $backupDirsList -or $backupDirsList.Count -eq 0) {
        Write-Log "BackupDirs.txt is empty or contains only blank lines: $dirsFile" -Level "ERROR"
        exit 1
    }

    Write-Log "Using directories from BackupDirs.txt"
}

# === CREATE TEMP BACKUP FOLDER ===
$timestamp = Get-Date -Format "yyyyMMdd_HHmm"
$computerName = $env:COMPUTERNAME
$tempBackupDir = Join-Path $backupRoot "${computerName}_$timestamp"
New-Item -Path $tempBackupDir -ItemType Directory | Out-Null
Write-Log "Temporary backup folder created: $tempBackupDir"

# === COPY DIRECTORIES ===
foreach ($dir in $backupDirsList) {
    if (-not $dir -or $dir.Trim() -eq "") {
        Write-Log "Skipped empty directory entry." -Level "WARN"
        continue
    }

    if (Test-Path $dir) {
        $name = Split-Path $dir -Leaf
        $target = Join-Path $tempBackupDir $name
        Write-Log "Copying: $dir -> $target"
        Copy-Item -Path $dir -Destination $target -Recurse -Force
    }
    else {
        Write-Log "Directory not found and skipped: $dir" -Level "WARN"
    }
}

# === ARCHIVE ===
$archivePath = "${tempBackupDir}.7z"
Write-Log "Creating archive: $archivePath"

try {
    & "$sevenZipExe" a -t7z "`"$archivePath`"" "`"$tempBackupDir`"" | Out-Null

    if (-not (Test-Path $archivePath)) {
        Write-Log "Archive was not created: $archivePath" -Level "ERROR"
        Remove-Item -Path $tempBackupDir -Recurse -Force
        exit 1
    }
}
catch {
    Write-Log "Failed to execute 7-Zip: $($_.Exception.Message)" -Level "ERROR"
    Remove-Item -Path $tempBackupDir -Recurse -Force
    exit 1
}

# === CLEANUP ===
Write-Log "Cleaning up temporary folder: $tempBackupDir"
Remove-Item -Path $tempBackupDir -Recurse -Force

Write-Log "Backup completed successfully"
Write-Log "Archive saved at: $archivePath"

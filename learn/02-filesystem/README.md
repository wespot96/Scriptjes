# Module 02: File System Operations

## Learning Goals

- Master file and directory enumeration with Get-ChildItem
- Validate paths and perform existence checks
- Create, copy, move, and delete files and folders safely
- Read and write file content efficiently
- Compress and archive files with Compress-Archive

## Key Concepts

### 1. Get-ChildItem: List Files and Folders
```powershell
# List current directory
Get-ChildItem

# List with detailed format
Get-ChildItem -Force  # Include hidden files
Get-ChildItem -Directory  # Folders only
Get-ChildItem -File  # Files only

# Recursive listing
Get-ChildItem -Recurse
Get-ChildItem -Recurse -Depth 2  # Limit depth

# Filter by name
Get-ChildItem -Filter "*.log"
Get-ChildItem -Path "C:\Windows" -Filter "*.exe"
```

### 2. Test-Path: Verify Path Existence
```powershell
# Check if path exists
Test-Path "C:\Windows"
Test-Path "C:\NonExistent"

# Check specific type
Test-Path "C:\Windows" -PathType Container  # Is it a folder?
Test-Path "C:\Windows\System32" -PathType Leaf  # Is it a file?

# Check with -IsValid (syntax only, doesn't verify existence)
Test-Path "C:\Invalid\Path::WithColon" -IsValid
```

### 3. New-Item: Create Files and Folders
```powershell
# Create folder
New-Item -Path "C:\Backups" -ItemType Directory

# Create file
New-Item -Path "C:\logs\app.log" -ItemType File

# Create with content
New-Item -Path "C:\config.txt" -ItemType File -Value "ServerName=DB01`nPort=5432"

# Create folder structure
New-Item -Path "C:\Data\Archive\2024\Q1" -ItemType Directory -Force
```

### 4. Copy-Item: Duplicate Files and Folders
```powershell
# Copy single file
Copy-Item -Path "C:\Original.txt" -Destination "C:\Backup.txt"

# Copy folder recursively
Copy-Item -Path "C:\Source" -Destination "C:\Backup" -Recurse

# Copy with filter
Copy-Item -Path "C:\Logs\*.log" -Destination "C:\Archive\"

# Copy and exclude
Copy-Item -Path "C:\Logs" -Destination "C:\Backup" -Recurse -Exclude "*.tmp"
```

### 5. Move-Item: Relocate Files and Folders
```powershell
# Move file
Move-Item -Path "C:\temp.txt" -Destination "C:\Archive\temp.txt"

# Move and rename
Move-Item -Path "C:\OldName.log" -Destination "C:\NewName.log"

# Move folder with contents
Move-Item -Path "C:\OldFolder" -Destination "C:\Archive\NewFolder"

# Move with force (overwrite)
Move-Item -Path "C:\file.txt" -Destination "C:\file.txt" -Force
```

### 6. Remove-Item: Delete Files and Folders
```powershell
# Remove file
Remove-Item -Path "C:\temp.txt"

# Remove folder and contents
Remove-Item -Path "C:\TempFolder" -Recurse

# Remove with confirmation
Remove-Item -Path "C:\logs" -Recurse -Confirm

# Remove without confirmation
Remove-Item -Path "C:\logs" -Recurse -Force

# Remove filtered items
Remove-Item -Path "C:\Logs\*.log" -Filter "*.tmp"
```

### 7. Get-Content: Read File Content
```powershell
# Read entire file as array of strings
$lines = Get-Content -Path "C:\config.txt"

# Read as single string
$content = Get-Content -Path "C:\config.txt" -Raw

# Read specific lines
Get-Content -Path "C:\log.txt" -TotalCount 10  # First 10 lines
Get-Content -Path "C:\log.txt" -Tail 5  # Last 5 lines

# Stream large files
Get-Content -Path "C:\LargeFile.log" -ReadCount 1000
```

### 8. Set-Content and Add-Content: Write to Files
```powershell
# Overwrite file
Set-Content -Path "C:\output.txt" -Value "Line 1", "Line 2", "Line 3"

# Append to file
Add-Content -Path "C:\log.txt" -Value "New entry: $(Get-Date)"

# Write from pipeline
Get-Service | Select-Object Name, Status | Set-Content -Path "C:\services.txt"

# Overwrite with string
Set-Content -Path "C:\simple.txt" -Value "Hello World"
```

### 9. Compress-Archive: Create ZIP Files
```powershell
# Compress single file
Compress-Archive -Path "C:\file.txt" -DestinationPath "C:\file.zip"

# Compress folder
Compress-Archive -Path "C:\Logs" -DestinationPath "C:\Logs.zip"

# Compress with filter
Get-ChildItem -Path "C:\Logs" -Filter "*.log" | Compress-Archive -DestinationPath "C:\Logs.zip"

# Update existing archive
Compress-Archive -Path "C:\NewFiles\*" -DestinationPath "C:\archive.zip" -Update

# Expand archive
Expand-Archive -Path "C:\archive.zip" -DestinationPath "C:\Extracted"
```

### 10. Directory Separator and Paths
```powershell
# Cross-platform safe path joining
$path = Join-Path -Path "C:\Logs" -ChildPath "app.log"

# Get path components
Split-Path -Path "C:\Logs\app.log" -Parent  # C:\Logs
Split-Path -Path "C:\Logs\app.log" -Leaf   # app.log

# Resolve to absolute path
Resolve-Path -Path "..\config.txt"
```

### 11. File Properties and Metadata
```powershell
# Get file details
$file = Get-Item -Path "C:\app.log"
$file.Length  # Size in bytes
$file.CreationTime
$file.LastWriteTime
$file.Attributes

# Get directory size
(Get-ChildItem -Path "C:\Logs" -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB
```

### 12. Working with Special Folders
```powershell
# Use environment variables
$desktop = $env:USERPROFILE + "\Desktop"
$temp = $env:TEMP
$programFiles = $env:ProgramFiles

# Or use DirectoryInfo
[System.Environment]::GetFolderPath("Desktop")
```

## Real-World Example: Log Rotation Script

Reference: **cleanlogs.ps1**

This script demonstrates:
- Finding old log files with Get-ChildItem
- Filtering by LastWriteTime
- Archiving with Compress-Archive
- Removing old files after archival

```powershell
# Archive logs older than 30 days
$logPath = "C:\Logs"
$archivePath = "C:\LogArchive"
$daysOld = 30

New-Item -Path $archivePath -ItemType Directory -Force

Get-ChildItem -Path $logPath -Filter "*.log" | Where-Object {
    $_.LastWriteTime -lt (Get-Date).AddDays(-$daysOld)
} | ForEach-Object {
    Write-Host "Archiving $($_.Name)"
    Copy-Item -Path $_.FullName -Destination $archivePath
}

# Create monthly archive
$monthYear = Get-Date -Format "yyyy-MM"
Compress-Archive -Path "$archivePath\*.log" -DestinationPath "$archivePath\Logs-$monthYear.zip"

# Clean up archived logs
Remove-Item -Path "$archivePath\*.log" -Force
```

## Quick Reference: File System Operations

| Task | Command |
|------|---------|
| List files | `Get-ChildItem` |
| Check if exists | `Test-Path` |
| Create folder | `New-Item -ItemType Directory` |
| Create file | `New-Item -ItemType File` |
| Copy file | `Copy-Item` |
| Move file | `Move-Item` |
| Delete | `Remove-Item` |
| Read content | `Get-Content` |
| Write content | `Set-Content` |
| Append content | `Add-Content` |
| Compress | `Compress-Archive` |
| Extract | `Expand-Archive` |
| Get properties | `Get-Item \| Get-Member` |
| Join path | `Join-Path` |
| Split path | `Split-Path` |

## Try It: Hands-On Exercises

### Exercise 1: List and filter logs
```powershell
# Find all .log files modified in last 7 days
$days = 7
Get-ChildItem -Path "C:\Windows\System32\LogFiles" -Filter "*.log" -Recurse |
    Where-Object { $_.LastWriteTime -gt (Get-Date).AddDays(-$days) }
```

### Exercise 2: Create backup folder structure
```powershell
# Create organized backup folders by date
$today = Get-Date -Format "yyyy-MM-dd"
$backupRoot = "C:\Backups"
$backupPath = Join-Path -Path $backupRoot -ChildPath $today

New-Item -Path $backupPath -ItemType Directory -Force
New-Item -Path (Join-Path $backupPath -ChildPath "Databases") -ItemType Directory
New-Item -Path (Join-Path $backupPath -ChildPath "Files") -ItemType Directory
New-Item -Path (Join-Path $backupPath -ChildPath "Configs") -ItemType Directory
```

### Exercise 3: Copy with exclusions
```powershell
# Backup a folder excluding temp and cache
$source = "C:\AppData"
$dest = "C:\Backup\AppData"
Copy-Item -Path $source -Destination $dest -Recurse -Exclude "*.tmp", "*cache*"
```

### Exercise 4: Archive old files
```powershell
# Find files older than 90 days and compress them
$oldDate = (Get-Date).AddDays(-90)
$oldFiles = Get-ChildItem -Path "C:\Archive" -Recurse |
    Where-Object { $_.LastWriteTime -lt $oldDate }

if ($oldFiles) {
    Compress-Archive -Path $oldFiles.FullName -DestinationPath "C:\OldFiles.zip"
}
```

### Exercise 5: Read and parse log file
```powershell
# Get last 50 lines of log file
$log = Get-Content -Path "C:\Windows\System32\config\SYSTEM" -Tail 50
$log | ForEach-Object { Write-Output $_ }
```

### Exercise 6: Safe file deletion
```powershell
# Delete with confirmation (interactive)
$path = "C:\TempFiles"
if (Test-Path -Path $path) {
    Remove-Item -Path $path -Recurse -Confirm
}
```

### Exercise 7: Calculate folder size
```powershell
# Get size of a folder in MB
$folder = "C:\Program Files"
$size = (Get-ChildItem -Path $folder -Recurse |
    Measure-Object -Property Length -Sum).Sum / 1MB
Write-Host "Folder size: $([Math]::Round($size, 2)) MB"
```

### Exercise 8: Compare two directories
```powershell
# List files in source but not in backup
$source = "C:\Source"
$backup = "C:\Backup"
$sourceFiles = Get-ChildItem -Path $source -Recurse
$backupFiles = Get-ChildItem -Path $backup -Recurse

$sourceFiles | Where-Object {
    -not (Test-Path -Path (Join-Path $backup -ChildPath $_.Name))
}
```

## Further Reading

- [Get-ChildItem](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/get-childitem)
- [Test-Path](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/test-path)
- [Copy-Item](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/copy-item)
- [Get-Content and Set-Content](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/get-content)
- [Compress-Archive](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.archive/compress-archive)
- [About Providers](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_providers)

# SilenceDetector

SilenceDetector is a PowerShell script that finds long silence in MP3 files and shortens it.

It is made for spoken-word audio where dead air is a problem.

## What It Does

- Scans MP3 files in an `Input` folder.
- Detects silence and classifies it as:
  - `START` (beginning of file)
  - `MIDDLE` (inside file)
  - `END` (end of file)
- Creates cleaned files in `Output`.
- Saves original versions of changed files in `UnmodifiedOriginals`.
- Writes a text report in `Logs`.

## Folder Layout (Default)

By default, these folders are under `~/Downloads`:

- `Input` — files to scan
- `Output` — cleaned files
- `UnmodifiedOriginals` — backups of files that were changed
- `Logs` — run reports

The script preserves subfolder structure.

Example:

- `Input/Series/Episode/file.mp3` -> `Output/Series/Episode/file.mp3`
- `Input/Series/Episode/file.mp3` -> `UnmodifiedOriginals/Series/Episode/file.mp3` (if changed)

## Quick Start

### Windows

- Double-click `RunScan.bat`
- It uses PowerShell Core (`pwsh`) if available, otherwise Windows PowerShell.

Or run manually:

```cmd
pwsh -ExecutionPolicy Bypass -File "ScanSilence.ps1"
```

### macOS / Linux

```bash
./RunScan.sh
```

Or:

```bash
pwsh ./ScanSilence.ps1
```

## Requirements

- PowerShell (`pwsh`) recommended
- FFmpeg + FFprobe installed and available in PATH

You can also place `ffmpeg` and `ffprobe` in the script directory.

## Configuration

Edit `config.txt` to control behavior.

### Current Default Config

```ini
# Silence Detection Settings
threshold=-40
minSilenceStartEnd=1
minSilenceMiddle=3
# Legacy compatibility key (optional). If set, it applies to both thresholds:
# minSilence=3
startEndSilenceDuration=0.5
middleSilenceDuration=2.5
contentThreshold=0.1

# Folder Paths
inputPath=~/Downloads/Input
outputPath=~/Downloads/Output
unmodifiedOriginalsPath=~/Downloads/UnmodifiedOriginals
logsPath=~/Downloads/Logs

# Processing Options
moveOnlyModifiedFiles=false
dryRun=false
```

## Settings Explained (Plain Language)

### Detection Settings (What gets flagged)

- `threshold`
  - Loudness level to treat as silence (in dB).
  - Typical values: `-40` to `-20`.

- `minSilenceStartEnd`
  - Minimum silence length (seconds) to flag at the beginning or end of a file.

- `minSilenceMiddle`
  - Minimum silence length (seconds) to flag in the middle of a file.

- `contentThreshold`
  - Helps decide whether a silence is start/middle/end.

### Editing Settings (How much silence remains)

- `startEndSilenceDuration`
  - How much silence to keep after trimming start/end silence.

- `middleSilenceDuration`
  - How much silence to keep for middle silence.

### File Movement Settings

- `moveOnlyModifiedFiles`
  - `false` (default): unchanged files are also copied to `Output`.
  - `true`: only changed files go to `Output`; unchanged files stay in `Input`.

- `dryRun`
  - `true`: analyze only, no file changes.
  - `false`: process files.

## Most Common Presets

### 1) Balanced (good default)

```ini
minSilenceStartEnd=1
minSilenceMiddle=3
startEndSilenceDuration=0.5
middleSilenceDuration=2.5
moveOnlyModifiedFiles=true
```

### 2) Aggressive Start/End Cleanup

```ini
minSilenceStartEnd=0.8
minSilenceMiddle=3
startEndSilenceDuration=0.3
middleSilenceDuration=2.5
moveOnlyModifiedFiles=true
```

### 3) Conservative / Safer

```ini
minSilenceStartEnd=1.5
minSilenceMiddle=4
startEndSilenceDuration=0.7
middleSilenceDuration=3.0
```

## Command-Line Overrides

Command-line values override `config.txt` for that run.

Examples:

```powershell
pwsh ./ScanSilence.ps1 -DryRun
```

```powershell
pwsh ./ScanSilence.ps1 -MinSilenceStartEnd 1 -MinSilenceMiddle 3
```

```powershell
pwsh ./ScanSilence.ps1 -Threshold -35 -StartEndSilenceDuration 0.3 -MiddleSilenceDuration 2.0
```

```powershell
pwsh ./ScanSilence.ps1 -MoveOnlyModifiedFiles $true
```

## What Happens During a Run

1. Scan all MP3 files in `Input` (including subfolders).
2. Detect and classify silence.
3. For files needing changes:
   - copy original to `UnmodifiedOriginals`
   - write cleaned version to `Output`
4. For files without changes:
   - copied to `Output` only if `moveOnlyModifiedFiles=false`
5. Clean up `Input`:
   - remove all processed files when default mode is used
   - remove only modified files when `moveOnlyModifiedFiles=true`
6. Write report to `Logs`.

## Dry Run Mode

Use dry run to preview what would happen:

```powershell
pwsh ./ScanSilence.ps1 -DryRun
```

Dry run shows:

- files that would be changed
- start/middle/end silence details
- where each file would go
- summary counts

No files are modified, moved, or deleted in dry run.

## Report Summary Fields

At the end of each report, you'll see values like:

- `Files scanned`
- `Files requiring silence processing`
- `Files moved to Output unchanged`
- `Files left in Input unchanged` (when `moveOnlyModifiedFiles=true`)
- `Longest silence detected`

## Installation Notes

### Windows (winget)

```cmd
winget install Microsoft.PowerShell
winget install Gyan.FFmpeg
```

### macOS (Homebrew)

```bash
brew install powershell ffmpeg
```

### Linux (Debian/Ubuntu)

```bash
sudo apt update
sudo apt install powershell ffmpeg
```

## Project Files

- `ScanSilence.ps1` — main script
- `config.txt` — settings
- `RunScan.bat` — Windows launcher
- `RunScan.sh` — macOS/Linux launcher
- `README.md` — documentation

## License

MIT

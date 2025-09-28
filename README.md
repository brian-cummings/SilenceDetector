# SilenceDetector

A cross-platform PowerShell script for detecting and processing silence periods in MP3 files using FFmpeg. Designed for radio playout systems to prevent dead air by automatically cleaning files with problematic silence periods.

## Purpose

This tool scans MP3 files for silence periods and automatically processes them to prevent dead air in radio playout systems. It detects problematic silence periods and intelligently trims or reduces them while preserving the original files for reference.

## Folder Layout

The script automatically creates and uses the following folder structure. By default, folders are created in ~/Downloads/, but you can specify absolute paths for any or all folders:

- **Input** → MP3 files to scan (files moved from here after processing) - Default: ~/Downloads/Input
- **Output** → Cleaned/processed files ready for playout - Default: ~/Downloads/Output
- **UnmodifiedOriginals** → Original files that contained problematic silence - Default: ~/Downloads/UnmodifiedOriginals
- **Logs** → Timestamped TXT reports - Default: ~/Downloads/Logs

## Quick Start

### Windows
Double-click `RunScan.bat` or run:
```cmd
powershell.exe -ExecutionPolicy Bypass -File "ScanSilence.ps1"
```

### macOS/Linux
```bash
./RunScan.sh
```
or
```bash
pwsh ./ScanSilence.ps1
```

## Features

- **Cross-platform**: Works on Windows, macOS, and Linux
- **Visual progress tracking**: Real-time progress bar showing current file and completion percentage
- **Audio quality preservation**: Automatically detects and preserves original bitrate, codec, and sample rate
- **Robust error handling**: 
  - FFmpeg timeout protection prevents hanging on problematic files
  - Disk space validation before processing
  - Graceful handling of corrupted or locked files
- **Sequential processing**: Handles large file collections efficiently with detailed progress tracking
- **Automatic processing**: Intelligently trims/reduces silence periods
- **Smart silence handling**: 
  - START/END silence: Trimmed to configurable duration (default: 0.5 seconds)
  - MIDDLE silence: Reduced to configurable duration (default: 2.5 seconds)
- **File preservation**: Originals with silence moved to UnmodifiedOriginals
- **Automatic folder creation**: Creates Input, Output, UnmodifiedOriginals, and Logs folders if missing
- **Comprehensive reporting**: Generates detailed TXT reports with full analysis
- **Metadata updates**: Updates audio duration metadata to match processed content
- **File overwrite protection**: Prevents accidental overwriting of existing output files
- **Frame-accurate processing**: Uses precise FFmpeg filters for timing accuracy
- **Configurable parameters**: Adjustable silence threshold and minimum duration
- **Intelligent silence location tagging**: Identifies silence as START, MIDDLE, or END based on surrounding content
  - START: Silence with meaningful content after but not before
  - END: Silence with meaningful content before but not after  
  - MIDDLE: Silence with meaningful content both before and after
- **Timecode output**: Converts seconds to HH:MM:SS.mmm format
- **Input folder cleanup**: Moves files from Input folder after processing
- **Summary statistics**: Reports files processed, flagged, and longest silence detected

## Dry Run Mode

The `-DryRun` parameter enables analysis mode where the script examines files and reports what would be processed **without making any changes**. This is perfect for:

- **Testing configurations** before processing valuable audio files
- **Previewing results** to understand what the tool will do
- **Validating settings** with different thresholds and durations
- **Batch analysis** to see which files need attention

### Dry Run Features:
- 🔍 **Complete analysis** of all silence periods
- 📊 **Detailed reports** showing planned processing actions
- ⏱️ **Time savings calculations** for each silence period
- 📁 **File movement preview** (what goes where)
- 🎯 **Zero risk** - no files are modified, moved, or deleted
- 📝 **Full logging** with "DRY RUN" markers in reports

### Example Dry Run Output:
```
🔍 DRY RUN: Would process silence periods and create cleaned version
  - END silence: 00:00:03.500 → 00:00:00.500 (saves 00:00:03.000)
  → Original would be moved to: UnmodifiedOriginals/song.mp3
  → Cleaned version would be created in: Output/song.mp3
```

## Configuration

### Default Parameters
- **Threshold**: -40 dB (adjustable via `-Threshold` parameter)
- **MinSilence**: 3 seconds (adjustable via `-MinSilence` parameter)
- **StartEndSilenceDuration**: 0.5 seconds (adjustable via `-StartEndSilenceDuration` parameter)
- **MiddleSilenceDuration**: 2.5 seconds (adjustable via `-MiddleSilenceDuration` parameter)
- **ContentThreshold**: 0.1 seconds (adjustable via `-ContentThreshold` parameter)
  - Minimum duration to consider as "meaningful content" when classifying silence location
- **DryRun**: Disabled (enable with `-DryRun` switch)
  - Analysis mode that shows what would be processed without making any changes
- **InputPath**: "~/Downloads/Input" (or specify absolute path)
- **OutputPath**: "~/Downloads/Output" (or specify absolute path)
- **UnmodifiedOriginalsPath**: "~/Downloads/UnmodifiedOriginals" (or specify absolute path)
- **LogsPath**: "~/Downloads/Logs" (or specify absolute path)

### Custom Parameters

**Basic usage with custom thresholds:**
```powershell
pwsh ./ScanSilence.ps1 -Threshold -35 -MinSilence 5
```

**Custom silence processing durations:**
```powershell
pwsh ./ScanSilence.ps1 -StartEndSilenceDuration 1.0 -MiddleSilenceDuration 3.0
```

**Comprehensive example with all audio processing parameters:**
```powershell
pwsh ./ScanSilence.ps1 -Threshold -35 -MinSilence 4 -StartEndSilenceDuration 0.3 -MiddleSilenceDuration 2.0
```

**Dry run mode (analysis only, no file changes):**
```powershell
pwsh ./ScanSilence.ps1 -DryRun
```

**Dry run with custom parameters:**
```powershell
pwsh ./ScanSilence.ps1 -DryRun -Threshold -35 -StartEndSilenceDuration 0.3 -MiddleSilenceDuration 2.0
```

**Using absolute paths (Windows):**
```powershell
pwsh ./ScanSilence.ps1 -InputPath "C:\Music\ToScan" -OutputPath "C:\Music\Processed" -UnmodifiedOriginalsPath "C:\Music\Flagged" -LogsPath "C:\Music\Reports"
```

**Using absolute paths (Mac/Linux):**
```powershell
pwsh ./ScanSilence.ps1 -InputPath "/Users/username/Music/ToScan" -OutputPath "/Users/username/Music/Processed" -UnmodifiedOriginalsPath "/Users/username/Music/Flagged" -LogsPath "/Users/username/Music/Reports"
```

## Technical Implementation

### Silence Processing Methods
The script uses different FFmpeg approaches optimized for each silence type:

- **END Silence**: Uses `-t` parameter to limit output duration (simple and reliable)
- **START Silence**: Uses `-ss` parameter to skip initial silence (preserves audio quality)  
- **MIDDLE Silence**: Uses `filter_complex` with `atrim` and `concat` for frame-accurate processing
- **Multiple Silence**: Generalizes the `atrim + concat` approach for precise timing across all segments

### Audio Quality Preservation
- Automatically detects original audio properties using `ffprobe`
- Maps codec names correctly (e.g., `mp3` → `libmp3lame`)
- Preserves original bitrate, sample rate, and channel configuration
- Updates metadata duration to match processed audio length

### Cross-Platform Compatibility
- Robust home directory resolution (`$env:HOME`, `$env:USERPROFILE`, etc.)
- Works with PowerShell Core (`pwsh`) on all platforms
- Handles path resolution and tilde expansion correctly

## Requirements

- **PowerShell**: Windows built-in or PowerShell Core (`pwsh`) on Mac/Linux
- **FFmpeg with FFprobe**: Audio processing and analysis tools
  - **Preferred**: Place `ffmpeg.exe` and `ffprobe.exe` (Windows) or `ffmpeg` and `ffprobe` (Mac/Linux) in the script directory
  - **Fallback**: Ensure both FFmpeg and FFprobe are in your system PATH
  - **Note**: FFprobe is used for audio quality detection and is typically included with FFmpeg installations

## Report Formats

### TXT Report Example
```
Silence Detection Report - 2024-01-15_14-30-25
==========================================
Threshold: -40 dB
MinSilence: 3 seconds

Files to scan: 5

File: song1.mp3
Duration: 00:03:45.123
silence_start: 00:00:00.000 [START]
silence_end: 00:00:03.500 [START]
silence_start: 00:03:40.000 [END]
silence_end: 00:03:45.123 [END]

==========================================
SUMMARY
Files scanned: 5
Files flagged: 2
Longest silence detected: 00:00:05.250
```

## Files

- `ScanSilence.ps1` - Main PowerShell script
- `RunScan.bat` - Windows batch file for easy execution
- `RunScan.sh` - macOS/Linux shell script for easy execution
- `README.md` - This documentation

## Usage Workflow

### Option 1: Default Behavior (Downloads Folder)
1. **Setup**: Place `ffmpeg.exe` (Windows) or `ffmpeg` (Mac/Linux) in the script directory
2. **Place MP3 files** in `~/Downloads/Input` folder (created automatically)
3. **Run** the appropriate script for your platform
4. **Processing**: The script will:
   - Scan all MP3 files for silence
   - Process files with problematic silence (trim/reduce)
   - Move originals with silence to `~/Downloads/UnmodifiedOriginals`
   - Place all processed/clean files in `~/Downloads/Output`
   - Move files from the `~/Downloads/Input` folder
5. **Review** results:
   - Cleaned files ready for playout: `~/Downloads/Output` folder
   - Original problematic files: `~/Downloads/UnmodifiedOriginals` folder  
   - Detailed reports: `~/Downloads/Logs` folder

### Option 2: Custom Absolute Paths
1. **Setup**: Place `ffmpeg.exe` (Windows) or `ffmpeg` (Mac/Linux) in the script directory
2. **Run** the script from anywhere with absolute paths:
   ```powershell
   pwsh /path/to/ScanSilence.ps1 -InputPath "/absolute/path/to/mp3s" -OutputPath "/path/to/clean" -UnmodifiedOriginalsPath "/path/to/originals" -LogsPath "/absolute/path/to/reports"
   ```
3. **Review** results in your specified directories

## License

MIT License - feel free to use and modify as needed.
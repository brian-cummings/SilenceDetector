# SilenceDetector

A cross-platform PowerShell script for detecting and processing silence periods in MP3 files using FFmpeg. Designed for radio playout systems to prevent dead air by automatically cleaning talk audio files with problematic silence periods.

## Purpose

This tool scans talk audio MP3 files for silence periods and automatically processes them to prevent dead air in radio playout systems. It detects problematic silence periods and intelligently trims or reduces them while preserving the original files for reference.

## Folder Layout

The script automatically creates and uses the following folder structure. By default, folders are created in ~/Downloads/, but you can specify absolute paths for any or all folders:

- **Input** → Talk audio MP3 files to scan (files moved from here after processing) - Default: ~/Downloads/Input
- **Output** → Cleaned/processed talk audio files ready for playout - Default: ~/Downloads/Output
- **UnmodifiedOriginals** → Original talk audio files that contained problematic silence - Default: ~/Downloads/UnmodifiedOriginals
- **Logs** → Timestamped TXT reports - Default: ~/Downloads/Logs

### Recursive Directory Structure Support

The script now supports recursive folder structures, preserving the directory hierarchy from the Input folder in both Output and UnmodifiedOriginals folders. This means:

- **Input/Series/Episode/talk_audio.mp3** → **Output/Series/Episode/talk_audio.mp3** (cleaned)
- **Input/Series/Episode/talk_audio.mp3** → **UnmodifiedOriginals/Series/Episode/talk_audio.mp3** (original with silence)

The script automatically creates the necessary subdirectories in the output folders to maintain the same structure as your input organization.

## Quick Start

### Windows
Double-click `RunScan.bat` (requires PowerShell Core) or run manually:
```cmd
pwsh -ExecutionPolicy Bypass -File "ScanSilence.ps1"
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
- **Recursive directory support**: Preserves folder structure from Input to Output and UnmodifiedOriginals
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
  → Original would be moved to: UnmodifiedOriginals/talk_audio.mp3
  → Cleaned version would be created in: Output/talk_audio.mp3
```

## Configuration

### Configuration File

The script now supports a simple text configuration file (`config.txt`) that allows you to customize all settings without modifying the PowerShell code. This makes it much easier to adjust thresholds and paths for different use cases.

#### Config File Location
- **Default**: `config.txt` in the same directory as the PowerShell script
- **Format**: Simple key=value pairs with comments (lines starting with #)

#### Config File Example
```ini
# SilenceDetector Configuration File
# Edit these values to customize the script behavior without modifying the PowerShell code

# Silence Detection Settings
threshold=-40
minSilence=3
startEndSilenceDuration=0.5
middleSilenceDuration=2.5
contentThreshold=0.1

# Folder Paths (use ~ for home directory or absolute paths)
inputPath=~/Downloads/Input
outputPath=~/Downloads/Output
unmodifiedOriginalsPath=~/Downloads/UnmodifiedOriginals
logsPath=~/Downloads/Logs

# Processing Options
dryRun=false
```

#### Config File Benefits
- **Easy customization**: Change settings without touching PowerShell code
- **Version control friendly**: Keep your settings separate from the script
- **Multiple configurations**: Create different config files for different scenarios
- **Command line override**: Parameters passed via command line still override config file values
- **Fallback defaults**: If config file is missing, sensible defaults are used

#### Configuration Priority
1. **Command line parameters** (highest priority)
2. **Config file values**
3. **Built-in defaults** (lowest priority)

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

**Option 1: Using config file (recommended for regular use)**
1. Edit `config.txt` with your desired settings
2. Run the script normally: `pwsh ./ScanSilence.ps1`

**Option 2: Command line parameters (for one-time overrides)**
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
pwsh ./ScanSilence.ps1 -InputPath "C:\Audio\ToScan" -OutputPath "C:\Audio\Processed" -UnmodifiedOriginalsPath "C:\Audio\Flagged" -LogsPath "C:\Audio\Reports"
```

**Using absolute paths (Mac/Linux):**
```powershell
pwsh ./ScanSilence.ps1 -InputPath "/Users/username/Audio/ToScan" -OutputPath "/Users/username/Audio/Processed" -UnmodifiedOriginalsPath "/Users/username/Audio/Flagged" -LogsPath "/Users/username/Audio/Reports"
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

## Installation

### Windows Installation (Recommended)

Use Windows Package Manager (winget) to install the required dependencies:

```cmd
# Install PowerShell Core (recommended for better cross-platform compatibility)
winget install Microsoft.PowerShell

# Install FFmpeg
winget install Gyan.FFmpeg
```

After installation:
1. Restart your terminal or command prompt
2. Verify installations:
   ```cmd
   pwsh --version
   ffmpeg -version
   ```

### Manual Installation

#### Windows
- **PowerShell**: Use built-in Windows PowerShell or install PowerShell Core from [GitHub](https://github.com/PowerShell/PowerShell)
- **FFmpeg**: Download from [ffmpeg.org](https://ffmpeg.org/download.html) and add to PATH, or place `ffmpeg.exe` and `ffprobe.exe` in the script directory

#### macOS
```bash
# Using Homebrew
brew install powershell ffmpeg

# Using MacPorts
sudo port install powershell ffmpeg
```

#### Linux
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install powershell ffmpeg

# CentOS/RHEL/Fedora
sudo dnf install powershell ffmpeg
```

## Requirements

- **PowerShell Core (`pwsh`)**: Required on all platforms for cross-platform compatibility
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

File: talk_audio1.mp3
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
- `config.txt` - Configuration file for easy customization of settings
- `RunScan.bat` - Windows batch file for easy execution
- `RunScan.sh` - macOS/Linux shell script for easy execution
- `README.md` - This documentation

## Usage Workflow

### Option 1: Default Behavior (Downloads Folder)
1. **Setup**: Place `ffmpeg.exe` (Windows) or `ffmpeg` (Mac/Linux) in the script directory
2. **Configure** (optional): Edit `config.txt` to customize thresholds and paths
3. **Place talk audio MP3 files** in `~/Downloads/Input` folder (created automatically) - supports nested subdirectories
4. **Run** the appropriate script for your platform
5. **Processing**: The script will:
   - Scan all talk audio MP3 files for silence (including subdirectories)
   - Process files with problematic silence (trim/reduce)
   - Move originals with silence to `~/Downloads/UnmodifiedOriginals` (preserving directory structure)
   - Place all processed/clean talk audio files in `~/Downloads/Output` (preserving directory structure)
   - Move files from the `~/Downloads/Input` folder
6. **Review** results:
   - Cleaned talk audio files ready for playout: `~/Downloads/Output` folder (with preserved directory structure)
   - Original problematic talk audio files: `~/Downloads/UnmodifiedOriginals` folder (with preserved directory structure)
   - Detailed reports: `~/Downloads/Logs` folder

### Option 2: Custom Absolute Paths
1. **Setup**: Place `ffmpeg.exe` (Windows) or `ffmpeg` (Mac/Linux) in the script directory
2. **Configure**: Edit `config.txt` with your custom paths, or use command line parameters
3. **Run** the script from anywhere:
   ```powershell
   pwsh /path/to/ScanSilence.ps1 -InputPath "/absolute/path/to/talk_audio" -OutputPath "/path/to/clean" -UnmodifiedOriginalsPath "/path/to/originals" -LogsPath "/absolute/path/to/reports"
   ```
4. **Review** results in your specified directories

## License

MIT License - feel free to use and modify as needed.
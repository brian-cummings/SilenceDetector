# SilenceDetector

A cross-platform PowerShell script for detecting silence periods in MP3 files using FFmpeg.

## Features

- **Cross-platform**: Works on Windows, macOS, and Linux
- **Automatic path detection**: Uses Downloads folder by default
- **Timecode output**: Converts seconds to HH:MM:SS.mmm format
- **Silence location**: Identifies if silence is at START, MIDDLE, or END of file
- **Detailed reporting**: Generates timestamped reports with file durations
- **Easy execution**: Simple batch/shell scripts for different platforms

## Files

- `ScanSilence.ps1` - Main PowerShell script
- `RunScan.bat` - Windows batch file for easy execution
- `RunScan.sh` - macOS/Linux shell script for easy execution

## Usage

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

## Default Behavior

- **Input**: Scans `~/Downloads/silence_test/` for MP3 files
- **Output**: Saves reports to `~/Downloads/silence_test_reports/`
- **Silence detection**: 3+ second periods below -40dB
- **Report format**: Timestamped text files with timecode and location info

## Custom Parameters

You can override the default paths:
```powershell
pwsh ./ScanSilence.ps1 -InputPath "C:\MyMusic" -OutputDir "C:\Reports"
```

## Requirements

- PowerShell Core (`pwsh`) - [Download here](https://github.com/PowerShell/PowerShell)
- FFmpeg - [Download here](https://ffmpeg.org/download.html)
  - Windows: Place `ffmpeg.exe` in the script directory
  - macOS: Install via Homebrew (`brew install ffmpeg`)
  - Linux: Install via package manager

## Report Format

```
Silence Detection Report - 2024-01-15_14-30-25
==========================================

File: /path/to/song.mp3
Duration: 00:03:45.123
silence_start: 00:00:00.000 [START]
silence_end: 00:00:03.500 [START]
silence_start: 00:03:40.000 [END]
silence_end: 00:03:45.123 [END]
```

## License

MIT License - feel free to use and modify as needed.

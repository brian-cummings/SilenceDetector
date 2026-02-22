#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v pwsh >/dev/null 2>&1; then
    echo "Error: PowerShell Core (pwsh) is not installed or not in PATH."
    echo "Please install PowerShell Core from: https://github.com/PowerShell/PowerShell"
    exit 1
fi

echo "SilenceDetector - MP3 Silence Processing Tool"
echo "============================================="
echo ""
echo "This will scan MP3 files in the Input folder for silence:"
echo "- Files with problematic silence will be processed and cleaned"
echo "- Originals with silence will be moved to UnmodifiedOriginals folder"
echo "- Processed files will be placed in Output folder"
echo "- Unchanged files are also moved to Output by default"
echo "- Set moveOnlyModifiedFiles=true in config.txt to keep unchanged files in Input"
echo "- Detailed reports will be saved to Logs folder"
echo ""
echo "Starting scan..."

pwsh "$SCRIPT_DIR/ScanSilence.ps1"
EXIT_CODE=$?

echo ""
if [ $EXIT_CODE -eq 0 ]; then
    echo "Scan completed successfully. Check the report for details:"
else
    echo "Scan completed with errors. Check the report for details:"
fi
echo "- Processed files: Output folder"
echo "- Original files: UnmodifiedOriginals folder"
echo "- Detailed reports: Logs folder"

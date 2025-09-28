#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

pwsh "$SCRIPT_DIR/ScanSilence.ps1"

echo "Press any key to continue..."
read -n 1 -s

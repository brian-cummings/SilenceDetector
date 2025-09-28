@echo off
echo SilenceDetector - MP3 Silence Processing Tool
echo =============================================
echo.
echo This will scan MP3 files in the Input folder for silence:
echo - Files with problematic silence will be processed and cleaned
echo - Originals with silence will be moved to UnmodifiedOriginals folder
echo - Processed files will be placed in Output folder
echo - Files will be moved from Input folder after processing
echo - Detailed reports will be saved to Logs folder
echo.
echo Starting scan...

powershell.exe -ExecutionPolicy Bypass -File "%~dp0ScanSilence.ps1"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo Scan completed successfully. Check the report for details:
) else (
    echo.
    echo Scan completed with errors. Check the report for details:
)
echo - Processed files: Output folder
echo - Original files: UnmodifiedOriginals folder  
echo - Detailed reports: Logs folder
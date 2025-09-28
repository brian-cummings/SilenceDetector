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

REM Check if PowerShell Core is available
where pwsh >nul 2>nul
if %ERRORLEVEL% EQU 0 goto :use_pwsh

REM PowerShell Core not found, try Windows PowerShell
echo PowerShell Core (pwsh) not found, trying Windows PowerShell...
where powershell >nul 2>nul
if %ERRORLEVEL% EQU 0 goto :use_powershell

REM No PowerShell found
echo ERROR: No PowerShell found!
echo Please install PowerShell Core using: winget install Microsoft.PowerShell
echo Or download from: https://github.com/PowerShell/PowerShell
pause
exit /b 1

:use_pwsh
echo Using PowerShell Core (pwsh)...
pwsh -ExecutionPolicy Bypass -NoProfile -File "%~dp0ScanSilence.ps1"
goto :check_result

:use_powershell
echo Using Windows PowerShell...
powershell -ExecutionPolicy Bypass -NoProfile -File "%~dp0ScanSilence.ps1"
goto :check_result

:check_result

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
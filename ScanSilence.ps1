param(
    [string]$InputPath = "",
    [string]$OutputDir = ""
)

$BaseFolder = "Downloads"
$InputFolder = "silence_test"
$OutputFolder = "silence_test_reports"

$IsWindowsOS = $IsWindows -or $env:OS -eq "Windows_NT"

if ($IsWindowsOS) {
    $BasePath = Join-Path $env:USERPROFILE $BaseFolder
} else {
    $BasePath = Join-Path $env:HOME $BaseFolder
}

if ([string]::IsNullOrEmpty($InputPath)) {
    $InputPath = Join-Path $BasePath $InputFolder
}

if ([string]::IsNullOrEmpty($OutputDir)) {
    $OutputDir = Join-Path $BasePath $OutputFolder
}

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$reportFile = Join-Path $OutputDir "silence_report_$timestamp.txt"

New-Item -ItemType File -Path $reportFile -Force | Out-Null
Add-Content -Path $reportFile -Value "Silence Detection Report - $timestamp"
Add-Content -Path $reportFile -Value "=========================================="
Add-Content -Path $reportFile -Value ""

function Convert-ToTimecode {
    param([double]$Seconds)
    
    $hours = [int][math]::Floor($Seconds / 3600)
    $minutes = [int][math]::Floor(($Seconds % 3600) / 60)
    $secs = [int][math]::Floor($Seconds % 60)
    $milliseconds = [int][math]::Floor(($Seconds % 1) * 1000)
    
    return "{0:D2}:{1:D2}:{2:D2}.{3:D3}" -f $hours, $minutes, $secs, $milliseconds
}

function Get-SilenceLocation {
    param(
        [double]$SilenceStart,
        [double]$SilenceEnd,
        [double]$TotalDuration
    )
    
    if ($TotalDuration -eq 0) { return "Unknown" }
    
    $startPercent = ($SilenceStart / $TotalDuration) * 100
    $endPercent = ($SilenceEnd / $TotalDuration) * 100
    
    if ($startPercent -lt 5) {
        return "START"
    } elseif ($endPercent -gt 95) {
        return "END"
    } else {
        return "MIDDLE"
    }
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

$ffmpegPath = $null
if (Test-Path (Join-Path $scriptDir "ffmpeg.exe")) {
    $ffmpegPath = Join-Path $scriptDir "ffmpeg.exe"
} elseif (Test-Path (Join-Path $scriptDir "ffmpeg")) {
    $ffmpegPath = Join-Path $scriptDir "ffmpeg"
} else {
    $ffmpegPath = "ffmpeg"
}

Write-Host "Input path: $InputPath"
Write-Host "Output directory: $OutputDir"
Write-Host "Report file: $reportFile"

$mp3Files = Get-ChildItem -Path $InputPath -Filter "*.mp3" -Recurse
Write-Host "Found $($mp3Files.Count) MP3 files to scan"

foreach ($file in $mp3Files) {
    Write-Host "Scanning: $($file.FullName)"
    
    $ffmpegArgs = @(
        "-i", $file.FullName,
        "-af", "silencedetect=noise=-40dB:d=3",
        "-f", "null",
        "-"
    )
    
    try {
        $output = & $ffmpegPath $ffmpegArgs 2>&1
        
        $durationMatch = $output | Where-Object { $_ -match "Duration: (\d{2}):(\d{2}):(\d{2}\.\d{2})" }
        $totalDuration = 0
        if ($durationMatch) {
            $durationParts = $durationMatch -match "Duration: (\d{2}):(\d{2}):(\d{2}\.\d{2})"
            $hours = [int]$matches[1]
            $minutes = [int]$matches[2] 
            $seconds = [double]$matches[3]
            $totalDuration = $hours * 3600 + $minutes * 60 + $seconds
        }
        
        $silenceLines = $output | Where-Object { $_ -match "silence_start|silence_end" }
        
        if ($silenceLines.Count -gt 0) {
            Write-Host "  Found $($silenceLines.Count) silence periods - writing to report"
            Add-Content -Path $reportFile -Value "File: $($file.FullName)"
            if ($totalDuration -gt 0) {
                $durationTimecode = Convert-ToTimecode $totalDuration
                Add-Content -Path $reportFile -Value "Duration: $durationTimecode"
            }
            
            $silenceStart = 0
            $silenceEnd = 0
            
            foreach ($line in $silenceLines) {
                $timecodeLine = $line
                if ($line -match "silence_start:\s*([\d.]+)") {
                    $seconds = [double]$matches[1]
                    $timecode = Convert-ToTimecode $seconds
                    $timecodeLine = $line -replace "silence_start:\s*[\d.]+", "silence_start: $timecode"
                    $silenceStart = $seconds
                }
                if ($line -match "silence_end:\s*([\d.]+)") {
                    $seconds = [double]$matches[1]
                    $timecode = Convert-ToTimecode $seconds
                    $timecodeLine = $timecodeLine -replace "silence_end:\s*[\d.]+", "silence_end: $timecode"
                    $silenceEnd = $seconds
                    
                    if ($silenceStart -gt 0) {
                        $location = Get-SilenceLocation $silenceStart $silenceEnd $totalDuration
                        $timecodeLine += " [$location]"
                    }
                }
                Add-Content -Path $reportFile -Value $timecodeLine
            }
            Add-Content -Path $reportFile -Value ""
        } else {
            Write-Host "  No silence detected"
        }
    }
    catch {
        Write-Warning "Error processing $($file.FullName): $($_.Exception.Message)"
    }
}

Add-Content -Path $reportFile -Value ""
Add-Content -Path $reportFile -Value "=========================================="
Add-Content -Path $reportFile -Value "Scan complete. Processed $($mp3Files.Count) files."

Write-Host "Scan complete. Report saved to: $reportFile"

param(
    [Nullable[double]]$Threshold,
    [Nullable[double]]$MinSilence,
    [Nullable[double]]$StartEndSilenceDuration,
    [Nullable[double]]$MiddleSilenceDuration,
    [Nullable[double]]$ContentThreshold,
    [string]$InputPath = "",
    [string]$OutputPath = "",
    [string]$UnmodifiedOriginalsPath = "",
    [string]$LogsPath = "",
    [switch]$DryRun
)


# Configuration file loading function
function Read-ConfigFile {
    param([string]$ConfigPath = "config.txt")
    
    $config = @{
        Threshold = -40
        MinSilence = 3
        StartEndSilenceDuration = 0.5
        MiddleSilenceDuration = 2.5
        ContentThreshold = 0.1
        InputPath = "~/Downloads/Input"
        OutputPath = "~/Downloads/Output"
        UnmodifiedOriginalsPath = "~/Downloads/UnmodifiedOriginals"
        LogsPath = "~/Downloads/Logs"
        DryRun = $false
    }
    
    if (Test-Path $ConfigPath) {
        Write-Host "Loading configuration from: $ConfigPath" -ForegroundColor Cyan
        
        try {
            # Use UTF8 encoding to handle potential BOM issues on Windows
            $lines = Get-Content $ConfigPath -Encoding UTF8 -ErrorAction Stop
            Write-Verbose "Config: Successfully read $($lines.Count) lines from config file"
        } catch {
            Write-Warning "Config: Failed to read config file '$ConfigPath': $($_.Exception.Message)"
            Write-Host "Using default configuration values" -ForegroundColor Yellow
            return $config
        }
        foreach ($line in $lines) {
            $line = $line.Trim()
            
            # Skip empty lines and comments
            if ([string]::IsNullOrEmpty($line) -or $line.StartsWith("#")) {
                continue
            }
            
            # Parse key=value pairs
            if ($line -match "^([^=]+)=(.*)$") {
                $key = $matches[1].Trim().ToLower()
                $value = $matches[2].Trim()
                Write-Verbose "Config: Parsing line '$line' -> key='$key', value='$value'"
                
                switch ($key) {
                    "threshold" { 
                        $parsedValue = 0.0
                        if ([double]::TryParse($value, [System.Globalization.NumberStyles]::Float, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$parsedValue)) {
                            $config.Threshold = $parsedValue
                            Write-Verbose "Config: Set Threshold = $parsedValue"
                        } else {
                            Write-Warning "Config: Failed to parse threshold value '$value', using default: $($config.Threshold)"
                        }
                    }
                    "minsilence" { 
                        $parsedValue = 0.0
                        if ([double]::TryParse($value, [System.Globalization.NumberStyles]::Float, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$parsedValue)) {
                            $config.MinSilence = $parsedValue
                            Write-Verbose "Config: Set MinSilence = $parsedValue"
                        } else {
                            Write-Warning "Config: Failed to parse minSilence value '$value', using default: $($config.MinSilence)"
                        }
                    }
                    "startendsilenceduration" { 
                        $parsedValue = 0.0
                        if ([double]::TryParse($value, [System.Globalization.NumberStyles]::Float, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$parsedValue)) {
                            $config.StartEndSilenceDuration = $parsedValue
                            Write-Verbose "Config: Set StartEndSilenceDuration = $parsedValue"
                        } else {
                            Write-Warning "Config: Failed to parse startEndSilenceDuration value '$value', using default: $($config.StartEndSilenceDuration)"
                        }
                    }
                    "middlesilenceduration" { 
                        $parsedValue = 0.0
                        if ([double]::TryParse($value, [System.Globalization.NumberStyles]::Float, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$parsedValue)) {
                            $config.MiddleSilenceDuration = $parsedValue
                            Write-Verbose "Config: Set MiddleSilenceDuration = $parsedValue"
                        } else {
                            Write-Warning "Config: Failed to parse middleSilenceDuration value '$value', using default: $($config.MiddleSilenceDuration)"
                        }
                    }
                    "contentthreshold" { 
                        $parsedValue = 0.0
                        if ([double]::TryParse($value, [System.Globalization.NumberStyles]::Float, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$parsedValue)) {
                            $config.ContentThreshold = $parsedValue
                            Write-Verbose "Config: Set ContentThreshold = $parsedValue"
                        } else {
                            Write-Warning "Config: Failed to parse contentThreshold value '$value', using default: $($config.ContentThreshold)"
                        }
                    }
                    "inputpath" { $config.InputPath = $value }
                    "outputpath" { $config.OutputPath = $value }
                    "unmodifiedoriginalspath" { $config.UnmodifiedOriginalsPath = $value }
                    "logspath" { $config.LogsPath = $value }
                    "dryrun" { 
                        $config.DryRun = ($value -eq "true" -or $value -eq "1")
                    }
                }
            } else {
                Write-Verbose "Config: Skipping invalid line (no key=value pattern): '$line'"
            }
        }
        
        # Show summary of loaded values
        Write-Host "Config loaded successfully:" -ForegroundColor Green
        Write-Host "  Threshold: $($config.Threshold) dB" -ForegroundColor Gray
        Write-Host "  MinSilence: $($config.MinSilence) seconds" -ForegroundColor Gray
        Write-Host "  StartEndSilenceDuration: $($config.StartEndSilenceDuration) seconds" -ForegroundColor Gray
        Write-Host "  MiddleSilenceDuration: $($config.MiddleSilenceDuration) seconds" -ForegroundColor Gray
        Write-Host "  ContentThreshold: $($config.ContentThreshold) seconds" -ForegroundColor Gray
    } else {
        Write-Host "Config file not found: $ConfigPath - Using defaults" -ForegroundColor Yellow
    }
    
    return $config
}

# Load configuration
$config = Read-ConfigFile

# Apply config values, but allow command line parameters to override
if ($Threshold.HasValue) { 
    Write-Host "  Overriding Threshold: $($config.Threshold) -> $($Threshold.Value)" -ForegroundColor Yellow
    $config.Threshold = $Threshold.Value 
}
if ($MinSilence.HasValue) { 
    Write-Host "  Overriding MinSilence: $($config.MinSilence) -> $($MinSilence.Value)" -ForegroundColor Yellow
    $config.MinSilence = $MinSilence.Value 
}
if ($StartEndSilenceDuration.HasValue) { 
    Write-Host "  Overriding StartEndSilenceDuration: $($config.StartEndSilenceDuration) -> $($StartEndSilenceDuration.Value)" -ForegroundColor Yellow
    $config.StartEndSilenceDuration = $StartEndSilenceDuration.Value 
}
if ($MiddleSilenceDuration.HasValue) { 
    Write-Host "  Overriding MiddleSilenceDuration: $($config.MiddleSilenceDuration) -> $($MiddleSilenceDuration.Value)" -ForegroundColor Yellow
    $config.MiddleSilenceDuration = $MiddleSilenceDuration.Value 
}
if ($ContentThreshold.HasValue) { 
    Write-Host "  Overriding ContentThreshold: $($config.ContentThreshold) -> $($ContentThreshold.Value)" -ForegroundColor Yellow
    $config.ContentThreshold = $ContentThreshold.Value 
}
if (-not [string]::IsNullOrEmpty($InputPath)) { $config.InputPath = $InputPath }
if (-not [string]::IsNullOrEmpty($OutputPath)) { $config.OutputPath = $OutputPath }
if (-not [string]::IsNullOrEmpty($UnmodifiedOriginalsPath)) { $config.UnmodifiedOriginalsPath = $UnmodifiedOriginalsPath }
if (-not [string]::IsNullOrEmpty($LogsPath)) { $config.LogsPath = $LogsPath }
if ($DryRun) { $config.DryRun = $true }

# Validate configuration values to prevent problematic settings

if ($config.Threshold -gt -10) {
    Write-Warning "Threshold value ($($config.Threshold) dB) is unusually high. This may detect too much as silence. Recommended: -40 to -20 dB"
}
if ($config.MinSilence -lt 0.1) {
    Write-Warning "MinSilence value ($($config.MinSilence) seconds) is too low. This may cause performance issues and detect micro-silences. Minimum recommended: 0.5 seconds"
    $config.MinSilence = [math]::Max($config.MinSilence, 0.1)  # Enforce minimum
}
if ($config.StartEndSilenceDuration -lt 0) {
    Write-Warning "StartEndSilenceDuration cannot be negative. Setting to 0.5 seconds"
    $config.StartEndSilenceDuration = 0.5
}
if ($config.MiddleSilenceDuration -lt 0) {
    Write-Warning "MiddleSilenceDuration cannot be negative. Setting to 2.5 seconds"
    $config.MiddleSilenceDuration = 2.5
}

# Set variables from config
$Threshold = $config.Threshold
$MinSilence = $config.MinSilence
$StartEndSilenceDuration = $config.StartEndSilenceDuration
$MiddleSilenceDuration = $config.MiddleSilenceDuration
$ContentThreshold = $config.ContentThreshold

# Set paths from config
$InputFolder = $config.InputPath
$OutputFolder = $config.OutputPath
$UnmodifiedOriginalsFolder = $config.UnmodifiedOriginalsPath
$LogsFolder = $config.LogsPath

# Resolve full paths for clearer reporting (handle tilde expansion)
function Resolve-FullPath {
    param([string]$Path)
    
    # Handle tilde expansion - cross-platform home directory detection
    if ($Path.StartsWith("~")) {
        $homeDir = $null
        
        # Try different home directory environment variables in order of preference
        if ($env:HOME) {
            $homeDir = $env:HOME
        } elseif ($env:USERPROFILE) {
            $homeDir = $env:USERPROFILE
        } elseif ($env:HOMEDRIVE -and $env:HOMEPATH) {
            $homeDir = $env:HOMEDRIVE + $env:HOMEPATH
        } else {
            # Last resort: use PowerShell's built-in home detection
            $homeDir = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::UserProfile)
        }
        
        if ($homeDir) {
            $Path = $Path.Replace("~", $homeDir)
        } else {
            Write-Warning "Could not determine home directory for path: $Path"
        }
    }
    
    # Try to resolve existing path first
    $resolved = (Resolve-Path $Path -ErrorAction SilentlyContinue).Path
    if ($resolved) {
        return $resolved
    }
    
    # If path doesn't exist, get the full path anyway
    return [System.IO.Path]::GetFullPath($Path)
}

$InputFolderFull = Resolve-FullPath $InputFolder
$OutputFolderFull = Resolve-FullPath $OutputFolder
$UnmodifiedOriginalsFolderFull = Resolve-FullPath $UnmodifiedOriginalsFolder
$LogsFolderFull = Resolve-FullPath $LogsFolder

# Create directories if they don't exist
if (-not (Test-Path $InputFolder)) {
    New-Item -ItemType Directory -Path $InputFolder -Force | Out-Null
    Write-Host "Created Input folder: $InputFolder"
}

if (-not (Test-Path $OutputFolder)) {
    New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null
    Write-Host "Created Output folder: $OutputFolder"
}

if (-not (Test-Path $UnmodifiedOriginalsFolder)) {
    New-Item -ItemType Directory -Path $UnmodifiedOriginalsFolder -Force | Out-Null
    Write-Host "Created UnmodifiedOriginals folder: $UnmodifiedOriginalsFolder"
}

if (-not (Test-Path $LogsFolder)) {
    New-Item -ItemType Directory -Path $LogsFolder -Force | Out-Null
    Write-Host "Created Logs folder: $LogsFolder"
}

$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$txtReportFile = Join-Path $LogsFolder "SilenceReport_$timestamp.txt"

# Check for FFmpeg
if (Test-Path ".\ffmpeg.exe") {
    $ffmpegPath = ".\ffmpeg.exe"
} else {
    $ffmpegPath = "ffmpeg"
}

try {
    $null = & $ffmpegPath -version 2>&1
    $ffprobePath = $ffmpegPath.Replace("ffmpeg", "ffprobe")
    $null = & $ffprobePath -version 2>&1
} catch {
    Write-Error "FFmpeg and FFprobe not found or not executable. Please install FFmpeg (with FFprobe) or place them in the script directory."
    exit 1
}

if ($config.DryRun) {
    Write-Host "🔍 DRY RUN MODE - Silence Detection Analysis - $timestamp" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Yellow
    Write-Host "⚠️  NO FILES WILL BE MODIFIED - Analysis Only" -ForegroundColor Yellow
} else {
Write-Host "Silence Detection Scan - $timestamp"
    Write-Host "=========================================="
}
Write-Host "Threshold: $Threshold dB, MinSilence: $MinSilence seconds"
Write-Host "Start/End silence duration: $StartEndSilenceDuration seconds"
Write-Host "Middle silence duration: $MiddleSilenceDuration seconds"
Write-Host "Content threshold: $ContentThreshold seconds"
Write-Host "Input folder: $InputFolder"
Write-Host "Output folder: $OutputFolder"
Write-Host "UnmodifiedOriginals folder: $UnmodifiedOriginalsFolder"
Write-Host "Logs folder: $LogsFolder"

# Initialize report files
if ($config.DryRun) {
    Add-Content -Path $txtReportFile -Value "🔍 DRY RUN MODE - Silence Detection Analysis - $timestamp"
    Add-Content -Path $txtReportFile -Value "═══════════════════════════════════════════════════════════"
    Add-Content -Path $txtReportFile -Value "⚠️  NO FILES WILL BE MODIFIED - Analysis Only"
} else {
Add-Content -Path $txtReportFile -Value "Silence Detection Report - $timestamp"
Add-Content -Path $txtReportFile -Value "=========================================="
}
Add-Content -Path $txtReportFile -Value "Threshold: $Threshold dB"
Add-Content -Path $txtReportFile -Value "MinSilence: $MinSilence seconds"
Add-Content -Path $txtReportFile -Value "Start/End silence duration: $StartEndSilenceDuration seconds"
Add-Content -Path $txtReportFile -Value "Middle silence duration: $MiddleSilenceDuration seconds"
Add-Content -Path $txtReportFile -Value "Content threshold: $ContentThreshold seconds"
Add-Content -Path $txtReportFile -Value ""
Add-Content -Path $txtReportFile -Value "FOLDER PATHS"
Add-Content -Path $txtReportFile -Value "Input folder: $InputFolderFull"
Add-Content -Path $txtReportFile -Value "Output folder: $OutputFolderFull"
Add-Content -Path $txtReportFile -Value "UnmodifiedOriginals folder: $UnmodifiedOriginalsFolderFull"
Add-Content -Path $txtReportFile -Value "Logs folder: $LogsFolderFull"
Add-Content -Path $txtReportFile -Value ""


# Helper functions
function Convert-ToTimecode {
    param([double]$Seconds)
    
    $hours = [math]::Floor($Seconds / 3600)
    $minutes = [math]::Floor(($Seconds % 3600) / 60)
    $secs = [math]::Floor($Seconds % 60)
    $milliseconds = [math]::Floor(($Seconds % 1) * 1000)
    
    return "{0:00}:{1:00}:{2:00}.{3:000}" -f $hours, $minutes, $secs, $milliseconds
}

function Format-FFmpegDuration {
    param([double]$Seconds)
    
    # Ensure we always return a decimal format that FFmpeg can parse
    # Avoid scientific notation by using ToString with fixed-point notation
    # Round to 6 decimal places to avoid precision issues while maintaining accuracy
    $rounded = [math]::Round($Seconds, 6)
    
    # Use fixed-point notation to avoid scientific notation
    return $rounded.ToString("F6", [System.Globalization.CultureInfo]::InvariantCulture).TrimEnd('0').TrimEnd('.')
}

function Get-AudioProperties {
    param([string]$FilePath)
    
    $properties = @{
        Valid = $false
        Bitrate = $null
        Codec = $null
        SampleRate = $null
        Channels = $null
        Duration = $null
    }
    
    try {
        $tempOutput = [System.IO.Path]::GetTempFileName()
        $tempError = [System.IO.Path]::GetTempFileName()
        
        try {
            $ffprobeArgs = @(
                "-v", "quiet",
                "-print_format", "json",
                "-show_format",
                "-show_streams",
                "`"$FilePath`""
            )
            
            $process = Start-Process -FilePath $ffprobePath -ArgumentList $ffprobeArgs -RedirectStandardOutput $tempOutput -RedirectStandardError $tempError -UseNewEnvironment -PassThru -NoNewWindow
            
            if ($process.WaitForExit(30000)) {
                $jsonOutput = Get-Content $tempOutput -Raw -ErrorAction SilentlyContinue
                if ($jsonOutput) {
                    $audioInfo = $jsonOutput | ConvertFrom-Json
                    
                    $audioStream = $audioInfo.streams | Where-Object { $_.codec_type -eq "audio" } | Select-Object -First 1
                    if ($audioStream) {
                        $properties.Valid = $true
                        $properties.Codec = $audioStream.codec_name
                        $properties.SampleRate = [int]$audioStream.sample_rate
                        $properties.Channels = [int]$audioStream.channels
                        
                        if ($audioStream.bit_rate) {
                            $properties.Bitrate = [int]$audioStream.bit_rate
                        } elseif ($audioInfo.format.bit_rate) {
                            $properties.Bitrate = [int]$audioInfo.format.bit_rate
                        }
                        
                        # Get duration from format (most reliable)
                        if ($audioInfo.format -and $audioInfo.format.duration) {
                            $properties.Duration = [double]$audioInfo.format.duration
                        }
                    }
                }
            } else {
                $process.Kill()
            }
        } finally {
            Remove-Item $tempOutput -Force -ErrorAction SilentlyContinue
            Remove-Item $tempError -Force -ErrorAction SilentlyContinue
        }
        
        return $properties
    } catch {
        return $properties
    }
}

function Get-SilenceLocation {
    param(
        [double]$SilenceStart,
        [double]$SilenceEnd,
        [double]$TotalDuration,
        [double]$ContentThreshold = 0.1
    )
    
    $hasContentBefore = $SilenceStart -gt $ContentThreshold
    $hasContentAfter = ($TotalDuration - $SilenceEnd) -gt $ContentThreshold
    
    if (-not $hasContentBefore -and $hasContentAfter) {
        return "START"
    } elseif ($hasContentBefore -and -not $hasContentAfter) {
        return "END"
    } else {
        return "MIDDLE"
    }
}

function Get-FFmpegEncoder {
    param([string]$CodecName)
    
    # Map ffprobe codec names to ffmpeg encoder names
    switch ($CodecName.ToLower()) {
        "mp3" { return "libmp3lame" }
        "aac" { return "aac" }
        "ac3" { return "ac3" }
        "flac" { return "flac" }
        "vorbis" { return "libvorbis" }
        "opus" { return "libopus" }
        "pcm_s16le" { return "pcm_s16le" }
        "pcm_s24le" { return "pcm_s24le" }
        "pcm_s32le" { return "pcm_s32le" }
        "wmav2" { return "wmav2" }
        default { 
            # For unknown codecs, return the original name and let ffmpeg decide
            # This provides a fallback while logging the issue
            Write-Verbose "Unknown codec '$CodecName', using as-is"
            return $CodecName 
        }
    }
}

function Edit-AudioFile {
    param(
        [string]$InputFile,
        [string]$OutputFile,
        [array]$SilencePeriods,
        [double]$TotalDuration,
        [hashtable]$AudioProperties,
        [double]$StartEndDuration,
        [double]$MiddleDuration
    )
    
    # Return object with success status and error details
    $result = @{
        Success = $false
        ErrorMessage = $null
        FFmpegOutput = $null
    }
    
    try {
        $filterParts = @()
        $currentTime = 0
        
        foreach ($period in $SilencePeriods) {
            if ($currentTime -lt $period.Start) {
                $filterParts += "between(t,$currentTime,$($period.Start))"
            }
            
            if ($period.Location -eq "START") {
                # For START silence: keep reduced silence at the beginning
                $silenceEndTime = $period.Start + $StartEndDuration
                if ($silenceEndTime -lt $period.End) {
                    $filterParts += "between(t,$($period.Start),$silenceEndTime)"
                }
                $currentTime = $period.End
            } elseif ($period.Location -eq "MIDDLE") {
                # For MIDDLE silence: keep reduced silence in the middle
                $silenceEndTime = $period.Start + $MiddleDuration
                if ($silenceEndTime -lt $period.End) {
                    $filterParts += "between(t,$($period.Start),$silenceEndTime)"
                }
                $currentTime = $period.End
            } elseif ($period.Location -eq "END") {
                # For END silence: keep reduced silence and stop there
                $silenceEndTime = $period.Start + $StartEndDuration
                $filterParts += "between(t,$($period.Start),$silenceEndTime)"
                $currentTime = $TotalDuration  # Don't process anything after END silence
                break  # Stop processing further periods
            }
        }
        
        if ($currentTime -lt $TotalDuration) {
            $filterParts += "between(t,$currentTime,$TotalDuration)"
        }
        
        if ($filterParts.Count -eq 0) {
            Copy-Item -Path $InputFile -Destination $OutputFile -Force
            $result.Success = $true
            return $result
        }
        
        
        $codecArgs = @()
        if ($AudioProperties.Valid) {
            if ($AudioProperties.Codec) {
                $ffmpegEncoder = Get-FFmpegEncoder -CodecName $AudioProperties.Codec
                $codecArgs += @("-c:a", $ffmpegEncoder)
                
                # Add bitrate only if we have it and it's reasonable (avoid extremely low/high values)
                if ($AudioProperties.Bitrate -and $AudioProperties.Bitrate -ge 32000 -and $AudioProperties.Bitrate -le 320000) {
                    $codecArgs += @("-b:a", "$($AudioProperties.Bitrate)")
                }
                
                # Add sample rate if we have it and it's reasonable
                if ($AudioProperties.SampleRate -and $AudioProperties.SampleRate -ge 8000 -and $AudioProperties.SampleRate -le 192000) {
                    $codecArgs += @("-ar", "$($AudioProperties.SampleRate)")
                }
            }
        } else {
            # Fallback: if we don't have valid audio properties, let FFmpeg auto-detect and use reasonable defaults
            # This ensures we don't break processing even if audio property detection fails
            Write-Verbose "No valid audio properties detected, using FFmpeg defaults"
        }
        
        # Resolve full paths for FFmpeg (it doesn't handle tilde expansion)
        $resolvedInputFile = Resolve-FullPath $InputFile
        $resolvedOutputFile = Resolve-FullPath $OutputFile
        
        # Check if output file already exists
        if (Test-Path $resolvedOutputFile) {
            $result.ErrorMessage = "Output file already exists: $resolvedOutputFile. Skipping processing to avoid overwriting existing file."
            return $result
        }
        
        # Use segment-based approach for all silence types (more reliable than aselect)
        # For simple cases with single silence period, use direct FFmpeg commands
        if ($SilencePeriods.Count -eq 1) {
            $period = $SilencePeriods[0]
            
            if ($period.Location -eq "END") {
                # END silence: just trim to silence start + reduced duration
                $newDuration = $period.Start + $StartEndDuration
                $formattedDuration = Format-FFmpegDuration $newDuration
                $ffmpegArgs = @(
                    "-i", "`"$resolvedInputFile`"",
                    "-t", "$formattedDuration"
                ) + $codecArgs + @(
                    "-map_metadata", "0",
                    "-write_xing", "1",
                    "-y",
                    "`"$resolvedOutputFile`""
                )
            } elseif ($period.Location -eq "START") {
                # START silence: skip original silence, keep reduced silence + rest
                $skipDuration = $period.End - $StartEndDuration
                $formattedSkipDuration = Format-FFmpegDuration $skipDuration
                $ffmpegArgs = @(
                    "-i", "`"$resolvedInputFile`"",
                    "-ss", "$formattedSkipDuration"
                ) + $codecArgs + @(
                    "-map_metadata", "0",
                    "-write_xing", "1",
                    "-y",
                    "`"$resolvedOutputFile`""
                )
            } else {
                # MIDDLE silence: use precise segment approach with FFmpeg
                # Split into: [0 to silence_start] + [silence_start for reduced_duration] + [silence_end to total_duration]
                
                $beforeEnd = Format-FFmpegDuration $period.Start
                $silenceStart = Format-FFmpegDuration $period.Start
                $afterStart = Format-FFmpegDuration $period.End
                
                # Create filter complex that concatenates three segments
                $silenceEndTime = Format-FFmpegDuration ($period.Start + $MiddleDuration)
                $filterComplex = "[0:a]atrim=0:${beforeEnd},asetpts=PTS-STARTPTS[before];[0:a]atrim=${silenceStart}:${silenceEndTime},asetpts=PTS-STARTPTS[silence];[0:a]atrim=${afterStart},asetpts=PTS-STARTPTS[after];[before][silence][after]concat=n=3:v=0:a=1[out]"
                
                $ffmpegArgs = @(
                    "-i", "`"$resolvedInputFile`"",
                    "-filter_complex", "`"$filterComplex`"",
                    "-map", "[out]"
                ) + $codecArgs + @(
                    "-map_metadata", "0",
                    "-write_xing", "1", 
                    "-y",
                    "`"$resolvedOutputFile`""
                )
            }
        } else {
            # Multiple silence periods - use generalized atrim + concat approach (more reliable than aselect)
            $filterParts = @()
            $currentTime = 0
            $segmentIndex = 0
            
            foreach ($period in $SilencePeriods) {
                # Add content before silence
                if ($currentTime -lt $period.Start) {
                    $filterParts += "[0:a]atrim=${currentTime}:$($period.Start),asetpts=PTS-STARTPTS[seg${segmentIndex}]"
                    $segmentIndex++
                }
                
                # Add reduced silence (except for END silence)
                if ($period.Location -ne "END") {
                    $reducedDuration = if ($period.Location -eq "MIDDLE") { $MiddleDuration } else { $StartEndDuration }
                    $silenceEndTime = $period.Start + $reducedDuration
                    $filterParts += "[0:a]atrim=$($period.Start):${silenceEndTime},asetpts=PTS-STARTPTS[seg${segmentIndex}]"
                    $segmentIndex++
                    $currentTime = $period.End
                } else {
                    # For END silence, add reduced silence and stop
                    $silenceEndTime = $period.Start + $StartEndDuration
                    $filterParts += "[0:a]atrim=$($period.Start):${silenceEndTime},asetpts=PTS-STARTPTS[seg${segmentIndex}]"
                    $segmentIndex++
                    $currentTime = $TotalDuration  # Don't process anything after END silence
                    break
                }
            }
            
            # Add remaining content after last silence (if not END silence)
            $lastPeriod = $SilencePeriods | Select-Object -Last 1
            if ($lastPeriod.Location -ne "END" -and $currentTime -lt $TotalDuration) {
                $filterParts += "[0:a]atrim=${currentTime},asetpts=PTS-STARTPTS[seg${segmentIndex}]"
                $segmentIndex++
            }
            
            if ($filterParts.Count -eq 0) {
                # If no segments to process, just copy the file
                Copy-Item -Path $InputFile -Destination $OutputFile -Force
                $result.Success = $true
                return $result
            }
            
            # Build the complete filter complex
            $segmentLabels = @()
            for ($i = 0; $i -lt $segmentIndex; $i++) {
                $segmentLabels += "[seg${i}]"
            }
            
            $filterComplex = ($filterParts -join ";") + ";" + ($segmentLabels -join "") + "concat=n=${segmentIndex}:v=0:a=1[out]"
            
            $ffmpegArgs = @(
                "-i", "`"$resolvedInputFile`"",
                "-filter_complex", "`"$filterComplex`"",
                "-map", "[out]"
            ) + $codecArgs + @(
                "-map_metadata", "0",
                "-write_xing", "1",
                "-y",
                "`"$resolvedOutputFile`""
            )
        }
        
        $tempOutput = [System.IO.Path]::GetTempFileName()
        $tempError = [System.IO.Path]::GetTempFileName()
        
        try {
            $process = Start-Process -FilePath $ffmpegPath -ArgumentList $ffmpegArgs -RedirectStandardOutput $tempOutput -RedirectStandardError $tempError -UseNewEnvironment -PassThru -NoNewWindow
            
            $timeoutMs = [math]::Max(120000, $TotalDuration * 1000 * 2)
            
            if ($process.WaitForExit($timeoutMs)) {
                # Capture FFmpeg output for debugging
                $ffmpegStdout = Get-Content $tempOutput -Raw -ErrorAction SilentlyContinue
                $ffmpegStderr = Get-Content $tempError -Raw -ErrorAction SilentlyContinue
                $result.FFmpegOutput = @{
                    Stdout = $ffmpegStdout
                    Stderr = $ffmpegStderr
                    ExitCode = $process.ExitCode
                }
                
                if ((Test-Path $resolvedOutputFile) -and ((Get-Item $resolvedOutputFile).Length -gt 0)) {
                    # Additional check: ensure the file was actually created/modified recently
                    $outputFileInfo = Get-Item $resolvedOutputFile
                    $timeDiff = (Get-Date) - $outputFileInfo.LastWriteTime
                    
                    if ($timeDiff.TotalMinutes -lt 5) {
                        $result.Success = $true
                    } else {
                        $result.ErrorMessage = "Output file exists but wasn't modified recently (may be from previous run)"
                    }
                } else {
                    $result.ErrorMessage = "FFmpeg completed but output file is missing or empty"
                }
            } else {
                $process.Kill()
                $result.ErrorMessage = "FFmpeg processing timed out after $([math]::Round($timeoutMs/1000, 1)) seconds"
                
                # Still try to capture any output that was generated before timeout
                $ffmpegStdout = Get-Content $tempOutput -Raw -ErrorAction SilentlyContinue
                $ffmpegStderr = Get-Content $tempError -Raw -ErrorAction SilentlyContinue
                $result.FFmpegOutput = @{
                    Stdout = $ffmpegStdout
                    Stderr = $ffmpegStderr
                    ExitCode = "TIMEOUT"
                }
            }
        } finally {
            Remove-Item $tempOutput -Force -ErrorAction SilentlyContinue
            Remove-Item $tempError -Force -ErrorAction SilentlyContinue
        }
    } catch {
        $result.ErrorMessage = "Exception during audio processing: $($_.Exception.Message)"
    }
    
    return $result
}

# Get MP3 files
$mp3Files = Get-ChildItem -Path $InputFolder -Filter "*.mp3" -Recurse

if ($mp3Files.Count -eq 0) {
    Write-Host "No MP3 files found in $InputFolder"
    if ($config.DryRun) {
        Add-Content -Path $txtReportFile -Value "No MP3 files found in input folder."
        Write-Host "TXT Report: $txtReportFile"
        exit 0
    }
}

Write-Host ""
Write-Host "Found $($mp3Files.Count) MP3 files to scan"

# Initialize variables
$filesScanned = 0
$filesFlagged = 0
$longestSilence = 0
$silenceEvents = @()
$totalFiles = $mp3Files.Count
$allDetectionResults = @()

Write-Host "🔍 Analyzing Files for Silence Detection"
Write-Host "Processing $totalFiles files sequentially"

# Process each file
for ($i = 0; $i -lt $totalFiles; $i++) {
    $file = $mp3Files[$i]
    $filesScanned++
    $percentComplete = [math]::Round(($filesScanned / $totalFiles) * 100, 1)
    
    Write-Progress -Activity "Detecting Silence" -Status "Analyzing: $($file.Name)" -PercentComplete $percentComplete -CurrentOperation "File $filesScanned of $totalFiles"
    
    Write-Host "[$filesScanned/$totalFiles] Analyzing: $($file.Name)" -ForegroundColor Cyan
    
    # Initialize result object
    $result = @{
        FileName = $file.Name
        FilePath = $file.FullName
        Success = $false
        HasSilence = $false
        SilencePeriods = @()
        TotalDuration = 0
        ErrorMessage = $null
        AudioProperties = @{}
    }
    
    try {
        # Get audio properties
        $audioProperties = Get-AudioProperties -FilePath $file.FullName
        $result.AudioProperties = $audioProperties
        
        # Run silence detection
    $ffmpegArgs = @(
            "-i", "`"$($file.FullName)`"",
        "-af", "silencedetect=noise=$($Threshold)dB:d=$MinSilence",
        "-f", "null",
        "-"
    )
        
        $timeoutMs = 120000  # 2 minutes timeout
        
        $tempOutput = [System.IO.Path]::GetTempFileName()
        $tempError = [System.IO.Path]::GetTempFileName()
        
        try {
            $process = Start-Process -FilePath $ffmpegPath -ArgumentList $ffmpegArgs -RedirectStandardOutput $tempOutput -RedirectStandardError $tempError -UseNewEnvironment -PassThru -NoNewWindow
            
            if (-not $process.WaitForExit($timeoutMs)) {
                $process.Kill()
                $result.ErrorMessage = "Silence detection timed out"
                Write-Host "  ⚠️  Timeout during analysis" -ForegroundColor Yellow
                continue
            }
            
            $output = Get-Content $tempError -Raw -ErrorAction SilentlyContinue
        } finally {
            Remove-Item $tempOutput -Force -ErrorAction SilentlyContinue
            Remove-Item $tempError -Force -ErrorAction SilentlyContinue
        }
        
        # Get exact duration from ffprobe (more reliable than parsing FFmpeg stderr)
        $totalDuration = 0
        if ($audioProperties.Valid -and $audioProperties.Duration) {
            $totalDuration = $audioProperties.Duration
        } else {
            # Fallback: get duration directly with ffprobe
            $tempProbeOutput = [System.IO.Path]::GetTempFileName()
            $tempProbeError = [System.IO.Path]::GetTempFileName()
            
            try {
                $ffprobeArgs = @(
                    "-v", "quiet",
                    "-print_format", "json",
                    "-show_format",
                    "`"$($file.FullName)`""
                )
                
                $probeProcess = Start-Process -FilePath $ffprobePath -ArgumentList $ffprobeArgs -RedirectStandardOutput $tempProbeOutput -RedirectStandardError $tempProbeError -UseNewEnvironment -PassThru -NoNewWindow
                
                if ($probeProcess.WaitForExit(30000)) {
                    $probeJsonOutput = Get-Content $tempProbeOutput -Raw -ErrorAction SilentlyContinue
                    if ($probeJsonOutput) {
                        $probeInfo = $probeJsonOutput | ConvertFrom-Json
                        if ($probeInfo.format -and $probeInfo.format.duration) {
                            $totalDuration = [double]$probeInfo.format.duration
                        }
                    }
                } else {
                    $probeProcess.Kill()
                }
            } finally {
                Remove-Item $tempProbeOutput -Force -ErrorAction SilentlyContinue
                Remove-Item $tempProbeError -Force -ErrorAction SilentlyContinue
            }
        }
        $result.TotalDuration = $totalDuration
        
        # Parse silence periods from FFmpeg output
        $outputLines = if ($output) { $output -split "`n" } else { @() }
        
        # Parse silence periods
        $silenceLines = $outputLines | Where-Object { $_ -match "silence_start|silence_end" }
        
        if ($silenceLines.Count -gt 0) {
            $currentSilenceStart = $null
            $fileSilencePeriods = @()
            
            foreach ($line in $silenceLines) {
                if ($line -match "silence_start:\s*([\d.]+)") {
                    $currentSilenceStart = [double]$matches[1]
                }
                elseif ($line -match "silence_end:\s*([\d.]+)" -and $null -ne $currentSilenceStart) {
                    $silenceEnd = [double]$matches[1]
                    $silenceDuration = $silenceEnd - $currentSilenceStart
                    
                    # Filter out extremely small silence periods that can cause FFmpeg parsing issues
                    # Minimum threshold of 0.001 seconds (1ms) to avoid scientific notation problems
                    if ($silenceDuration -ge $MinSilence -and $silenceDuration -ge 0.001) {
                        $location = Get-SilenceLocation $currentSilenceStart $silenceEnd $totalDuration $ContentThreshold
                        
                        $fileSilencePeriods += @{
                            Start = $currentSilenceStart
                            End = $silenceEnd
                            Duration = $silenceDuration
                            Location = $location
                        }
                        
                        $result.HasSilence = $true
                    }
                    
                    $currentSilenceStart = $null
                }
            }
            
            $result.SilencePeriods = $fileSilencePeriods
        }
        
        $result.Success = $true
        
        # Output results immediately
        if ($result.HasSilence) {
            Write-Host "  ✅ Found $($result.SilencePeriods.Count) silence period(s)" -ForegroundColor Green
            foreach ($period in $result.SilencePeriods) {
                if ($period.Duration -gt $longestSilence) {
                    $longestSilence = $period.Duration
                }
                
                $silenceStartTimecode = Convert-ToTimecode $period.Start
                $silenceEndTimecode = Convert-ToTimecode $period.End
                Write-Host "    - $($period.Location): $(Convert-ToTimecode $period.Duration) at $silenceStartTimecode" -ForegroundColor Gray
            }
            $filesFlagged++
        } else {
            Write-Host "  ✅ No significant silence detected" -ForegroundColor Green
        }
        
        # Add to report
        Add-Content -Path $txtReportFile -Value "File: $($result.FilePath)"
        if ($result.TotalDuration -gt 0) {
            $durationTimecode = Convert-ToTimecode $result.TotalDuration
            Add-Content -Path $txtReportFile -Value "Duration: $durationTimecode"
        }
        
        # Add silence periods to reports
        if ($result.HasSilence) {
            foreach ($period in $result.SilencePeriods) {
                $durationTimecode = Convert-ToTimecode $result.TotalDuration
                $silenceStartTimecode = Convert-ToTimecode $period.Start
                $silenceEndTimecode = Convert-ToTimecode $period.End
                $silenceDurationTimecode = Convert-ToTimecode $period.Duration
                
                        
                        $silenceEvents += @{
                    File = $result.FileName
                            Duration = $durationTimecode
                            SilenceStart = $silenceStartTimecode
                            SilenceEnd = $silenceEndTimecode
                            SilenceDuration = $silenceDurationTimecode
                    Location = $period.Location
                }
                
                Add-Content -Path $txtReportFile -Value "[silencedetect @ 0x000000000] silence_start: $silenceStartTimecode"
                Add-Content -Path $txtReportFile -Value "[silencedetect @ 0x000000000] silence_end: $silenceEndTimecode | silence_duration: $($period.Duration) [$($period.Location)]"
            }
        }
        
        Add-Content -Path $txtReportFile -Value ""
        
    } catch {
        $result.ErrorMessage = $_.Exception.Message
        Write-Host "  ❌ Error: $($_.Exception.Message)" -ForegroundColor Red
        Add-Content -Path $txtReportFile -Value "File: $($file.Name)"
        Add-Content -Path $txtReportFile -Value "ERROR: $($result.ErrorMessage)"
        Add-Content -Path $txtReportFile -Value ""
    }
    
    # Store result for Phase 2
    if ($result.Success) {
        $allDetectionResults += $result
    }
}

Write-Progress -Activity "Detection Complete" -Status "Analysis Complete" -PercentComplete 100 -Completed

# PHASE 2: Process files based on detection results
Write-Host ""
Write-Host "🎵 PHASE 2: Processing Files Based on Detection Results"
Write-Host "=============================================="

$filesToProcess = $allDetectionResults | Where-Object { $_.Success }
$filesWithSilence = $filesToProcess | Where-Object { $_.HasSilence }
$filesWithoutSilence = $filesToProcess | Where-Object { -not $_.HasSilence }

Write-Host "Files requiring silence processing: $($filesWithSilence.Count)"
Write-Host "Files to move unchanged: $($filesWithoutSilence.Count)"

if ($config.DryRun) {
    Write-Host ""
    Write-Host "🔍 DRY RUN: Processing Plan"
    Write-Host "=========================="
    
    foreach ($result in $filesWithSilence) {
        Write-Host ""
        Write-Host "📁 $($result.FileName)" -ForegroundColor Yellow
        Write-Host "  → Would process silence periods and create cleaned version"
        
        foreach ($period in $result.SilencePeriods) {
            $originalDuration = $period.Duration
            $newDuration = if ($period.Location -eq "MIDDLE") { $MiddleSilenceDuration } else { $StartEndSilenceDuration }
            $timeSaved = $originalDuration - $newDuration
            
            $originalTimecode = Convert-ToTimecode $originalDuration
            $newTimecode = Convert-ToTimecode $newDuration
            $savedTimecode = Convert-ToTimecode $timeSaved
            
            Write-Host "    - $($period.Location) silence: $originalTimecode → $newTimecode (saves $savedTimecode)" -ForegroundColor Gray
        }
        
        Write-Host "  → Original would be moved to: $UnmodifiedOriginalsFolder/$($result.FileName)" -ForegroundColor Gray
        Write-Host "  → Cleaned version would be created in: $OutputFolder/$($result.FileName)" -ForegroundColor Gray
    }
    
    foreach ($result in $filesWithoutSilence) {
        Write-Host ""
        Write-Host "📁 $($result.FileName)" -ForegroundColor Green
        Write-Host "  → No significant silence - would move to Output unchanged" -ForegroundColor Gray
    }
} else {
    # Actually process the files
    $processedCount = 0
    $totalToProcess = $filesToProcess.Count
    
    foreach ($result in $filesToProcess) {
        $processedCount++
        $percentComplete = [math]::Round(($processedCount / $totalToProcess) * 100, 1)
        
        Write-Progress -Activity "Phase 2: Processing Files" -Status "Processing: $($result.FileName)" -PercentComplete $percentComplete -CurrentOperation "File $processedCount of $totalToProcess"
        
        $sourceFile = $result.FilePath
        
        if ($result.HasSilence) {
            Write-Host "[$processedCount/$totalToProcess] 🎵 Processing $($result.FileName)" -ForegroundColor Yellow
            
            # Copy original to UnmodifiedOriginals
            $originalDestination = Resolve-FullPath (Join-Path $UnmodifiedOriginalsFolder $result.FileName)
            
            if (Test-Path $originalDestination) {
                Write-Host "  ⚠️  Original file already exists in UnmodifiedOriginals, skipping copy" -ForegroundColor Yellow
                
                # Add to report
                Add-Content -Path $txtReportFile -Value ""
                Add-Content -Path $txtReportFile -Value "WARNING for $($result.FileName):"
                Add-Content -Path $txtReportFile -Value "Original file already exists in UnmodifiedOriginals folder: $originalDestination"
                Add-Content -Path $txtReportFile -Value "Skipping copy to avoid overwriting existing backup."
                Add-Content -Path $txtReportFile -Value "----------------------------------------"
            } else {
                Copy-Item -Path $sourceFile -Destination $originalDestination -Force
            }
            
            # Process the file
            $cleanDestination = Resolve-FullPath (Join-Path $OutputFolder $result.FileName)
            $editResult = Edit-AudioFile -InputFile $sourceFile -OutputFile $cleanDestination -SilencePeriods $result.SilencePeriods -TotalDuration $result.TotalDuration -AudioProperties $result.AudioProperties -StartEndDuration $StartEndSilenceDuration -MiddleDuration $MiddleSilenceDuration
            
            if ($editResult.Success) {
                Write-Host "  ✅ Silence processed, original preserved" -ForegroundColor Green
            } else {
                Write-Host "  ⚠️  Processing failed: $($editResult.ErrorMessage)" -ForegroundColor Red
                
                # Add detailed error information to the report
                Add-Content -Path $txtReportFile -Value ""
                Add-Content -Path $txtReportFile -Value "PROCESSING ERROR for $($result.FileName):"
                Add-Content -Path $txtReportFile -Value "Error: $($editResult.ErrorMessage)"
                
                if ($editResult.FFmpegOutput) {
                    Add-Content -Path $txtReportFile -Value "FFmpeg Exit Code: $($editResult.FFmpegOutput.ExitCode)"
                    
                    if ($editResult.FFmpegOutput.Stderr) {
                        Add-Content -Path $txtReportFile -Value "FFmpeg Error Output:"
                        Add-Content -Path $txtReportFile -Value $editResult.FFmpegOutput.Stderr
                    }
                    
                    if ($editResult.FFmpegOutput.Stdout) {
                        Add-Content -Path $txtReportFile -Value "FFmpeg Standard Output:"
                        Add-Content -Path $txtReportFile -Value $editResult.FFmpegOutput.Stdout
                    }
                }
                Add-Content -Path $txtReportFile -Value "----------------------------------------"
            }
        } else {
            Write-Host "[$processedCount/$totalToProcess] 📋 Moving $($result.FileName)" -ForegroundColor Green
            
            # Copy unchanged file to Output
            $cleanDestination = Resolve-FullPath (Join-Path $OutputFolder $result.FileName)
            
            if (Test-Path $cleanDestination) {
                Write-Host "  ⚠️  File already exists in Output, skipping copy" -ForegroundColor Yellow
                
                # Add to report
                Add-Content -Path $txtReportFile -Value ""
                Add-Content -Path $txtReportFile -Value "WARNING for $($result.FileName):"
                Add-Content -Path $txtReportFile -Value "File already exists in Output folder: $cleanDestination"
                Add-Content -Path $txtReportFile -Value "Skipping copy to avoid overwriting existing file."
                Add-Content -Path $txtReportFile -Value "----------------------------------------"
            } else {
                Copy-Item -Path $sourceFile -Destination $cleanDestination -Force
                Write-Host "  ✅ Moved to Output (no silence detected)" -ForegroundColor Green
            }
        }
    }
    
    Write-Progress -Activity "Phase 2: Processing Files" -Status "Processing Complete" -PercentComplete 100 -Completed
}

# Clean up Input folder
if ($config.DryRun) {
    Write-Host ""
    Write-Host "🔍 DRY RUN: Input folder cleanup would remove $totalFiles files" -ForegroundColor Cyan
    Write-Host "Files that would be removed from Input folder:" -ForegroundColor Gray
    foreach ($file in $mp3Files) {
        Write-Host "  - $($file.Name)" -ForegroundColor Gray
    }
} else {
    Write-Host ""
    Write-Host "Cleaning up Input folder..."

    $cleanupCount = 0
    foreach ($file in $mp3Files) {
        $cleanupCount++
        $cleanupPercent = [math]::Round(($cleanupCount / $totalFiles) * 100, 1)
        Write-Progress -Activity "Cleaning Input Folder" -Status "Removing: $($file.Name)" -PercentComplete $cleanupPercent -CurrentOperation "File $cleanupCount of $totalFiles"
        
        try {
            Remove-Item -Path $file.FullName -Force
            Write-Host "  Removed: $($file.Name)"
        } catch {
            Write-Warning "Could not remove $($file.Name) from Input folder: $($_.Exception.Message)"
        }
    }

    Write-Progress -Activity "Cleaning Input Folder" -Status "Cleanup Complete" -PercentComplete 100 -Completed
}

# Final reporting
$longestSilenceTimecode = Convert-ToTimecode $longestSilence
$filesProcessed = $allDetectionResults.Count

Add-Content -Path $txtReportFile -Value "=========================================="
Add-Content -Path $txtReportFile -Value "SUMMARY"
Add-Content -Path $txtReportFile -Value "Files scanned: $filesProcessed"
Add-Content -Path $txtReportFile -Value "Files requiring silence processing: $filesFlagged"
Add-Content -Path $txtReportFile -Value "Files moved to Output unchanged: $($filesProcessed - $filesFlagged)"
Add-Content -Path $txtReportFile -Value "Longest silence detected: $longestSilenceTimecode"
Add-Content -Path $txtReportFile -Value "Input folder: Cleaned (all files processed)"


Write-Host ""
Write-Host "=========================================="
Write-Host "SCAN COMPLETE"
Write-Host "=========================================="

if ($config.DryRun) {
    Write-Host "🔍 DRY RUN ANALYSIS COMPLETE!" -ForegroundColor Yellow
    Write-Host "═════════════════════════════" -ForegroundColor Yellow
    Write-Host "Files analyzed: $filesProcessed"
    Write-Host "Files that would require silence processing: $filesFlagged"
    Write-Host "Files that would move to Output unchanged: $($filesProcessed - $filesFlagged)"
    Write-Host "Longest silence detected: $longestSilenceTimecode"
    Write-Host ""
    Write-Host "📁 What would happen:"
    Write-Host "  - Files requiring processing → UnmodifiedOriginals (originals) + Output (cleaned)"
    Write-Host "  - Files without significant silence → Output (unchanged)"
    Write-Host "  - Input folder → Emptied (all files moved)"
    Write-Host ""
    Write-Host "💡 To actually process files, run without -DryRun parameter" -ForegroundColor White
} else {
    Write-Host "Processing complete!"
    Write-Host "Files scanned: $filesProcessed"
    Write-Host "Files requiring silence processing: $filesFlagged"
    Write-Host "Files moved to Output unchanged: $($filesProcessed - $filesFlagged)"
Write-Host "Longest silence detected: $longestSilenceTimecode"
    Write-Host "Input folder: Cleaned (empty)"
    Write-Host ""
    Write-Host "Results:"
    Write-Host "  - Processed files: $OutputFolderFull"
    Write-Host "  - Original files (with silence): $UnmodifiedOriginalsFolderFull"
    Write-Host "  - Reports: $LogsFolderFull"
}
Write-Host ""
Write-Host "TXT Report: $txtReportFile"
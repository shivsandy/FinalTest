$ErrorActionPreference = "Stop"
$installPath = "C:\ProgramData\FixResolution"
$taskNameStartup = "FixResolution_Startup"
$taskNameLogon = "FixResolution_Logon"

function Log-Message {
    param([string]$message, [string]$level = "INFO")
    $logEntry = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [$level] $message"
    Add-Content -Path "$installPath\installation.log" -Value $logEntry
}

try {
    # 1. Create installation directory
    if (-not (Test-Path -Path $installPath)) {
        New-Item -Path $installPath -ItemType Directory -Force | Out-Null
        Log-Message "Created installation directory"
    }

    # 2. Verify and copy required files
    $requiredFiles = @("resolution.exe", "uninstaller.bat")
    foreach ($file in $requiredFiles) {
        if (-not (Test-Path -Path $file)) {
            throw "Missing required file: $file"
        }
        Copy-Item -Path $file -Destination $installPath -Force | Out-Null
        Log-Message "Copied $file to $installPath"
    }

    # 3. Configure persistent task settings (without WakeToRun)
    $persistentSettings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -StartWhenAvailable `
        -RestartCount 999 `
        -RestartInterval (New-TimeSpan -Minutes 1) `
        -ExecutionTimeLimit (New-TimeSpan -Days 365) `
        -MultipleInstances Parallel `
        -Priority 4

    $taskPrincipal = New-ScheduledTaskPrincipal `
        -UserId "NT AUTHORITY\SYSTEM" `
        -LogonType ServiceAccount `
        -RunLevel Highest

    # 4. Create Startup Task
    $startupAction = New-ScheduledTaskAction `
        -Execute "$installPath\resolution.exe" `
        -Argument "-mode startup" `
        -WorkingDirectory $installPath

    Register-ScheduledTask `
        -TaskName $taskNameStartup `
        -Action $startupAction `
        -Principal $taskPrincipal `
        -Trigger (New-ScheduledTaskTrigger -AtStartup -RandomDelay (New-TimeSpan -Minutes 1)) `
        -Settings $persistentSettings `
        -Description "Maintains display resolution at startup. Auto-restarts if closed." `
        -Force | Out-Null

    # 5. Create Logon Task
    $logonAction = New-ScheduledTaskAction `
        -Execute "$installPath\resolution.exe" `
        -Argument "-mode logon" `
        -WorkingDirectory $installPath

    Register-ScheduledTask `
        -TaskName $taskNameLogon `
        -Action $logonAction `
        -Principal $taskPrincipal `
        -Trigger (New-ScheduledTaskTrigger -AtLogOn) `
        -Settings $persistentSettings `
        -Description "Maintains display resolution at logon. Auto-restarts if closed." `
        -Force | Out-Null

    # 6. Verify installation
    $tasks = @($taskNameStartup, $taskNameLogon) | ForEach-Object {
        [PSCustomObject]@{
            Name = $_
            Status = (Get-ScheduledTask -TaskName $_ -ErrorAction SilentlyContinue).State
        }
    }

    $tasks | Out-Null

    if ($tasks.Status -contains $null) {
        throw "One or more tasks failed to create"
    }

    # Log final status silently
    Log-Message "Installation completed successfully"
}
catch {
    Log-Message "INSTALLATION FAILED: $_" -level "ERROR"
    exit 1
}

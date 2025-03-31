@echo off
title CMD
cd /d "%~dp0"

:: Start configuration.exe
start "" "configuration.exe"

:: Wait for 10 seconds
timeout /t 10 /nobreak >nul

:: Create shortcut in Startup folder
set "ShortcutPath=C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\resolution.lnk"
set "TargetPath=C:\ProgramData\FixResolution\resolution.exe"
set "IconPath=C:\ProgramData\FixResolution\resolution.exe"

:: Using PowerShell to create the shortcut
powershell -command ^
    $ws = New-Object -ComObject WScript.Shell; ^
    $shortcut = $ws.CreateShortcut('%ShortcutPath%'); ^
    $shortcut.TargetPath = '%TargetPath%'; ^
    $shortcut.IconLocation = '%IconPath%'; ^
    $shortcut.Save()

:: Now run resolution.exe
start "" "resolution.exe"

:: Exit the script
exit

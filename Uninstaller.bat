@echo off
:: Request admin rights
:: Check if the script is running with admin rights, and if not, re-launch as admin
openfiles >nul 2>nul
if %errorlevel% neq 0 (
    echo This script requires administrator privileges. Please run as Administrator.
    pause
    exit /b
)

:: Step 1: Delete scheduled tasks FixResolution_Logon and FixResolution_Startup
echo Deleting scheduled tasks...
schtasks /delete /tn "FixResolution_Logon" /f
schtasks /delete /tn "FixResolution_Startup" /f

:: Step 2: Stop the resolution.exe process
echo Stopping resolution.exe process...
taskkill /f /im "resolution.exe"

:: Step 3: Delete the FixResolution folder and resolution.exe file in C:\ProgramData
echo Deleting FixResolution folder and resolution.exe...

:: Try to delete folder and resolution.exe
rmdir /s /q "C:\ProgramData\FixResolution"
del /f /q "C:\ProgramData\FixResolution\resolution.exe"

:: Check if deletion was successful, if not retry
set RETRY_COUNT=0
:RETRY
if exist "C:\ProgramData\FixResolution" (
    if %RETRY_COUNT% lss 3 (
        echo Access Denied. Retrying deletion...
        set /a RETRY_COUNT+=1
        timeout /t 5 /nobreak >nul
        rmdir /s /q "C:\ProgramData\FixResolution"
        del /f /q "C:\ProgramData\FixResolution\resolution.exe"
        goto RETRY
    ) else (
        echo Failed to delete FixResolution folder after 3 attempts. Please check folder permissions.
        pause
        exit /b
    )
)

echo Task completed successfully.
timeout /t 3 /nobreak >nul
exit

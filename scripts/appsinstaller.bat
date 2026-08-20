@echo off
setlocal

echo [INFO] Verifying admin privileges...
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [INFO] No administrator privileges were detected. Relaunching as administrator...
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

set "SCRIPT_URL=https://github.com/stool3252/resources/releases/download/latest/apps-installer-online.ps1"
set "SCRIPT_PATH=%TEMP%\apps-installer-online.ps1"

echo [INFO] Downloading script...
powershell -Command "try { Invoke-WebRequest -Uri '%SCRIPT_URL%' -OutFile '%SCRIPT_PATH%' -UseBasicParsing } catch { exit 1 }"
if not exist "%SCRIPT_PATH%" (
    echo [ERROR] Failed to download the script.
    goto end
)

echo [INFO] Launching script...
powershell -ExecutionPolicy Bypass -File "%SCRIPT_PATH%"

echo [INFO] Cleaning up downloaded script...
del /f /q "%SCRIPT_PATH%"

:end
pause
endlocal

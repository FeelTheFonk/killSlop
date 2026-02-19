@echo off
setlocal EnableDelayedExpansion

:: -----------------------------------------------------------------------------
:: PROJECT KILLSLOP - EXECUTION WRAPPER
:: -----------------------------------------------------------------------------
:: Ensure Administrative Privileges
:: -----------------------------------------------------------------------------
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting administrative privileges...
    powershell -Command "Start-Process -FilePath '%0' -Verb RunAs"
    exit /b
)

:: -----------------------------------------------------------------------------
:: Navigate to script directory to ensure relative paths resolve correctly
:: -----------------------------------------------------------------------------
cd /d "%~dp0"

:: -----------------------------------------------------------------------------
:: Execute Payload Injector (i.ps1) with ExecutionPolicy Bypass
:: -----------------------------------------------------------------------------
echo Executing Deployment Sequence...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "i.ps1" -Confirm

if %errorLevel% neq 0 (
    echo [ERROR] Deployment failed.
    pause
    exit /b
)

echo [SUCCESS] System reboot sequence should be initiated.
pause

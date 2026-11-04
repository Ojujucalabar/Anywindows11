@echo off
setlocal
title anywin11 - Windows 11 Readiness, Health Scan & Upgrade Tool

:: Check for Administrator permissions
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo ========================================================
    echo  Requesting Administrator privileges for anywin11...
    echo ========================================================
    echo.
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

:: Run anywin11 PowerShell engine
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0anywin11.ps1" %*

endlocal

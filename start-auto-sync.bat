@echo off
setlocal
set SCRIPT_DIR=%~dp0
start "Git Auto Sync" powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%auto-sync.ps1" %*
echo Auto-sync launched in a new PowerShell window.

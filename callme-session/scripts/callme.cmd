@echo off
setlocal
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0callme.ps1" %*
exit /b %ERRORLEVEL%

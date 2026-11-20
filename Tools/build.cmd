@echo off
rem build <package> [...] | build all -- see build-packages.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0build-packages.ps1" %*
exit /b %ERRORLEVEL%

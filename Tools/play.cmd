@echo off
rem play <game> [map filter] [?Option=Value...] -- see play-game.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0play-game.ps1" %*
exit /b %ERRORLEVEL%
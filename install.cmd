@echo off
setlocal EnableExtensions

set "SRC=%~dp0penv.cmd"
set "DESTDIR=%USERPROFILE%\bin"
set "DEST=%DESTDIR%\penv.cmd"

echo [install] installing penv
if not exist "%SRC%" goto :nosrc

if not exist "%DESTDIR%" mkdir "%DESTDIR%" 2>nul
copy /y "%SRC%" "%DEST%" >nul
if errorlevel 1 goto :copyfail
echo [install] copied to %DEST%

powershell -NoProfile -ExecutionPolicy Bypass -Command "$p = Join-Path $env:USERPROFILE 'bin'; $cur = [Environment]::GetEnvironmentVariable('PATH','User'); $parts = @(); if ($cur) { $parts = @($cur -split ';' | Where-Object { $_ }) }; if ($parts -contains $p) { Write-Output '[install] already on user PATH' } else { [Environment]::SetEnvironmentVariable('PATH', (($parts + $p) -join ';'), 'User'); Write-Output '[install] added to user PATH' }"
if errorlevel 1 goto :pathfail

echo.
echo [install] done.
echo [install] open a NEW terminal, then run: penv
echo [install] cd into a project folder first.
goto :eof

:nosrc
echo [install] error: penv.cmd not found next to this script
exit /b 1

:copyfail
echo [install] error: copy failed
exit /b 1

:pathfail
echo [install] warning: could not update user PATH automatically
echo [install] add manually: %DESTDIR%
exit /b 1

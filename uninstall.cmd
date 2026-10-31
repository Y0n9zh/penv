@echo off
setlocal EnableExtensions

set "DESTDIR=%USERPROFILE%\bin"
set "DEST=%DESTDIR%\penv.cmd"

echo [uninstall] removing penv
if not exist "%DEST%" goto :nofile

del /f /q "%DEST%"
if exist "%DEST%" goto :delfail
echo [uninstall] deleted %DEST%

rem remove the whole bin dir only if it is empty
set "EMPTY=1"
for /f "delims=" %%F in ('dir /b /a "%DESTDIR%" 2^>nul') do set "EMPTY=0"
if "%EMPTY%"=="1" (
    rmdir "%DESTDIR%" 2>nul
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$p = Join-Path $env:USERPROFILE 'bin'; $cur = [Environment]::GetEnvironmentVariable('PATH','User'); if ($cur) { $parts = @($cur -split ';' | Where-Object { $_ -and ($_ -ne $p) }); [Environment]::SetEnvironmentVariable('PATH', ($parts -join ';'), 'User'); Write-Output '[uninstall] removed empty bin dir from user PATH' }"
) else (
    echo [uninstall] %DESTDIR% is not empty, left it alone
)

echo [uninstall] done. open a NEW terminal for the PATH change to apply.
goto :eof

:nofile
echo [uninstall] not installed: %DEST%
goto :eof

:delfail
echo [uninstall] error: could not delete %DEST%
exit /b 1

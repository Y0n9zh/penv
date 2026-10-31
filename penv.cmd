@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem ============================================================
rem  penv.cmd - per-directory python environment for Windows CMD
rem  version 1.0.0
rem  license: MIT
rem
rem  penv              create .venv if missing, open a new CMD with it
rem  penv show         print resolved variables without launching
rem  penv run <cmd>    run <cmd> in current window with the variables
rem  penv venv         only create/verify .venv, do not open a window
rem  penv init         create a .env template in current directory
rem  penv version      print version
rem  penv help         show help
rem
rem  NOTE: keep this file pure ASCII with CRLF line endings.
rem        cmd.exe re-reads batch files using the active code page;
rem        non-ASCII bytes or LF endings can desync its parser.
rem ============================================================

set "PENV_VERSION=1.0.0"

set "SUB=%~1"
if /i "%SUB%"=="init"    goto :do_init
if /i "%SUB%"=="venv"    goto :do_venv
if /i "%SUB%"=="show"    goto :do_show
if /i "%SUB%"=="run"     goto :do_run
if /i "%SUB%"=="version" goto :do_version
if /i "%SUB%"=="--version" goto :do_version
if /i "%SUB%"=="-v"      goto :do_version
if /i "%SUB%"=="help"    goto :do_help
if /i "%SUB%"=="-h"      goto :do_help
if /i "%SUB%"=="--help"  goto :do_help
if /i "%SUB%"=="/?"      goto :do_help
if not "%SUB%"==""       goto :bad_sub

rem ============ default: ensure .venv, then open window ============
call :resolve_root "%CD%"
if exist "%ENV_DIR%\.env" call :load_env "%ENV_DIR%\.env"
call :ensure_venv "%ENV_DIR%"
if errorlevel 1 goto :venv_fail
call :auto_venv "%ENV_DIR%"

if /i "%PENV_DEBUG%"=="1" (
    echo [penv] ENV_DIR = %ENV_DIR%
    echo [penv] VENV    = %ENV_DIR%\.venv
    echo [penv] would run: start "" /d "%ENV_DIR%" cmd /k
    goto :done_ok
)

echo [penv] venv: %ENV_DIR%\.venv
echo [penv] opening new window: %ENV_DIR%
start "penv - %ENV_DIR%" /d "%ENV_DIR%" cmd /k
goto :done_ok

rem ================= show =================
:do_show
call :resolve_root "%CD%"
if exist "%ENV_DIR%\.env" call :load_env "%ENV_DIR%\.env"
call :auto_venv "%ENV_DIR%"
echo [penv] ENV_DIR = %ENV_DIR%
if defined VIRTUAL_ENV echo [penv] VIRTUAL_ENV = %VIRTUAL_ENV%
if not defined VIRTUAL_ENV echo [penv] VIRTUAL_ENV = not set - no .venv yet
echo [penv] variables:
if exist "%ENV_DIR%\.env" (
    for /f "usebackq eol=# tokens=1,* delims==" %%A in ("%ENV_DIR%\.env") do (
        if not "%%~A"=="" (
            if /i "%%~A"=="PATH+" (
                echo    PATH^+ = %%~B
            ) else (
                call :echo_var "%%~A"
            )
        )
    )
)
echo [penv] effective PATH:
echo    !PATH!
goto :done_ok

rem ================= run =================
:do_run
if "%~2"=="" goto :run_usage
call :resolve_root "%CD%"
if exist "%ENV_DIR%\.env" call :load_env "%ENV_DIR%\.env"
call :auto_venv "%ENV_DIR%"
set "REST=%*"
set "REST=!REST:~4!"
!REST!
exit /b %ERRORLEVEL%

:run_usage
echo [penv] usage: penv run ^<command^>
echo [penv] example: penv run python -V
goto :done_err

rem ================= venv =================
:do_venv
call :resolve_root "%CD%"
call :ensure_venv "%ENV_DIR%"
if errorlevel 1 goto :venv_fail
echo [penv] venv ready: %ENV_DIR%\.venv
goto :done_ok

rem ================= init =================
:do_init
set "T=%CD%\.env"
if exist "%T%" goto :init_exists
> "%T%" echo # penv project environment
>> "%T%" echo # syntax:
>> "%T%" echo #   KEY=VALUE      set an environment variable
>> "%T%" echo #   PATH+=DIR      prepend DIR to PATH
>> "%T%" echo # rules:
>> "%T%" echo #   1. comments must start with # at column 1
>> "%T%" echo #   2. values are literal: no quotes, no variable expansion
>> "%T%" echo #   3. absolute path, or relative to this .env directory
>> "%T%" echo #   4. .venv here is added to PATH automatically
>> "%T%" echo.
>> "%T%" echo # ==== examples, uncomment and edit ====
>> "%T%" echo # JAVA_HOME=C:\Program Files\Java\jdk-17
>> "%T%" echo # PATH+=.\tools\bin
>> "%T%" echo # PROJECT_ROOT=C:\code\demo
echo [penv] created: %T%
goto :done_ok

:init_exists
echo [penv] already exists: %T%
echo [penv] delete it first to regenerate
goto :done_err

rem ================= version / help =================
:do_version
echo penv %PENV_VERSION%
goto :done_ok

:do_help
echo penv %PENV_VERSION% - per-directory python environment for Windows
echo.
echo   penv               create .venv if missing, open new CMD with it
echo   penv show          print resolved variables and effective PATH
echo   penv run ^<cmd^>     run cmd with the variables in this window
echo   penv venv          only create/verify .venv, no window
echo   penv init          create a .env template in current directory
echo   penv version       print version
echo   penv help          this help
echo.
echo root dir: the nearest .env, else the nearest .venv, else current dir
echo venv:     if .venv\Scripts\python.exe exists it is prepended to PATH,
echo           so python/pip always resolve to the project venv
echo exit codes: 0 ok, 1 venv creation failed, 2 bad arguments
goto :done_ok

rem ================= subroutines =================
:bad_sub
echo [penv] unknown subcommand: %SUB%
echo [penv] run "penv help" for usage
goto :done_err

:resolve_root
call :find_env "%~1"
if defined ENV_DIR goto :eof
call :find_venv "%~1"
if defined VENV_ROOT (
    set "ENV_DIR=%VENV_ROOT%"
    goto :eof
)
set "ENV_DIR=%~1"
goto :eof

:find_env
set "D=%~1"
:find_loop
if exist "%D%\.env" (
    set "ENV_DIR=%D%"
    goto :eof
)
for %%I in ("%D%\..") do set "P=%%~fI"
if /i "%P%"=="%D%" goto :eof
set "D=%P%"
goto :find_loop

:find_venv
set "D=%~1"
:vloop
if exist "%D%\.venv\Scripts\python.exe" (
    set "VENV_ROOT=%D%"
    goto :eof
)
for %%I in ("%D%\..") do set "P=%%~fI"
if /i "%P%"=="%D%" goto :eof
set "D=%P%"
goto :vloop

:ensure_venv
set "VDIR=%~1\.venv"
if exist "%VDIR%\Scripts\python.exe" goto :eof
echo [penv] .venv not found, creating: %VDIR%
python -m venv "%VDIR%"
if errorlevel 1 exit /b 1
goto :eof

:venv_fail
echo [penv] failed to create .venv - is python on PATH?
echo [penv] check with: where python
goto :done_err

:load_env
set "ENVFILE=%~1"
if not exist "%ENVFILE%" goto :eof
set "ENVROOT=%~dp1"
if "%ENVROOT:~-1%"=="\" set "ENVROOT=%ENVROOT:~0,-1%"
for /f "usebackq eol=# tokens=1,* delims==" %%A in ("%ENVFILE%") do (
    set "K=%%~A"
    set "V=%%~B"
    if not "!K!"=="" (
        if /i "!K!"=="PATH+" (
            set "PV=!V!"
            set "REL=1"
            if "!PV:~1,1!"==":" set "REL=0"
            if "!PV:~0,2!"=="\\" set "REL=0"
            if "!PV:~0,1!"=="/" set "REL=0"
            if "!REL!"=="1" set "PV=!ENVROOT!\!PV!"
            set "PATH=!PV!;!PATH!"
        ) else (
            set "!K!=!V!"
        )
    )
)
set "PENV_ROOT=%ENVROOT%"
set "PROMPT=[penv] $P$G"
goto :eof

:auto_venv
if not exist "%~1\.venv\Scripts\python.exe" goto :eof
set "PATH=%~1\.venv\Scripts;!PATH!"
set "VIRTUAL_ENV=%~1\.venv"
set "PROMPT=(venv) [penv] $P$G"
goto :eof

:echo_var
set "N=%~1"
set "V=!%N%!"
echo    %N%=!V!
goto :eof

:done_ok
exit /b 0

:done_err
exit /b 1

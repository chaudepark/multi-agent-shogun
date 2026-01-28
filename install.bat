@echo off
setlocal enabledelayedexpansion

REM ============================================================
REM install.bat - multi-agent-shogun Auto Installer for Windows
REM
REM IMPORTANT: Run this file from Windows path, NOT from WSL path!
REM   OK:  C:\Users\...\multi-agent-shogun\install.bat
REM   NG:  \\wsl.localhost\Ubuntu\...\install.bat
REM ============================================================

title multi-agent-shogun Installer

echo.
echo   +============================================================+
echo   ^|  multi-agent-shogun - Auto Installer                       ^|
echo   ^|  Windows Auto Setup Script                                 ^|
echo   +============================================================+
echo.

REM Check if running from UNC path (WSL filesystem)
echo %~dp0 | findstr /i "wsl.localhost wsl$" >nul
if %ERRORLEVEL% EQU 0 (
    echo   +============================================================+
    echo   ^|  ERROR: Cannot run from WSL path!                          ^|
    echo   +============================================================+
    echo.
    echo   This batch file is located in WSL filesystem.
    echo   Please copy to Windows filesystem first:
    echo.
    echo   1. Copy this folder to C:\Users\YourName\multi-agent-shogun
    echo   2. Run install.bat from there
    echo.
    echo   Or run directly in WSL:
    echo.
    echo   1. Open Ubuntu terminal
    echo   2. cd /home/yourname/work/multi-agent-shogun
    echo   3. ./first_setup.sh
    echo.
    pause
    exit /b 1
)

REM ===== Step 1: Check/Install WSL2 =====
echo   [1/4] Checking WSL2...

wsl.exe --version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo   WSL2 not found. Installing...
    echo.

    REM Check admin privileges
    net session >nul 2>&1
    if %ERRORLEVEL% NEQ 0 (
        echo   +============================================================+
        echo   ^|  Administrator privileges required!                        ^|
        echo   +============================================================+
        echo.
        echo   Right-click install.bat and select "Run as administrator"
        echo.
        pause
        exit /b 1
    )

    echo   Installing WSL2...
    wsl --install --no-launch

    echo.
    echo   +============================================================+
    echo   ^|  Restart required!                                         ^|
    echo   +============================================================+
    echo.
    echo   After restart, run install.bat again.
    echo.
    pause
    exit /b 0
)
echo   [OK] WSL2
echo.

REM ===== Step 2: Check/Install Ubuntu =====
echo   [2/4] Checking Ubuntu...

wsl.exe -l -q 2>nul | findstr /i "ubuntu" >nul
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo   Ubuntu not found. Installing...
    echo.

    wsl --install -d Ubuntu --no-launch

    echo.
    echo   +============================================================+
    echo   ^|  Ubuntu initial setup required!                            ^|
    echo   +============================================================+
    echo.
    echo   1. Open Ubuntu from Start Menu
    echo   2. Set your username and password
    echo   3. Run install.bat again
    echo.
    pause
    exit /b 0
)
echo   [OK] Ubuntu
echo.

REM ===== Step 3: Get script path for WSL =====
echo   [3/4] Preparing WSL path...

REM Convert Windows path to WSL path
set "WIN_PATH=%~dp0"
set "WIN_PATH=%WIN_PATH:\=/%"
set "WIN_PATH=%WIN_PATH:C:=/mnt/c%"
set "WIN_PATH=%WIN_PATH:D:=/mnt/d%"
set "WIN_PATH=%WIN_PATH:E:=/mnt/e%"
set "WIN_PATH=%WIN_PATH:F:=/mnt/f%"
REM Remove trailing slash
if "%WIN_PATH:~-1%"=="/" set "WIN_PATH=%WIN_PATH:~0,-1%"

echo   [OK] Path: %WIN_PATH%
echo.

REM ===== Step 4: Run first_setup.sh =====
echo   [4/4] Running first_setup.sh in WSL...
echo.

wsl.exe -e bash -c "cd '%WIN_PATH%' && chmod +x *.sh extensions/scripts/*.sh 2>/dev/null; ./first_setup.sh"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo   +============================================================+
    echo   ^|  Setup failed!                                             ^|
    echo   +============================================================+
    echo.
    pause
    exit /b 1
)

echo.
echo   +============================================================+
echo   ^|  Installation completed!                                   ^|
echo   +============================================================+
echo.
echo   NEXT STEP: Start the system
echo   ----------------------------------------------------------
echo.
echo   Open WSL terminal and run:
echo.
echo     cd %WIN_PATH%
echo     ./shutsujin_departure.sh
echo.
echo   ----------------------------------------------------------
echo.
pause
exit /b 0

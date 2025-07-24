@echo off
setlocal enabledelayedexpansion

REM === Change directory to the script location ===
cd /d "%~dp0"

REM ===============================================================================
REM  SELF-HEALING PRE-FLIGHT CHECK
REM  Ensures PM2 and NPM are in the current session's PATH so all options work.
REM ===============================================================================
for /f "delims=" %%i in ('npm config get prefix 2^>nul') do set "NPM_DIR=%%i"
if defined NPM_DIR (
    echo "!Path!" | findstr /I /C:"!NPM_DIR!" >nul
    if !errorlevel! neq 0 (
        set "Path=!Path!;!NPM_DIR!"
    )
)

REM Set the name for the PM2 process from the ecosystem file
set "PM2_APP_NAME=print-server"

REM Check for administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    set "isAdmin=false"
) else (
    set "isAdmin=true"
)

:menu
cls
echo =================================================================
echo  Node.js Print Server Management Script (Definitive Edition)
echo =================================================================
echo.
echo  Please choose an option:
echo.
echo  [1] Install Dependencies (Run this first)
echo  [2] Start Server (Production)
echo  [3] Stop Server
echo  [4] Restart Server
echo  [5] View Server Status and Logs
echo  [6] Enable Auto-Startup on Reboot (Requires Admin)
echo  [7] Disable Auto-Startup on Reboot (Requires Admin)
echo  [8] Delete Server from PM2
echo.
echo  [0] Exit
echo.
set /p choice="Enter your choice: "

if "%choice%"=="1" goto install
if "%choice%"=="2" goto start
if "%choice%"=="3" goto stop
if "%choice%"=="4" goto restart
if "%choice%"=="5" goto status
if "%choice%"=="6" (
    if "%isAdmin%"=="false" (
        goto admin_required
    ) else (
        goto startup_on
    )
)
if "%choice%"=="7" (
    if "%isAdmin%"=="false" (
        goto admin_required
    ) else (
        goto startup_off
    )
)
if "%choice%"=="8" goto delete
if "%choice%"=="0" goto :eof

echo Invalid choice. Please try again.
pause
goto menu

:install
echo --- 1. Installing Node.js dependencies...
call npm install
if %errorLevel% neq 0 (
    echo [ERROR] Failed to install Node.js dependencies. Please check the output above.
    pause
    goto menu
)
echo.
echo --- 2. Installing PM2 globally...
call npm install pm2 -g
if %errorLevel% neq 0 (
    echo [ERROR] Failed to install PM2 globally. Please check the output above.
    pause
    goto menu
)
echo.
echo Installation complete. Run option [6] next to configure auto-startup.
pause
goto menu

:start
echo Starting the server with PM2...
call npm run start:prod
if %errorLevel% neq 0 (
    echo [ERROR] Failed to start the server. Please check the output above.
    pause
    goto menu
)
echo.
echo Server started. Saving PM2 process list for auto-startup...
call pm2 save
if %errorLevel% neq 0 (
    echo [ERROR] Failed to save the process list.
    pause
    goto menu
)
echo.
echo Server started successfully.
pause
goto menu

:stop
echo Stopping the server...
call pm2 stop %PM2_APP_NAME%
if %errorLevel% neq 0 (
    echo [ERROR] Failed to stop the server. It might not be running. Check 'pm2 list'.
    pause
    goto menu
)
echo.
echo Server stopped.
pause
goto menu

:restart
echo Restarting the server...
call pm2 restart %PM2_APP_NAME%
if %errorLevel% neq 0 (
    echo [ERROR] Failed to restart the server. It might not be running. Use option [2] to start it.
    pause
    goto menu
)
echo.
echo Server restarted.
pause
goto menu

:status
echo --- Server Status ---
call pm2 list
echo.
echo --- Tailing Logs (Press Ctrl+C to stop) ---
call pm2 logs %PM2_APP_NAME% --lines 20
pause
goto menu

:startup_on
echo --- Enabling auto-startup on system reboot (Windows only) ---
echo.

REM --- Section 1: Set System Environment Variables for the PM2 Service ---
echo 1. Configuring System Environment for the PM2 Service...
set "envChanged=false"
for /f "tokens=2,*" %%a in ('reg query "HKLM\System\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul') do set "SYSTEM_PATH=%%b"
set "NEW_PATH=!SYSTEM_PATH!"

for /f "delims=" %%i in ('where node 2^>nul') do set "NODE_DIR=%%~dpi"
for /f "delims=" %%i in ('npm config get prefix 2^>nul') do set "NPM_DIR=%%i"

if defined NODE_DIR (
    echo "!SYSTEM_PATH!" | findstr /I /C:"%NODE_DIR%" >nul
    if !errorlevel! neq 0 (
        echo      - Adding Node.js directory to PATH...
        set "NEW_PATH=!NEW_PATH!;%NODE_DIR%"
        set "envChanged=true"
    )
)
if defined NPM_DIR (
    echo "!SYSTEM_PATH!" | findstr /I /C:"%NPM_DIR%" >nul
    if !errorlevel! neq 0 (
        echo      - Adding NPM global directory to PATH...
        set "NEW_PATH=!NEW_PATH!;%NPM_DIR%"
        set "envChanged=true"
    )
)

if "%envChanged%"=="true" (
    setx Path "!NEW_PATH!" /M
    if !errorlevel! neq 0 (
        echo [ERROR] Failed to update System PATH. Check for admin rights.
        pause
        goto menu
    )
    echo    - SUCCESS: System PATH has been updated.
) else (
    echo    - OK: System PATH is already correctly configured.
)
echo.

REM --- Section 2: Install PM2 Service and Save Processes ---
echo 2. Installing the Windows PM2 startup service...
call pm2 install pm2-windows-startup
if %errorLevel% neq 0 (
    echo [ERROR] Failed to install pm2-windows-startup. Please check the output above.
    pause
    goto menu
)
echo.

REM Check for errored status after installation
call pm2 list | findstr /I "pm2-windows-startup" | findstr /I "errored" >nul
if !errorlevel! == 0 (
    echo.
    echo ============================== FATAL ERROR ==============================
    echo.
    echo  The 'pm2-windows-startup' module entered an 'errored' state.
    echo  This means auto-startup will NOT work.
    echo.
    echo  Displaying logs from the module to help diagnose the issue:
    echo -----------------------------------------------------------------------
    call pm2 logs pm2-windows-startup --lines 20
    echo -----------------------------------------------------------------------
    echo.
    echo  Common Fix: Run option [7] to uninstall, then run [6] again.
    echo.
    echo =======================================================================
    pause
    goto menu
)

REM Check if the app is already running, otherwise start it
call pm2 list | findstr /I /C:"%PM2_APP_NAME%" >nul
if %errorLevel% neq 0 (
    echo [INFO] PM2 process '%PM2_APP_NAME%' not found. Starting it now...
    call npm run start:prod
)
echo.
echo 3. Saving current process list to run on startup...
call pm2 save
if %errorLevel% neq 0 (
    echo [ERROR] Failed to save the process list. Please check the output above.
    pause
    goto menu
)
echo.
echo =======================================================================
echo  Auto-startup has been successfully configured.
if "%envChanged%"=="true" (
    echo.
    echo  IMPORTANT: A system reboot is recommended for all changes
    echo  to be available to the Windows startup service.
)
echo =======================================================================
pause
goto menu

:startup_off
echo --- Disabling ALL auto-startup methods for PM2 ---
echo.
REM Uninstall PM2 Windows startup service (main method)
call pm2-windows-startup uninstall >nul 2>&1
if !errorlevel! == 0 (
    echo [INFO] PM2 Windows startup service has been uninstalled.
) else (
    echo [INFO] PM2 Windows startup service was not found.
)

REM Remove registry-based startup (older method)
REG DELETE "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /V PM2 /F >nul 2>&1
if !errorlevel! == 0 (
    echo [INFO] Removed legacy registry key for PM2 auto-start.
)
echo.
echo Auto-startup has been fully disabled.
pause
goto menu

:delete
echo --- Deleting the server from PM2 ---
echo This will stop the server and remove it from PM2's list.
set /p confirm="Are you sure? (y/n): "
if /i "%confirm%" neq "y" goto menu

call pm2 delete %PM2_APP_NAME%
if %errorLevel% neq 0 (
    echo [ERROR] Failed to delete the server from PM2. It might not exist. Check 'pm2 list'.
    pause
    goto menu
)
echo.
echo Server has been deleted from PM2.
pause
goto menu

:admin_required
echo.
echo =================================== WARNING ===================================
echo.
echo  This option requires administrator privileges to run correctly.
echo  Please right-click on 'manage.bat' and select 'Run as administrator'.
echo.
echo ===============================================================================
echo.
pause
goto menu

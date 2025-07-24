@echo off
setlocal

REM === Change directory to the script location ===
cd /d "%~dp0"

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
echo  Node.js Print Server Management Script
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
echo Installation complete.
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
    echo [ERROR] Failed to save the process list. Please check the output above.
    pause
    goto menu
)
echo.
echo Server started and auto-start is now active. Use option [5] to check its status.
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
echo 1. Installing the Windows PM2 startup service...
call pm2 install pm2-windows-startup
if %errorLevel% neq 0 (
    echo [ERROR] Failed to install pm2-windows-startup. Please check the output above.
    pause
    goto menu
)
echo.
REM Check if the app is already running, otherwise start it
call pm2 list | findstr /I "%PM2_APP_NAME%" >nul
if %errorLevel% neq 0 (
    echo [INFO] PM2 process '%PM2_APP_NAME%' not found. Starting it now...
    call npm run start:prod
)
echo.
echo 2. Saving current process list to run on startup...
call pm2 save
if %errorLevel% neq 0 (
    echo [ERROR] Failed to save the process list. Please check the output above.
    pause
    goto menu
)
echo.
echo Auto-startup has been enabled for Windows and current app.
pause
goto menu

:startup_off
echo --- Disabling auto-startup on system reboot (Windows only) ---
call npx pm2-windows-startup uninstall
if %errorLevel% neq 0 (
    echo [ERROR] Failed to uninstall the PM2 startup service. Please check the output above.
    pause
    goto menu
)
echo.
echo Auto-startup has been disabled for Windows.
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
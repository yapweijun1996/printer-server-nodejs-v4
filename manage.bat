@echo off
setlocal

REM Set the name for the PM2 process from the ecosystem file
set "PM2_APP_NAME=print-server"

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
echo  [6] Enable Auto-Startup on Reboot
echo  [7] Disable Auto-Startup on Reboot
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
if "%choice%"=="6" goto startup_on
if "%choice%"=="7" goto startup_off
if "%choice%"=="8" goto delete
if "%choice%"=="0" goto :eof

echo Invalid choice. Please try again.
pause
goto menu

:install
echo --- 1. Installing Node.js dependencies...
call npm install
echo.
echo --- 2. Installing PM2 globally...
call npm install pm2 -g
echo.
echo Installation complete.
pause
goto menu

:start
echo Starting the server with PM2...
call npm run start:prod
echo.
echo Server started. Use option [5] to check its status.
pause
goto menu

:stop
echo Stopping the server...
call pm2 stop %PM2_APP_NAME%
echo.
echo Server stopped.
pause
goto menu

:restart
echo Restarting the server...
call pm2 restart %PM2_APP_NAME%
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
echo --- Enabling auto-startup on system reboot ---
echo.
echo 1. Generating startup script...
call pm2 startup
echo.
echo 2. Saving current process list to run on startup...
call pm2 save
echo.
echo Auto-startup has been enabled.
pause
goto menu

:startup_off
echo --- Disabling auto-startup on system reboot ---
call pm2 unstartup
echo.
echo Auto-startup has been disabled.
pause
goto menu

:delete
echo --- Deleting the server from PM2 ---
echo This will stop the server and remove it from PM2's list.
set /p confirm="Are you sure? (y/n): "
if /i "%confirm%" neq "y" goto menu

call pm2 delete %PM2_APP_NAME%
echo.
echo Server has been deleted from PM2.
pause
goto menu
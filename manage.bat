@echo off
setlocal enabledelayedexpansion

REM === Change directory to the script location ===
cd /d "%~dp0"

REM ===============================================================================
REM  SELF-HEALING PRE-FLIGHT CHECK
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
echo  Node.js Print Server Management Script (vEradicate)
echo =================================================================
echo.
echo  -- Standard Operations --
echo  [1] Install Dependencies (Run this first)
echo  [2] Start Server (Production)
echo  [3] Stop Server
echo  [4] Restart Server
echo  [5] View Server Status and Logs
echo.
echo  -- Administrative and Recovery Tasks (Requires Admin) --
echo  [6] Enable Auto-Startup on Reboot
echo  [7] Disable Auto-Startup on Reboot
echo  [X] NUKE PM2 FROM ORBIT (Start from Zero)
echo.
echo  [0] Exit
echo.
set /p choice="Enter your choice: "

if "%choice%"=="1" goto install
if "%choice%"=="2" goto start
if "%choice%"=="3" goto stop
if "%choice%"=="4" goto restart
if "%choice%"=="5" goto status
if "%choice%"=="6" goto admin_check
if "%choice%"=="7" goto admin_check
if /i "%choice%"=="X" goto admin_check
if "%choice%"=="0" goto :eof

echo Invalid choice. Please try again.
pause
goto menu

:admin_check
if "%isAdmin%"=="false" (
    goto admin_required
)
if "%choice%"=="6" goto startup_on
if "%choice%"=="7" goto startup_off
if /i "%choice%"=="X" goto eradicate_pm2
goto menu

:install
echo --- 1. Installing Node.js dependencies...
call npm install
if %errorLevel% neq 0 (
    echo [ERROR] Failed to install Node.js dependencies.
    pause
    goto menu
)
echo.
echo --- 2. Installing PM2 globally...
call npm install pm2 -g
if %errorLevel% neq 0 (
    echo [ERROR] Failed to install PM2 globally.
    pause
    goto menu
)
echo.
echo Installation complete. You can now use option [2] or [6].
pause
goto menu

:start
echo Starting the server with PM2...
call npm run start:prod
if %errorLevel% neq 0 (
    echo [ERROR] Failed to start the server. Check for EPERM errors.
    echo If found, run this script as an Admin and use option [X].
    pause
    goto menu
)
echo.
echo Server started successfully.
pause
goto menu

:stop
call pm2 stop %PM2_APP_NAME% >nul 2>&1
goto menu

:restart
call pm2 restart %PM2_APP_NAME% >nul 2>&1
goto menu

:status
call pm2 list
if %errorLevel% neq 0 (
    echo.
    echo [ERROR] Failed to get status. Run this script as Admin and use option [X].
)
pause
goto menu

:startup_on
echo --- Enabling auto-startup on system reboot ---
call pm2 install pm2-windows-startup
call pm2-startup install
call pm2 save
echo --- Auto-startup has been configured ---
echo If you want to test, reboot your computer and run "pm2 list" to check.
pause
goto menu

:startup_off
echo --- Disabling ALL auto-startup methods for PM2 ---
call pm2-startup uninstall >nul 2>&1
call npx pm2-windows-startup uninstall >nul 2>&1
call pm2 uninstall pm2-windows-startup >nul 2>&1
REG DELETE "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /V PM2 /F >nul 2>&1
echo --- Auto-startup has been disabled ---
pause
goto menu

:eradicate_pm2
echo.
echo =======================================================================
echo           !!! EXTREME DANGER: TOTAL PM2 ERADICATION !!!
echo =======================================================================
echo.
echo  This will UNINSTALL PM2, DELETE ALL its configuration files,
echo  and kill any stuck background processes. This is the only way
echo  to guarantee a 100%% fresh start from zero.
echo.
set /p confirm="Are you ABSOLUTELY sure? This cannot be undone. (y/n): "
if /i "%confirm%" neq "y" goto menu

echo.
echo --- Step 1: Terminating all Node.js and PM2 processes...
taskkill /F /IM node.exe /T >nul 2>&1
echo    - Done.
echo.

echo --- Step 2: Uninstalling PM2 globally...
npm uninstall pm2 -g
echo    - Done.
echo.

echo --- Step 3: Deleting the PM2 configuration directory...
set "PM2_DIR=%USERPROFILE%\.pm2"
if exist "!PM2_DIR!" (
    rmdir /s /q "!PM2_DIR!"
    echo    - SUCCESS: Deleted !PM2_DIR!
) else (
    echo    - INFO: Directory !PM2_DIR! not found.
)
echo.

echo --- Step 4: Clearing the NPM cache...
npm cache clean --force
echo    - Done.
echo.

echo =======================================================================
echo   PM2 has been completely ERADICATED from your system.
echo.
echo   The script will now run the installer for you to start
echo   from a truly clean slate.
echo =======================================================================
pause
goto install

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

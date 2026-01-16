@echo off
REM CORTEX BOT - Windows Build Script
REM Usage: build.bat [quake_path]

echo ===============================================
echo CORTEX BOT v4.2 "Hunter" - Build Script
echo ===============================================
echo.

REM Check for FTEQCC
where fteqcc >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: fteqcc not found in PATH
    echo.
    echo Download FTEQCC from: https://www.fteqcc.org/
    echo Or add it to your PATH environment variable
    echo.
    pause
    exit /b 1
)

echo [1/3] Compiling QuakeC...
fteqcc progs.src

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ERROR: Compilation failed!
    pause
    exit /b 1
)

echo [2/3] Compilation successful!
echo.

REM Check if quake path provided
if "%~1"=="" (
    echo [3/3] progs.dat created in current directory
    echo.
    echo To install, copy progs.dat to your Quake id1 folder:
    echo   copy progs.dat "C:\Games\Quake\id1\"
    echo.
    echo Then run Quake:
    echo   quake +deathmatch 1 +map dm4
    echo.
    echo In game console:
    echo   impulse 100
    echo.
) else (
    echo [3/3] Copying to %~1\id1\
    copy /Y progs.dat "%~1\id1\progs.dat"
    echo.
    echo Ready to test! Run:
    echo   "%~1\quake.exe" +deathmatch 1 +map dm4
    echo.
)

echo Build complete!
pause

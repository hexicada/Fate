@echo off
setlocal

set "PROJECT_DIR=%~dp0"
if "%PROJECT_DIR:~-1%"=="\" set "PROJECT_DIR=%PROJECT_DIR:~0,-1%"
set "LOG_FILE=%PROJECT_DIR%\godot_launch.log"
set "GODOT_EXE="

REM Prefer explicit binary first; avoid shim ambiguity.
if exist "C:\ProgramData\chocolatey\bin\Godot_v4.6.3-stable_win64.exe" (
    set "GODOT_EXE=C:\ProgramData\chocolatey\bin\Godot_v4.6.3-stable_win64.exe"
)

if not defined GODOT_EXE if exist "C:\ProgramData\chocolatey\bin\godot.exe" (
    set "GODOT_EXE=C:\ProgramData\chocolatey\bin\godot.exe"
)

if not defined GODOT_EXE (
    where godot >nul 2>nul
    if %errorlevel%==0 (
        set "GODOT_EXE=godot"
    )
)

if not defined GODOT_EXE (
    echo Could not find Godot executable.
    echo Install Godot 4.x or add godot to PATH.
    pause
    exit /b 1
)

echo ================================================== > "%LOG_FILE%"
echo Launch time: %DATE% %TIME% >> "%LOG_FILE%"
echo Executable: %GODOT_EXE% >> "%LOG_FILE%"
echo Project: %PROJECT_DIR% >> "%LOG_FILE%"
echo ================================================== >> "%LOG_FILE%"
echo.
echo Launching Godot with verbose logging...
echo Log file: %LOG_FILE%
echo.

"%GODOT_EXE%" --path "%PROJECT_DIR%" --editor --verbose >> "%LOG_FILE%" 2>&1
set "EXIT_CODE=%ERRORLEVEL%"

echo.
echo Godot exited with code %EXIT_CODE%.
echo Last 30 log lines:
powershell -NoProfile -Command "Get-Content -Path '%LOG_FILE%' -Tail 30"
echo.
echo If this still closes instantly, send me godot_launch.log.
pause
exit /b %EXIT_CODE%

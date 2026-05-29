@echo off
setlocal

set "PROJECT_DIR=%~dp0"
if "%PROJECT_DIR:~-1%"=="\" set "PROJECT_DIR=%PROJECT_DIR:~0,-1%"
set "GODOT_EXE="

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
    echo Install Godot 4.x or add godot to PATH, then try again.
    pause
    exit /b 1
)

echo Launching with: %GODOT_EXE%
"%GODOT_EXE%" --path "%PROJECT_DIR%" --editor

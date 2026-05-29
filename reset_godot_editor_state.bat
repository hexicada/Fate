@echo off
setlocal

set "ROAMING_GODOT=%APPDATA%\Godot"
set "PROJECT_DIR=%~dp0"
if "%PROJECT_DIR:~-1%"=="\" set "PROJECT_DIR=%PROJECT_DIR:~0,-1%"
set "BACKUP_DIR=%PROJECT_DIR%\godot_state_backup_%DATE:~10,4%-%DATE:~4,2%-%DATE:~7,2%_%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%"
set "BACKUP_DIR=%BACKUP_DIR: =0%"

if not exist "%ROAMING_GODOT%" (
    echo Godot settings folder not found: %ROAMING_GODOT%
    pause
    exit /b 1
)

mkdir "%BACKUP_DIR%" >nul 2>nul

if exist "%ROAMING_GODOT%\editor_settings-4.6.tres" copy "%ROAMING_GODOT%\editor_settings-4.6.tres" "%BACKUP_DIR%\editor_settings-4.6.tres.bak" >nul
if exist "%ROAMING_GODOT%\projects.cfg" copy "%ROAMING_GODOT%\projects.cfg" "%BACKUP_DIR%\projects.cfg.bak" >nul
if exist "%ROAMING_GODOT%\app_userdata\Fate Prototype" xcopy "%ROAMING_GODOT%\app_userdata\Fate Prototype" "%BACKUP_DIR%\Fate Prototype" /E /I /Q /Y >nul

if exist "%ROAMING_GODOT%\editor_settings-4.6.tres" del /q "%ROAMING_GODOT%\editor_settings-4.6.tres"
if exist "%ROAMING_GODOT%\projects.cfg" del /q "%ROAMING_GODOT%\projects.cfg"
if exist "%ROAMING_GODOT%\app_userdata\Fate Prototype" rmdir /s /q "%ROAMING_GODOT%\app_userdata\Fate Prototype"

echo Reset complete. Backup saved to:
echo %BACKUP_DIR%
echo.
echo Next: run open_project_safe_mode.bat once, then open_project.bat.
pause

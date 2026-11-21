@echo off
REM Double-click to play. Edit GODOT below if your Godot .exe is somewhere else.
set "GODOT=C:\Users\Asus\godot_engine\Godot_v4.7.2-stable_win64.exe"
set "HERE=%~dp0."
if not exist "%GODOT%" (
  echo Godot not found at %GODOT%
  pause
  exit /b 1
)
"%GODOT%" --path "%HERE%"
if errorlevel 1 pause

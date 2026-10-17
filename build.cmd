@echo off
REM Build / upload wrapper for M5Core2-MIDIXposeFilBT.
REM   build.cmd                  -> compile, then list the COM ports (comports.ps1)
REM   build.cmd --upload -p COM4 -> compile + upload
setlocal
set "SKETCH_DIR=%~dp0"
if "%SKETCH_DIR:~-1%"=="\" set "SKETCH_DIR=%SKETCH_DIR:~0,-1%"
arduino-cli compile --fqbn m5stack:esp32:m5stack_core2 %* "%SKETCH_DIR%"
set "RC=%ERRORLEVEL%"
if "%~1"=="" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%SKETCH_DIR%\comports.ps1"
  echo   upload: build.cmd --upload -p COMx
)
endlocal & exit /b %RC%

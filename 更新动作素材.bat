@echo off
setlocal
cd /d "%~dp0"
where py >nul 2>nul
if %errorlevel%==0 (
  py -3 tools\build_motion_sheets.py
) else (
  python tools\build_motion_sheets.py
)
if errorlevel 1 exit /b %errorlevel%
echo.
echo Motion assets updated. You can start the game now.
pause

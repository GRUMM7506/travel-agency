@echo off
setlocal
cd /d "%~dp0"

echo Открываю backend в отдельном окне...
start "travel-agency backend" cmd /k call "%~dp0start-backend.bat"

echo Жду несколько секунд, пока backend поднимется...
timeout /t 6 /nobreak >nul

call "%~dp0start-frontend.bat"

endlocal

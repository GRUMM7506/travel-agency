@echo off
setlocal
cd /d "%~dp0..\backend"

if not exist venv\Scripts\python.exe (
    echo ERROR: backend\venv не найден. Сначала запустите start-backend.bat хотя бы раз.
    pause
    exit /b 1
)

REM Можно перетащить файл .backup на этот .bat в проводнике - он придёт как %1
venv\Scripts\python.exe "%~dp0restore_db.py" %1
pause

endlocal

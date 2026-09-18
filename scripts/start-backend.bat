@echo off
setlocal
cd /d "%~dp0..\backend"

if not exist venv\Scripts\python.exe (
    echo Не найден venv в backend\venv. Создаю...
    python -m venv venv
    call venv\Scripts\activate.bat
    pip install -r requirements.txt
) else (
    call venv\Scripts\activate.bat
)

if not exist .env (
    echo.
    echo ERROR: backend\.env не найден.
    echo Скопируйте backend\.env.example в backend\.env и укажите DATABASE_URL вашей локальной БД.
    pause
    exit /b 1
)

echo Применяю миграции...
python -m alembic upgrade head
if errorlevel 1 (
    echo ERROR: alembic upgrade head завершился с ошибкой, смотрите вывод выше.
    pause
    exit /b 1
)

echo.
echo Запускаю backend на http://127.0.0.1:8000 ...
uvicorn app.main:app --reload --host 127.0.0.1 --port 8000

endlocal

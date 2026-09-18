@echo off
setlocal
cd /d "%~dp0.."

echo Запускаю Flutter web (Chrome), backend ожидается на http://127.0.0.1:8000 ...
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000

endlocal

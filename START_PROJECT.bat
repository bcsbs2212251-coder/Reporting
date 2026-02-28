@echo off
echo ============================================================
echo   MOLECULE WORKFLOW PRO - Quick Start
echo ============================================================
echo.

echo Checking Python...
python --version
if errorlevel 1 (
    echo ERROR: Python is not installed or not in PATH
    pause
    exit /b 1
)

echo.
echo Checking Flutter...
flutter --version
if errorlevel 1 (
    echo ERROR: Flutter is not installed or not in PATH
    pause
    exit /b 1
)

echo.
echo ============================================================
echo   Starting Backend Server...
echo ============================================================
echo.

start "Molecule Backend" cmd /k "cd backend && python run_server.py"

timeout /t 3 /nobreak >nul

echo.
echo ============================================================
echo   Starting Frontend App...
echo ============================================================
echo.

start "Molecule Frontend" cmd /k "cd frontend && flutter run -d chrome"

echo.
echo ============================================================
echo   Project Started!
echo ============================================================
echo.
echo Backend: http://localhost:8000
echo API Docs: http://localhost:8000/docs
echo Frontend: Will open in Chrome automatically
echo.
echo Press any key to exit this window...
pause >nul

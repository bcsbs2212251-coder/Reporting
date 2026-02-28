@echo off
echo ============================================================
echo   MOLECULE WORKFLOW PRO - Project Verification
echo ============================================================
echo.

echo [1/5] Checking Python installation...
python --version
if errorlevel 1 (
    echo [FAIL] Python is not installed
    goto :error
)
echo [OK] Python is installed
echo.

echo [2/5] Checking Flutter installation...
flutter --version | findstr /C:"Flutter"
if errorlevel 1 (
    echo [FAIL] Flutter is not installed
    goto :error
)
echo [OK] Flutter is installed
echo.

echo [3/5] Checking backend dependencies...
cd backend
python -c "import fastapi, motor, pymongo, pydantic; print('[OK] All core backend dependencies installed')"
if errorlevel 1 (
    echo [FAIL] Backend dependencies missing
    echo Run: pip install -r requirements.txt
    cd ..
    goto :error
)
cd ..
echo.

echo [4/5] Checking backend imports...
cd backend
python -c "from main import app; print('[OK] Backend app loads successfully')"
if errorlevel 1 (
    echo [FAIL] Backend has import errors
    cd ..
    goto :error
)
cd ..
echo.

echo [5/5] Checking frontend dependencies...
cd frontend
if not exist "pubspec.lock" (
    echo [WARN] Flutter dependencies not installed
    echo Run: flutter pub get
) else (
    echo [OK] Flutter dependencies installed
)
cd ..
echo.

echo ============================================================
echo   VERIFICATION COMPLETE - PROJECT IS READY!
echo ============================================================
echo.
echo Next steps:
echo   1. Run START_PROJECT.bat to start both backend and frontend
echo   2. Or manually start:
echo      - Backend: cd backend ^&^& uvicorn main:app --reload
echo      - Frontend: cd frontend ^&^& flutter run -d chrome
echo.
echo See PROJECT_STATUS.md for detailed information.
echo.
pause
exit /b 0

:error
echo.
echo ============================================================
echo   VERIFICATION FAILED
echo ============================================================
echo.
echo Please check the error messages above and fix the issues.
echo See PROJECT_STATUS.md for troubleshooting help.
echo.
pause
exit /b 1

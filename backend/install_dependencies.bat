@echo off
echo ============================================================
echo   Installing Backend Dependencies
echo ============================================================
echo.

echo This will install all required Python packages...
echo.

python -m pip install --upgrade pip
echo.

echo Installing packages from requirements.txt...
python -m pip install -r requirements.txt

echo.
echo ============================================================
echo   Installation Complete!
echo ============================================================
echo.
echo To start the backend server, run:
echo   python run_server.py
echo.
echo Or use:
echo   python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000
echo.
pause

@echo off
echo ============================================================
echo   Free Port 8000
echo ============================================================
echo.

echo Checking what's using port 8000...
netstat -ano | findstr :8000

echo.
echo Finding process ID...
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :8000') do (
    set PID=%%a
    goto :found
)

echo Port 8000 is not in use.
goto :end

:found
echo.
echo Process ID using port 8000: %PID%
echo.
echo Do you want to kill this process? (Y/N)
set /p CONFIRM=

if /i "%CONFIRM%"=="Y" (
    echo.
    echo Killing process %PID%...
    taskkill /PID %PID% /F
    echo.
    echo Done! Port 8000 should now be free.
) else (
    echo.
    echo Operation cancelled.
)

:end
echo.
pause

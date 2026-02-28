@echo off
echo Starting Molecule WorkFlow Pro Frontend...
echo.

REM Install dependencies
echo Installing Flutter dependencies...
call flutter pub get

REM Run app
echo.
echo Starting Flutter app...
echo.
call flutter run -d chrome

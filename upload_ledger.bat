@echo off
setlocal

REM مسیر Git Bash - اگر جای دیگری نصب است این خط را تغییر دهید
set "GITBASH=C:\Program Files\Git\bin\bash.exe"

if not exist "%GITBASH%" (
    echo [X] Git Bash not found at:
    echo     %GITBASH%
    echo.
    echo Edit this .bat file and fix the GITBASH path.
    pause
    exit /b 1
)

REM رفتن به پوشه اسکریپت
cd /d "%~dp0"

REM اجرای اسکریپت bash
"%GITBASH%" -c "cd \"$(pwd)\" && ./upload_ledger.sh"

echo.
pause
@echo off
SETLOCAL EnableDelayedExpansion

echo [INFO] Windows Command Prompt Auto-Launcher Initialized.

:: Check Python
where python >nul 2>nul
if %errorlevel% neq 0 (
    echo [WARN] Python not found in PATH. Attempting winget installation...
    winget install -e --id Python.Python.3.11 --accept-package-agreements
    if %errorlevel% neq 0 (
        echo [ERROR] Python installation failed. Please install manually.
        pause
        exit /b 1
    )
)

:: Check Node.js
where node >nul 2>nul
if %errorlevel% neq 0 (
    echo [WARN] Node.js not found in PATH. Attempting winget installation...
    winget install -e --id OpenJS.NodeJS --accept-package-agreements
)

:: Check Vercel
where vercel >nul 2>nul
if %errorlevel% neq 0 (
    echo [WARN] Installing Vercel CLI...
    call npm install -g vercel
)

:: Python Virtual Environment
if not exist "venv" (
    echo [INFO] Creating Python virtual environment...
    python -m venv venv
)

call venv\Scripts\activate.bat
python -m pip install --upgrade pip
pip install -r requirements.txt

:: Check Deployment Flag
if "%1"=="--deploy" (
    echo [INFO] Deploying repository to Vercel...
    call vercel deploy --yes --prod
    goto END
)

:: Verify & Launch
echo [INFO] Running Lockdown Validation Audit...
python lockdown_check.py
if %errorlevel% neq 0 (
    echo [ERROR] Pre-flight lockdown failed.
    pause
    exit /b 1
)

echo [INFO] Launching Web Command Center...
streamlit run ui_command_center/app.py

:END
ENDLOCAL

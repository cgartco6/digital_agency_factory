# Requires Administrator privileges for automated software installations
$ErrorActionPreference = "Stop"

Write-Host "[INFO] Detected Windows Operating System." -ForegroundColor Green

function Test-CommandExists {
    param ($Command)
    return [bool](Get-Command $Command -ErrorAction SilentlyContinue)
}

# 1. Package Manager Check (winget)
if (-not (Test-CommandExists "winget")) {
    Write-Host "[WARN] Windows Package Manager (winget) is missing. Installing software manually or updating OS is required." -ForegroundColor Yellow
}

# 2. Check and Auto-Install Python
if (-not (Test-CommandExists "python")) {
    Write-Host "[WARN] Python missing. Installing Python 3 via winget..." -ForegroundColor Yellow
    winget install -e --id Python.Python.3.11 --accept-package-agreements --accept-source-agreements
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

# 3. Check and Auto-Install Node.js & Vercel
if (-not (Test-CommandExists "node")) {
    Write-Host "[WARN] Node.js missing. Installing Node.js via winget..." -ForegroundColor Yellow
    winget install -e --id OpenJS.NodeJS --accept-package-agreements --accept-source-agreements
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

if (-not (Test-CommandExists "vercel")) {
    Write-Host "[WARN] Vercel CLI missing. Installing via npm..." -ForegroundColor Yellow
    npm install -g vercel
}

# 4. Virtual Environment & Dependencies
Write-Host "[INFO] Setting up Python Virtual Environment..." -ForegroundColor Green
if (-not (Test-Path "venv")) {
    python -m venv venv
}

& ".\venv\Scripts\Activate.ps1"
python -m pip install --upgrade pip
pip install -r requirements.txt

# 5. Vercel Deployment Check
if ($args[0] -eq "--deploy") {
    Write-Host "[INFO] Executing Cloud Deployment to Vercel..." -ForegroundColor Green
    vercel deploy --yes --prod
    exit 0
}

# 6. Pre-flight Lockdown Audit & UI Launch
Write-Host "[INFO] Running lockdown check across code modules..." -ForegroundColor Green
python lockdown_check.py

Write-Host "[INFO] Launching Command Center Interface..." -ForegroundColor Green
streamlit run ui_command_center/app.py

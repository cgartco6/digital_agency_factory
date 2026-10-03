#!/usr/bin/env bash
set -e

BOLD="\031[1m"
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
NC="\033[0m"

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_err()  { echo -e "${RED}[ERROR]${NC} $1"; }

OS_TYPE="$(uname -s)"
log_info "Detected Operating System: ${OS_TYPE}"

# 1. Package Manager Auto-Detection & OS Package Installer
install_system_package() {
  PACKAGE=$1
  if command -v brew &> /dev/null; then
    brew install "$PACKAGE"
  elif command -v apt-get &> /dev/null; then
    sudo apt-get update -y && sudo apt-get install -y "$PACKAGE"
  elif command -v dnf &> /dev/null; then
    sudo dnf install -y "$PACKAGE"
  elif command -v pacman &> /dev/null; then
    sudo pacman -S --noconfirm "$PACKAGE"
  else
    log_err "No supported system package manager found (brew, apt, dnf, pacman). Please install $PACKAGE manually."
    exit 1
  fi
}

# 2. Python Detection & Environment Setup
if ! command -v python3 &> /dev/null; then
  log_warn "Python 3 is missing. Attempting automatic system installation..."
  install_system_package python3
fi

if ! command -v pip3 &> /dev/null; then
  log_warn "pip3 is missing. Installing..."
  install_system_package python3-pip
fi

log_info "Setting up Python Virtual Environment..."
if [ ! -d "venv" ]; then
  python3 -m venv venv || {
    log_warn "python3-venv missing. Attempting installation..."
    install_system_package python3-venv
    python3 -m venv venv
  }
fi

source venv/bin/activate
pip install --upgrade pip
log_info "Installing Python dependencies from requirements.txt..."
pip install -r requirements.txt

# 3. Node.js & Vercel CLI Auto-Detection
if ! command -v node &> /dev/null; then
  log_warn "Node.js is missing. Attempting automatic installation..."
  install_system_package nodejs
fi

if ! command -v npm &> /dev/null; then
  log_warn "npm is missing. Attempting automatic installation..."
  install_system_package npm
fi

if ! command -v vercel &> /dev/null; then
  log_warn "Vercel CLI missing. Auto-installing globally via npm..."
  npm install -g vercel || sudo npm install -g vercel
fi

# 4. Optional Vercel Automated Deployment Flag Check
if [[ "$1" == "--deploy" ]]; then
  log_info "Triggering Vercel Auto-Deployment..."
  vercel deploy --yes --prod
  exit 0
fi

# 5. Execute Self-Test Suite & Launch Command Center
log_info "Running system self-healing check and lock validation..."
python3 lockdown_check.py || {
  log_err "Lockdown check failed! System halted."
  exit 1
}

log_info "Launching Factory Web Command Center..."
streamlit run ui_command_center/app.py

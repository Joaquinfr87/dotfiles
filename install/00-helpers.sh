#!/usr/bin/env bash
# ==============================================================================
# install/00-helpers.sh — Helpers, colors and Debian 13 environment checks
# ==============================================================================
set -euo pipefail

# Make sure ~/.local/bin is available during the installation
export PATH="$HOME/.local/bin:$PATH"

# Avoid interactive APT/debconf prompts blocking the terminal
export DEBIAN_FRONTEND=noninteractive

# ANSI colors
BOLD='\033[1m'
GREEN='\033[38;5;142m'
BLUE='\033[38;5;109m'
YELLOW='\033[38;5;214m'
RED='\033[38;5;167m'
CYAN='\033[38;5;108m'
NC='\033[0m'

log_step() {
  echo -e "\n${CYAN}====================================================================${NC}"
  echo -e "${BOLD}${CYAN}>> $1${NC}"
  echo -e "${CYAN}====================================================================${NC}"
}

log_info() { echo -e "${BLUE}==>${NC} ${BOLD}$*${NC}"; }
log_ok() { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_err() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

# ------------------------------------------------------------------------------
# Supported platform: Debian 13 (trixie) only
# ------------------------------------------------------------------------------
require_debian_13() {
  local id="" version=""
  if [[ -r /etc/os-release ]]; then
    id="$(sed -n 's/^ID=//p' /etc/os-release | tr -d '"')"
    version="$(sed -n 's/^VERSION_ID=//p' /etc/os-release | tr -d '"')"
  fi

  if [[ "$id" != "debian" || "$version" != "13" ]]; then
    log_err "Unsupported system: ID=${id:-unknown} VERSION_ID=${version:-unknown}."
    log_err "This installer only supports Debian 13 (trixie)."
    log_err "Other distributions are intentionally not supported."
    exit 1
  fi
}

# Run a command with sudo when needed
run_sudo() {
  if [[ $EUID -eq 0 ]]; then
    "$@"
  elif has_cmd sudo; then
    sudo "$@"
  else
    log_err "Administrator privileges (sudo/root) are required for: $*"
    exit 1
  fi
}

# ------------------------------------------------------------------------------
# APT helpers (Debian only)
# ------------------------------------------------------------------------------
pkg_update() {
  log_info "Updating APT repositories..."
  run_sudo apt-get update -y
}

pkg_install() {
  if ! run_sudo apt-get install -y "$@"; then
    log_warn "Batch install failed. Retrying packages individually..."
    for p in "$@"; do
      run_sudo apt-get install -y "$p" 2>/dev/null || log_warn "Package not available in the configured repositories: $p"
    done
  fi
}

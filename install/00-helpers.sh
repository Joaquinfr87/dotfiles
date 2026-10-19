#!/usr/bin/env bash
# ==============================================================================
# install/00-helpers.sh — Funciones auxiliares, colores y detección de entorno
# ==============================================================================
set -euo pipefail

# Asegurar que ~/.local/bin esté en el PATH durante la ejecución
export PATH="$HOME/.local/bin:$PATH"

# Colores ANSI
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
log_warn() { echo -e "${YELLOW}[AVISO]${NC} $*"; }
log_err() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

# Detección de distribución
detect_os() {
  if [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    echo "${ID:-unknown}"
  else
    echo "unknown"
  fi
}

# Ejecutar con sudo si es necesario
run_sudo() {
  if [[ $EUID -eq 0 ]]; then
    "$@"
  elif has_cmd sudo; then
    sudo "$@"
  else
    log_err "Se requieren permisos de administrador (sudo/root) para: $*"
    exit 1
  fi
}

# Gestor de paquetes unificado
pkg_update() {
  local os
  os="$(detect_os)"
  case "$os" in
    debian|ubuntu|pop|linuxmint)
      log_info "Actualizando repositorios APT..."
      run_sudo apt update -y
      ;;
    arch|cachyos|manjaro)
      log_info "Actualizando base de datos pacman..."
      run_sudo pacman -Sy
      ;;
    fedora)
      log_info "Actualizando repositorios dnf..."
      run_sudo dnf check-update || true
      ;;
    *)
      log_warn "Distribución '$os' no gestionada automáticamente para update."
      ;;
  esac
}

pkg_install() {
  local os
  os="$(detect_os)"
  case "$os" in
    debian|ubuntu|pop|linuxmint)
      if ! run_sudo apt install -y "$@"; then
        log_warn "No se pudieron instalar todos los paquetes en bloque. Intentando instalar paquetes disponibles individualmente..."
        for p in "$@"; do
          run_sudo apt install -y "$p" 2>/dev/null || log_warn "Paquete no disponible en este repositorio: $p"
        done
      fi
      ;;
    arch|cachyos|manjaro)
      if ! run_sudo pacman -S --noconfirm --needed "$@"; then
        log_warn "No se pudieron instalar todos los paquetes con pacman en bloque. Intentando individualmente..."
        for p in "$@"; do
          run_sudo pacman -S --noconfirm --needed "$p" 2>/dev/null || log_warn "Paquete no disponible en pacman: $p"
        done
      fi
      ;;
    fedora)
      if ! run_sudo dnf install -y "$@"; then
        log_warn "No se pudieron instalar todos los paquetes con dnf en bloque. Intentando individualmente..."
        for p in "$@"; do
          run_sudo dnf install -y "$p" 2>/dev/null || log_warn "Paquete no disponible en dnf: $p"
        done
      fi
      ;;
    *)
      log_warn "No se pudo instalar paquetes automáticamente en '$os': $*"
      ;;
  esac
}

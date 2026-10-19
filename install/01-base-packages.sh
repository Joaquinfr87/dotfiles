#!/usr/bin/env bash
# ==============================================================================
# install/01-base-packages.sh — Instalación de paquetes base y utilidades CLI
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/00-helpers.sh"

log_step "Instalando paquetes esenciales del sistema y herramientas CLI"

OS="$(detect_os)"

case "$OS" in
  debian|ubuntu|pop|linuxmint)
    log_info "Instalando paquetes base para sistemas Debian/Ubuntu..."
    pkg_update
    pkg_install \
      git \
      curl \
      wget \
      unzip \
      tar \
      build-essential \
      zsh \
      tmux \
      fzf \
      ripgrep \
      fd-find \
      tree \
      htop \
      fastfetch \
      ca-certificates
    ;;
  arch|cachyos|manjaro)
    log_info "Instalando paquetes base para Arch Linux..."
    pkg_update
    pkg_install \
      base-devel \
      git \
      curl \
      wget \
      unzip \
      tar \
      zsh \
      tmux \
      fzf \
      ripgrep \
      fd \
      tree \
      htop \
      fastfetch \
      ca-certificates
    ;;
  fedora)
    log_info "Instalando paquetes base para Fedora..."
    pkg_install \
      @development-tools \
      git \
      curl \
      wget \
      unzip \
      tar \
      zsh \
      tmux \
      fzf \
      ripgrep \
      fd-find \
      tree \
      htop \
      fastfetch \
      ca-certificates
    ;;
  *)
    log_warn "Distribución no reconocida ($OS). Asegúrate de tener instalados: git, curl, zsh, tmux, fzf, ripgrep."
    ;;
esac

# Asegurar enlace de fd si se instaló como fdfind (común en Debian/Ubuntu)
if has_cmd fdfind && ! has_cmd fd; then
  mkdir -p "$HOME/.local/bin"
  ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
  log_ok "Enlazado 'fdfind' como 'fd' en ~/.local/bin/fd"
fi

log_ok "Paquetes base instalados correctamente."

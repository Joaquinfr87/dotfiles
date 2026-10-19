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
      xz-utils \
      build-essential \
      zsh \
      tmux \
      fzf \
      ripgrep \
      fd-find \
      tree \
      htop \
      fastfetch \
      ca-certificates \
      direnv \
      git-delta
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
      ca-certificates \
      git-delta
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
      ca-certificates \
      git-delta
    ;;
  *)
    log_warn "Distribución no reconocida ($OS). Asegúrate de tener instalados: git, curl, zsh, tmux, fzf, ripgrep, git-delta."
    ;;
esac

# Asegurar enlace de fd si se instaló como fdfind (común en Debian/Ubuntu)
if has_cmd fdfind && ! has_cmd fd; then
  mkdir -p "$HOME/.local/bin"
  ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
  log_ok "Enlazado 'fdfind' como 'fd' en ~/.local/bin/fd"
fi

# Asegurar que delta esté disponible como comando si se instaló como git-delta
if has_cmd git-delta && ! has_cmd delta; then
  mkdir -p "$HOME/.local/bin"
  ln -sf "$(command -v git-delta)" "$HOME/.local/bin/delta"
  log_ok "Enlazado 'git-delta' como 'delta' en ~/.local/bin/delta"
fi

log_ok "Paquetes base instalados correctamente."

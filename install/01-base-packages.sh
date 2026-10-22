#!/usr/bin/env bash
# ==============================================================================
# install/01-base-packages.sh — Base packages and CLI utilities (Debian 13)
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/00-helpers.sh"

log_step "Installing essential system packages and CLI tools"

require_debian_13
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

# Debian ships fd as "fdfind"; expose it as "fd"
if has_cmd fdfind && ! has_cmd fd; then
  mkdir -p "$HOME/.local/bin"
  ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
  log_ok "Linked 'fdfind' as 'fd' in ~/.local/bin/fd"
fi

# Debian ships delta as "git-delta"; expose it as "delta"
if has_cmd git-delta && ! has_cmd delta; then
  mkdir -p "$HOME/.local/bin"
  ln -sf "$(command -v git-delta)" "$HOME/.local/bin/delta"
  log_ok "Linked 'git-delta' as 'delta' in ~/.local/bin/delta"
fi

log_ok "Base packages installed successfully."

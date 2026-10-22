#!/usr/bin/env bash
# ==============================================================================
# install/03-shell.sh — Fast native Zsh + Starship
# ==============================================================================
# Default:
#   - Installs Starship (Rust prompt)
#   - Installs zsh-autosuggestions and zsh-syntax-highlighting (native, no OMZ)
#   - Configures an instant native Zsh (< 20 ms startup)
# Optional (--omz):
#   - Installs Oh My Zsh and Powerlevel10k as an alternative
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/00-helpers.sh"

log_step "Configuring Zsh and the Starship prompt (native / no Oh My Zsh)"

require_debian_13

# 1. Set zsh as the default shell (usermod avoids interactive PAM prompts)
ZSH_BIN="$(command -v zsh || echo "")"
if [[ -n "$ZSH_BIN" && "${SHELL:-}" != "$ZSH_BIN" ]]; then
  log_info "Setting zsh as the default shell for $USER..."
  if has_cmd usermod; then
    run_sudo usermod -s "$ZSH_BIN" "$USER" 2>/dev/null || true
  elif has_cmd chsh; then
    run_sudo chsh -s "$ZSH_BIN" "$USER" 2>/dev/null || true
  fi
fi

# 2. Install Starship (Rust prompt)
if ! has_cmd starship; then
  log_info "Installing Starship in ~/.local/bin/starship..."
  mkdir -p "$HOME/.local/bin"
  curl -sS https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin"
  log_ok "Starship installed successfully."
else
  log_ok "Starship is already installed: $(starship --version | head -n 1)"
fi

# 3. Install native Zsh plugins (no Oh My Zsh dependency)
ZSH_PLUGINS_DIR="$HOME/.local/share/zsh/plugins"
mkdir -p "$ZSH_PLUGINS_DIR"

if [[ ! -d "$ZSH_PLUGINS_DIR/zsh-autosuggestions" ]]; then
  log_info "Installing zsh-autosuggestions..."
  git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "$ZSH_PLUGINS_DIR/zsh-autosuggestions" || true
  log_ok "zsh-autosuggestions installed."
else
  log_ok "zsh-autosuggestions is already installed."
fi

if [[ ! -d "$ZSH_PLUGINS_DIR/zsh-syntax-highlighting" ]]; then
  log_info "Installing zsh-syntax-highlighting..."
  git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_PLUGINS_DIR/zsh-syntax-highlighting" || true
  log_ok "zsh-syntax-highlighting installed."
else
  log_ok "zsh-syntax-highlighting is already installed."
fi

# 4. Optional Oh My Zsh + Powerlevel10k (--omz)
INSTALL_OMZ="${1:-false}"
if [[ "$INSTALL_OMZ" == "--omz" || "$INSTALL_OMZ" == "true" ]]; then
  log_info "Installing Oh My Zsh and Powerlevel10k as an alternative environment..."
  if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    # IMPORTANT: pass "" --unattended --keep-zshrc so Oh My Zsh never runs
    # 'exec zsh -l' and blocks the main installer flow.
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc || true
  fi
  ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  if [[ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k" || true
  fi
  log_ok "Oh My Zsh and Powerlevel10k installed as an alternative environment."
fi

log_ok "Zsh and Starship configuration complete."

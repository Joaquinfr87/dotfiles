#!/usr/bin/env bash
# ==============================================================================
# install/03-shell.sh — Configuración de Zsh, Oh My Zsh y plugins
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/00-helpers.sh"

log_step "Configurando Zsh, Oh My Zsh, Powerlevel10k y plugins"

# 1. Cambiar shell por defecto a zsh si no lo es
ZSH_BIN="$(command -v zsh || echo "")"
if [[ -n "$ZSH_BIN" && "${SHELL:-}" != "$ZSH_BIN" ]]; then
  log_info "Cambiando shell por defecto a zsh..."
  if has_cmd chsh; then
    chsh -s "$ZSH_BIN" "$USER" || log_warn "No se pudo cambiar la shell con chsh. Puedes ejecutar manualmente: chsh -s \$(which zsh)"
  fi
fi

# 2. Instalar Oh My Zsh de forma desatendida
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  log_info "Instalando Oh My Zsh..."
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || true
  log_ok "Oh My Zsh instalado."
else
  log_ok "Oh My Zsh ya está instalado."
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# 3. Tema Powerlevel10k
if [[ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]]; then
  log_info "Clonando Powerlevel10k..."
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
  log_ok "Powerlevel10k instalado."
else
  log_ok "Powerlevel10k ya está instalado."
fi

# 4. Plugins: zsh-autosuggestions
if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
  log_info "Instalando zsh-autosuggestions en custom plugins..."
  git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions" || true
fi

# 5. Plugins: zsh-syntax-highlighting
if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
  log_info "Instalando zsh-syntax-highlighting en custom plugins..."
  git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" || true
fi

log_ok "Configuración de shell completada."

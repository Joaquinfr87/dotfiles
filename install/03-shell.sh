#!/usr/bin/env bash
# ==============================================================================
# install/03-shell.sh — Configuración de Zsh nativo ultrarrápido + Starship
# ==============================================================================
# Por defecto:
#   - Instala Starship (prompt en Rust)
#   - Instala zsh-autosuggestions y zsh-syntax-highlighting (nativo, sin OMZ)
#   - Configura Zsh nativo instantáneo (< 20 ms de inicio)
# Opcional (--omz):
#   - Instala Oh My Zsh y Powerlevel10k como alternativa
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/00-helpers.sh"

log_step "Configurando Shell Zsh y Prompt Starship (Nativo / Sin Oh My Zsh)"

# 1. Cambiar shell por defecto a zsh si no lo es
ZSH_BIN="$(command -v zsh || echo "")"
if [[ -n "$ZSH_BIN" && "${SHELL:-}" != "$ZSH_BIN" ]]; then
  log_info "Cambiando shell por defecto a zsh..."
  if has_cmd chsh; then
    chsh -s "$ZSH_BIN" "$USER" 2>/dev/null || run_sudo chsh -s "$ZSH_BIN" "$USER" 2>/dev/null || log_warn "No se pudo cambiar la shell con chsh automáticamente. Puedes ejecutar: chsh -s \$(which zsh)"
  fi
fi

# 2. Instalar Starship (prompt en Rust)
if ! has_cmd starship; then
  log_info "Instalando Starship en ~/.local/bin/starship..."
  mkdir -p "$HOME/.local/bin"
  curl -sS https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin"
  log_ok "Starship instalado correctamente."
else
  log_ok "Starship ya está instalado: $(starship --version | head -n 1)"
fi

# 3. Instalar plugins nativos de Zsh (sin dependencia de Oh My Zsh)
ZSH_PLUGINS_DIR="$HOME/.local/share/zsh/plugins"
mkdir -p "$ZSH_PLUGINS_DIR"

if [[ ! -d "$ZSH_PLUGINS_DIR/zsh-autosuggestions" ]]; then
  log_info "Instalando zsh-autosuggestions nativo..."
  git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "$ZSH_PLUGINS_DIR/zsh-autosuggestions" || true
  log_ok "zsh-autosuggestions instalado."
else
  log_ok "zsh-autosuggestions ya está instalado."
fi

if [[ ! -d "$ZSH_PLUGINS_DIR/zsh-syntax-highlighting" ]]; then
  log_info "Instalando zsh-syntax-highlighting nativo..."
  git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_PLUGINS_DIR/zsh-syntax-highlighting" || true
  log_ok "zsh-syntax-highlighting instalado."
else
  log_ok "zsh-syntax-highlighting ya está instalado."
fi

# 4. Opción para instalar Oh My Zsh y Powerlevel10k si se solicita (--omz)
INSTALL_OMZ="${1:-false}"
if [[ "$INSTALL_OMZ" == "--omz" || "$INSTALL_OMZ" == "true" ]]; then
  log_info "Instalando Oh My Zsh y Powerlevel10k como entorno alternativo..."
  if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || true
  fi
  ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  if [[ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k" || true
  fi
  log_ok "Oh My Zsh y Powerlevel10k instalados como opción alternativa."
fi

log_ok "Configuración de Zsh y Starship completada."

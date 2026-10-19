#!/usr/bin/env bash
# ==============================================================================
# install/02-cli-tools.sh — Herramientas modernas de desarrollo (Neovim, Tmux, CLIs)
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/00-helpers.sh"

log_step "Instalando herramientas CLI modernas (Neovim, Tmux plugins, zoxide, eza, bat)"

mkdir -p "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"

# 1. Zoxide (reemplazo inteligente de cd)
if ! has_cmd zoxide; then
  log_info "Instalando zoxide..."
  curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
  log_ok "zoxide instalado en ~/.local/bin/zoxide"
else
  log_ok "zoxide ya está instalado."
fi

# 2. Bat (resaltado de sintaxis para cat)
if ! has_cmd bat && ! has_cmd batcat; then
  log_info "Instalando bat..."
  OS="$(detect_os)"
  if [[ "$OS" =~ ^(debian|ubuntu)$ ]]; then
    pkg_install bat || true
  fi
fi

# Enlazar batcat a bat en Debian/Ubuntu si es necesario
if has_cmd batcat && ! has_cmd bat; then
  ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
  log_ok "Enlazado 'batcat' como 'bat' en ~/.local/bin/bat"
fi

# 3. Eza (reemplazo moderno de ls)
if ! has_cmd eza; then
  log_info "Intentando instalar eza..."
  OS="$(detect_os)"
  if [[ "$OS" =~ ^(debian|ubuntu)$ ]]; then
    # Repositorio gierens para eza en Debian/Ubuntu si no está en apt nativo
    if ! apt-cache show eza >/dev/null 2>&1; then
      run_sudo mkdir -p /etc/apt/keyrings
      wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | run_sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg || true
      echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | run_sudo tee /etc/apt/sources.list.d/gierens.list >/dev/null || true
      run_sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list || true
      run_sudo apt update -y || true
    fi
    pkg_install eza || log_warn "No se pudo instalar eza automáticamente; se usarán los alias estándar."
  elif [[ "$OS" =~ ^(arch|cachyos|manjaro)$ ]]; then
    pkg_install eza || true
  elif [[ "$OS" == "fedora" ]]; then
    pkg_install eza || true
  fi
else
  log_ok "eza ya está instalado."
fi

# 4. Neovim (vía Bob o release oficial de GitHub)
if ! has_cmd nvim; then
  log_info "Instalando Neovim..."
  # Intentar vía Bob primero
  if curl -fsSL https://raw.githubusercontent.com/MordechaiHadad/bob/master/scripts/install.sh | bash; then
    log_ok "Bob instalado. Descargando Neovim stable..."
    "$HOME/.local/share/bob/nvim-bin/nvim" --version >/dev/null 2>&1 || bob use stable || true
    if [[ -x "$HOME/.local/share/bob/nvim-bin/nvim" ]]; then
      mkdir -p "$HOME/.local/bin"
      ln -sf "$HOME/.local/share/bob/nvim-bin/nvim" "$HOME/.local/bin/nvim"
    fi
  fi

  # Si aún no está en PATH o bob falló, descargar release precompilado
  if ! has_cmd nvim; then
    log_info "Descargando release precompilado de Neovim desde GitHub..."
    local temp_tar="/tmp/nvim-linux-x86_64.tar.gz"
    curl -fsSL -o "$temp_tar" https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
    mkdir -p "$HOME/.local"
    tar -C "$HOME/.local" -xzf "$temp_tar" --strip-components=1
    rm -f "$temp_tar"
    log_ok "Neovim instalado en ~/.local/bin/nvim"
  fi
else
  log_ok "Neovim ya está disponible: $(nvim --version | head -n 1)"
fi

# 5. Lazygit
if ! has_cmd lazygit; then
  log_info "Instalando lazygit..."
  OS="$(detect_os)"
  if [[ "$OS" =~ ^(debian|ubuntu)$ ]]; then
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*' || echo "")
    if [[ -n "$LAZYGIT_VERSION" ]]; then
      curl -Lo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
      tar xf /tmp/lazygit.tar.gz -C /tmp lazygit
      run_sudo install /tmp/lazygit /usr/local/bin
      rm -f /tmp/lazygit.tar.gz /tmp/lazygit
      log_ok "lazygit instalado en /usr/local/bin/lazygit"
    else
      pkg_install lazygit || true
    fi
  else
    pkg_install lazygit || true
  fi
else
  log_ok "lazygit ya está instalado."
fi

# 6. Plugins de Tmux (resurrect y continuum)
log_info "Configurando plugins de persistencia para Tmux..."
mkdir -p "$HOME/.config/tmux/plugins"
if [[ ! -d "$HOME/.config/tmux/plugins/tmux-resurrect" ]]; then
  git clone --depth 1 https://github.com/tmux-plugins/tmux-resurrect "$HOME/.config/tmux/plugins/tmux-resurrect"
  log_ok "Clonado tmux-resurrect"
fi
if [[ ! -d "$HOME/.config/tmux/plugins/tmux-continuum" ]]; then
  git clone --depth 1 https://github.com/tmux-plugins/tmux-continuum "$HOME/.config/tmux/plugins/tmux-continuum"
  log_ok "Clonado tmux-continuum"
fi

# 7. Git-delta (resaltador de sintaxis para git diff, log y blame)
if ! has_cmd delta && ! has_cmd git-delta; then
  log_info "Instalando git-delta..."
  OS="$(detect_os)"
  if [[ "$OS" =~ ^(debian|ubuntu|pop|linuxmint)$ ]]; then
    pkg_install git-delta || true
  elif [[ "$OS" =~ ^(arch|cachyos|manjaro)$ ]]; then
    pkg_install git-delta || true
  elif [[ "$OS" == "fedora" ]]; then
    pkg_install git-delta || true
  fi

  # Fallback a release binario oficial desde GitHub si no se instaló por paquete
  if ! has_cmd delta && ! has_cmd git-delta; then
    log_info "Descargando binario de delta desde GitHub..."
    local delta_url
    delta_url=$(curl -s "https://api.github.com/repos/dandavison/delta/releases/latest" | grep -Po '"browser_download_url": "\K[^"]*x86_64-unknown-linux-musl\.tar\.gz' | head -n 1 || echo "")
    if [[ -n "$delta_url" ]]; then
      curl -fsSL -o /tmp/delta.tar.gz "$delta_url"
      tar -xzf /tmp/delta.tar.gz -C /tmp
      mkdir -p "$HOME/.local/bin"
      if has_cmd sudo; then
        run_sudo install /tmp/delta-*/delta /usr/local/bin/delta 2>/dev/null || true
      fi
      cp /tmp/delta-*/delta "$HOME/.local/bin/delta" 2>/dev/null || true
      chmod +x "$HOME/.local/bin/delta" 2>/dev/null || true
      rm -rf /tmp/delta.tar.gz /tmp/delta-*
      log_ok "delta instalado en ~/.local/bin/delta"
    fi
  fi
fi

if has_cmd git-delta && ! has_cmd delta; then
  ln -sf "$(command -v git-delta)" "$HOME/.local/bin/delta"
fi

# Fallback stub para que Git nunca falle si no hay conexión o no se pudo descargar
if ! has_cmd delta; then
  mkdir -p "$HOME/.local/bin"
  cat << 'EOF' > "$HOME/.local/bin/delta"
#!/bin/sh
exec less -RFX "$@"
EOF
  chmod +x "$HOME/.local/bin/delta"
  log_warn "Se configuró fallback para delta (less)."
else
  log_ok "delta ya está disponible: $(delta --version 2>/dev/null | head -n 1)"
fi

log_ok "Herramientas CLI preparadas."

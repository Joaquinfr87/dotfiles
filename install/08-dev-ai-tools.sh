#!/usr/bin/env bash
# ==============================================================================
# install/08-dev-ai-tools.sh — Node.js, pnpm, Docker and AI agents (Debian 13)
# ==============================================================================
# Supports individual tools or a list:
#   ./install/08-dev-ai-tools.sh node pnpm docker opencode freebuff codex agy
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/00-helpers.sh"

log_step "Installing selected development tools and AI agents"

require_debian_13

mkdir -p "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$HOME/.opencode/bin:$PATH"

# Load NVM if it is already available
export NVM_DIR="$HOME/.nvm"
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
  set +u
  # shellcheck disable=SC1091
  \. "$NVM_DIR/nvm.sh"
  set -u
fi

# ------------------------------------------------------------------------------
# 1. Node.js LTS
# ------------------------------------------------------------------------------
install_node() {
  log_info "Setting up Node.js LTS..."
  export NVM_DIR="$HOME/.nvm"
  if [[ ! -d "$NVM_DIR" ]]; then
    log_info "Installing NVM (Node Version Manager)..."
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
  fi

  # Load NVM while temporarily allowing unset variables inside nvm.sh
  set +u
  # shellcheck disable=SC1091
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  if ! has_cmd node; then
    log_info "Downloading the latest Node LTS release..."
    nvm install --lts
    nvm use --lts
    nvm alias default 'lts/*'
  fi
  set -u

  # Link node, npm and npx into ~/.local/bin so every shell sees them immediately
  if has_cmd node; then
    mkdir -p "$HOME/.local/bin"
    ln -sf "$(command -v node)" "$HOME/.local/bin/node" 2>/dev/null || true
    ln -sf "$(command -v npm)" "$HOME/.local/bin/npm" 2>/dev/null || true
    ln -sf "$(command -v npx)" "$HOME/.local/bin/npx" 2>/dev/null || true
  fi
  log_ok "Node.js $(node --version 2>/dev/null || echo '') installed."
}

# ------------------------------------------------------------------------------
# 2. pnpm (fast Node package manager)
# ------------------------------------------------------------------------------
install_pnpm() {
  log_info "Setting up pnpm..."
  set +u
  [[ -s "$NVM_DIR/nvm.sh" ]] && \. "$NVM_DIR/nvm.sh"
  set -u
  if ! has_cmd pnpm; then
    if has_cmd npm; then
      log_info "Installing pnpm via npm..."
      npm install -g pnpm || true
    else
      log_info "Installing pnpm via the official script..."
      curl -fsSL https://get.pnpm.io/install.sh | sh - || true
    fi
  fi

  if has_cmd pnpm; then
    mkdir -p "$HOME/.local/bin"
    ln -sf "$(command -v pnpm)" "$HOME/.local/bin/pnpm" 2>/dev/null || true
    log_ok "pnpm available: $(pnpm --version)"
  fi
}

# ------------------------------------------------------------------------------
# 3. Docker & Docker Compose
# ------------------------------------------------------------------------------
install_docker() {
  log_info "Setting up Docker Engine and Docker Compose..."
  if ! has_cmd docker; then
    log_info "Downloading and installing Docker via the official script..."
    curl -fsSL https://get.docker.com | run_sudo sh
    log_ok "Docker Engine installed."
  else
    log_ok "Docker is already installed: $(docker --version)"
  fi

  # Allow the user to run docker without sudo
  if ! groups "$USER" | grep -q "\bdocker\b"; then
    log_info "Adding user '$USER' to the docker group..."
    run_sudo usermod -aG docker "$USER"
    log_ok "User added to the docker group (log out and back in to apply)."
  fi

  # Enable the systemd service
  if has_cmd systemctl; then
    run_sudo systemctl enable --now docker || true
  fi

  # Check the docker compose plugin
  if docker compose version >/dev/null 2>&1; then
    log_ok "Docker Compose is ready: $(docker compose version)"
  elif has_cmd docker-compose; then
    log_ok "Standalone docker-compose is available: $(docker-compose --version)"
  else
    log_info "Installing docker-compose-plugin via APT..."
    pkg_install docker-compose-plugin || true
  fi

  # Lazydocker
  if ! has_cmd lazydocker; then
    log_info "Installing Lazydocker..."
    curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash || true
    log_ok "Lazydocker installed in ~/.local/bin/lazydocker"
  fi
}

# ------------------------------------------------------------------------------
# 4. OpenCode CLI
# ------------------------------------------------------------------------------
install_opencode() {
  log_info "Setting up OpenCode CLI..."

  if has_cmd opencode; then
    log_ok "OpenCode is already installed: $(opencode --version 2>/dev/null || echo 'installed')"
    return
  fi

  mkdir -p "$HOME/.local/bin" "$HOME/.opencode/bin"

  # --no-modify-path: PATH is already managed by .zshrc and
  # environment.d/10-path.conf, so the installer must not add duplicate lines.
  log_info "Installing OpenCode from the official installer..."
  if curl -fsSL https://opencode.ai/v2/install | bash -s -- --no-modify-path; then
    log_ok "OpenCode installer finished."
  else
    log_warn "The OpenCode installer returned an error; looking for the binary anyway."
  fi

  # Link the binary into ~/.local/bin so any shell can find it
  local candidate
  for candidate in "$HOME/.opencode/bin/opencode" "$HOME/.local/bin/opencode"; do
    if [[ -x "$candidate" ]]; then
      ln -sf "$candidate" "$HOME/.local/bin/opencode"
      break
    fi
  done

  export PATH="$HOME/.local/bin:$HOME/.opencode/bin:$PATH"
  if has_cmd opencode; then
    log_ok "OpenCode installed: $(opencode --version 2>/dev/null || echo 'OK')"
  else
    log_err "The OpenCode binary was not found after installation."
    log_warn "Check the output above or run it manually:"
    log_warn "  curl -fsSL https://opencode.ai/v2/install | bash"
  fi
}

# ------------------------------------------------------------------------------
# 5. Freebuff CLI
# ------------------------------------------------------------------------------
install_freebuff() {
  log_info "Setting up Freebuff CLI..."
  set +u
  [[ -s "$NVM_DIR/nvm.sh" ]] && \. "$NVM_DIR/nvm.sh"
  set -u
  if ! has_cmd freebuff; then
    if has_cmd npm; then
      log_info "Installing freebuff via npm..."
      npm install -g freebuff || true
    else
      log_warn "Node/npm is required to install Freebuff. Install Node first."
    fi
  fi

  if has_cmd freebuff; then
    mkdir -p "$HOME/.local/bin"
    ln -sf "$(command -v freebuff)" "$HOME/.local/bin/freebuff" 2>/dev/null || true
    log_ok "Freebuff available: $(freebuff --version 2>/dev/null || echo 'installed')"
  fi
}

# ------------------------------------------------------------------------------
# 6. Codex CLI
# ------------------------------------------------------------------------------
install_codex() {
  log_info "Setting up Codex CLI..."
  set +u
  [[ -s "$NVM_DIR/nvm.sh" ]] && \. "$NVM_DIR/nvm.sh"
  set -u

  if has_cmd codex; then
    log_ok "Codex CLI is already available: $(codex --version 2>/dev/null || echo 'installed')"
    return
  fi

  if has_cmd npm; then
    log_info "Installing Codex CLI via npm..."
    npm install -g @openai/codex || true
  else
    log_warn "Node/npm is required to install Codex CLI. Install Node first."
  fi

  if has_cmd codex; then
    mkdir -p "$HOME/.local/bin"
    ln -sf "$(command -v codex)" "$HOME/.local/bin/codex" 2>/dev/null || true
    log_ok "Codex CLI available: $(codex --version 2>/dev/null || echo 'installed')"
  fi
}

# ------------------------------------------------------------------------------
# 7. Antigravity CLI (agy)
# ------------------------------------------------------------------------------
install_agy() {
  log_info "Setting up Antigravity CLI (agy)..."

  if has_cmd agy; then
    log_ok "Antigravity CLI (agy) is already installed: $(agy --version 2>/dev/null || echo 'installed')"
    return
  fi

  mkdir -p "$HOME/.local/bin"

  # Official Google installer (binary in ~/.local/bin/agy)
  log_info "Installing Antigravity CLI from Google's official installer..."
  if curl -fsSL https://antigravity.google/cli/install.sh | bash; then
    log_ok "Antigravity CLI installer finished."
  else
    log_warn "The Antigravity CLI installer returned an error."
  fi

  # The installer appends an "export PATH=~/.local/bin" block to shell profiles.
  # Our dotfiles already include ~/.local/bin, so drop the duplicate block to
  # keep `dot-sync diff` clean.
  local profile tmp
  for profile in "$HOME/.zshrc" "$HOME/.zprofile" "$HOME/.bashrc" "$HOME/.profile"; do
    [[ -f "$profile" ]] || continue
    if grep -q "# Added by Antigravity CLI installer" "$profile"; then
      tmp="$(mktemp)"
      awk '
        /# Added by Antigravity CLI installer/ { skip = 1; next }
        skip > 0 { skip--; next }
        { print }
      ' "$profile" > "$tmp" && mv "$tmp" "$profile"
    fi
  done

  export PATH="$HOME/.local/bin:$PATH"
  if has_cmd agy; then
    log_ok "Antigravity CLI (agy) installed: $(agy --version 2>/dev/null || echo 'OK')"
  else
    log_err "'agy' was not found after installation."
    log_warn "Install it manually with:"
    log_warn "  curl -fsSL https://antigravity.google/cli/install.sh | bash"
    log_warn "And make sure ~/.local/bin is in your PATH."
  fi
}

# ------------------------------------------------------------------------------
# Dispatcher
# ------------------------------------------------------------------------------
if [[ $# -eq 0 ]]; then
  echo "Usage: $0 [node|pnpm|docker|opencode|freebuff|codex|agy|all] ..."
  exit 0
fi

for tool in "$@"; do
  case "$tool" in
    all)
      install_node
      install_pnpm
      install_docker
      install_opencode
      install_freebuff
      install_codex
      install_agy
      ;;
    node) install_node ;;
    pnpm) install_pnpm ;;
    docker) install_docker ;;
    opencode) install_opencode ;;
    freebuff) install_freebuff ;;
    codex) install_codex ;;
    agy) install_agy ;;
    *)
      log_warn "Unknown tool: $tool"
      ;;
  esac
done

log_ok "Selected tools installed."

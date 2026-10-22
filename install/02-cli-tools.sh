#!/usr/bin/env bash
# ==============================================================================
# install/02-cli-tools.sh — Modern CLI tooling (Neovim, Tmux plugins, zoxide…)
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/00-helpers.sh"

log_step "Installing modern CLI tools (Neovim, Tmux plugins, zoxide, eza, bat)"

require_debian_13
mkdir -p "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"

# 1. zoxide (smarter cd)
if ! has_cmd zoxide; then
  log_info "Installing zoxide..."
  curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
  log_ok "zoxide installed in ~/.local/bin/zoxide"
else
  log_ok "zoxide is already installed."
fi

# 2. bat (syntax highlighting for cat)
if ! has_cmd bat && ! has_cmd batcat; then
  log_info "Installing bat..."
  pkg_install bat || true
fi

# Debian installs it as "batcat"
if has_cmd batcat && ! has_cmd bat; then
  ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
  log_ok "Linked 'batcat' as 'bat' in ~/.local/bin/bat"
fi

# 3. eza (modern ls)
if ! has_cmd eza; then
  log_info "Installing eza..."
  if ! apt-cache show eza >/dev/null 2>&1; then
    # Use the gierens repository when eza is not available in Debian
    run_sudo mkdir -p /etc/apt/keyrings
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | run_sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg || true
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | run_sudo tee /etc/apt/sources.list.d/gierens.list >/dev/null || true
    run_sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list || true
    run_sudo apt-get update -y || true
  fi
  pkg_install eza || log_warn "Could not install eza automatically; standard aliases will be used."
else
  log_ok "eza is already installed."
fi

# 4. Neovim (via Bob, falling back to the official prebuilt release)
if ! has_cmd nvim; then
  log_info "Installing Neovim..."
  if curl -fsSL https://raw.githubusercontent.com/MordechaiHadad/bob/master/scripts/install.sh | bash; then
    log_ok "Bob installed. Downloading Neovim stable..."
    "$HOME/.local/share/bob/nvim-bin/nvim" --version >/dev/null 2>&1 || bob use stable || true
    if [[ -x "$HOME/.local/share/bob/nvim-bin/nvim" ]]; then
      mkdir -p "$HOME/.local/bin"
      ln -sf "$HOME/.local/share/bob/nvim-bin/nvim" "$HOME/.local/bin/nvim"
    fi
  fi

  if ! has_cmd nvim; then
    log_info "Downloading prebuilt Neovim release from GitHub..."
    temp_tar="/tmp/nvim-linux-x86_64.tar.gz"
    curl -fsSL -o "$temp_tar" https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
    mkdir -p "$HOME/.local"
    tar -C "$HOME/.local" -xzf "$temp_tar" --strip-components=1
    rm -f "$temp_tar"
    log_ok "Neovim installed in ~/.local/bin/nvim"
  fi
else
  log_ok "Neovim is already available: $(nvim --version | head -n 1)"
fi

# 5. Lazygit
if ! has_cmd lazygit; then
  log_info "Installing lazygit..."
  LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*' || echo "")
  if [[ -n "$LAZYGIT_VERSION" ]]; then
    curl -Lo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    tar xf /tmp/lazygit.tar.gz -C /tmp lazygit
    run_sudo install /tmp/lazygit /usr/local/bin
    rm -f /tmp/lazygit.tar.gz /tmp/lazygit
    log_ok "lazygit installed in /usr/local/bin/lazygit"
  else
    pkg_install lazygit || true
  fi
else
  log_ok "lazygit is already installed."
fi

# 6. Tmux plugins (resurrect and continuum)
log_info "Setting up Tmux persistence plugins..."
mkdir -p "$HOME/.config/tmux/plugins"
if [[ ! -d "$HOME/.config/tmux/plugins/tmux-resurrect" ]]; then
  git clone --depth 1 https://github.com/tmux-plugins/tmux-resurrect "$HOME/.config/tmux/plugins/tmux-resurrect"
  log_ok "Cloned tmux-resurrect"
fi
if [[ ! -d "$HOME/.config/tmux/plugins/tmux-continuum" ]]; then
  git clone --depth 1 https://github.com/tmux-plugins/tmux-continuum "$HOME/.config/tmux/plugins/tmux-continuum"
  log_ok "Cloned tmux-continuum"
fi

# 7. git-delta (syntax highlighter for git diff, log and blame)
if ! has_cmd delta && ! has_cmd git-delta; then
  log_info "Installing git-delta..."
  pkg_install git-delta || true

  # Fallback to the official static binary from GitHub
  if ! has_cmd delta && ! has_cmd git-delta; then
    log_info "Downloading the delta binary from GitHub..."
    delta_url=$(curl -s "https://api.github.com/repos/dandavison/delta/releases/latest" | grep -Po '"browser_download_url": "\K[^"]*x86_64-unknown-linux-musl\.tar\.gz' | head -n 1 || echo "")
    if [[ -n "$delta_url" ]]; then
      curl -fsSL -o /tmp/delta.tar.gz "$delta_url"
      tar -xzf /tmp/delta.tar.gz -C /tmp
      mkdir -p "$HOME/.local/bin"
      run_sudo install /tmp/delta-*/delta /usr/local/bin/delta 2>/dev/null || true
      cp /tmp/delta-*/delta "$HOME/.local/bin/delta" 2>/dev/null || true
      chmod +x "$HOME/.local/bin/delta" 2>/dev/null || true
      rm -rf /tmp/delta.tar.gz /tmp/delta-*
      log_ok "delta installed in ~/.local/bin/delta"
    fi
  fi
fi

if has_cmd git-delta && ! has_cmd delta; then
  ln -sf "$(command -v git-delta)" "$HOME/.local/bin/delta"
fi

# Last-resort fallback so Git never fails when delta is unavailable
if ! has_cmd delta; then
  mkdir -p "$HOME/.local/bin"
  cat << 'EOF' > "$HOME/.local/bin/delta"
#!/bin/sh
exec less -RFX "$@"
EOF
  chmod +x "$HOME/.local/bin/delta"
  log_warn "Configured a fallback for delta (less)."
else
  log_ok "delta is available: $(delta --version 2>/dev/null | head -n 1)"
fi

log_ok "CLI tools ready."

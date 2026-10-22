#!/usr/bin/env bash
# ==============================================================================
# install/05-noctalia.sh — Noctalia v5 repository, shell and greeter (Debian 13)
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/00-helpers.sh"

log_step "Installing Noctalia v5 and the Noctalia Greeter (login manager)"

require_debian_13

# 1. Official Noctalia repository
if ! has_cmd noctalia; then
  log_info "Configuring the official Noctalia repository for Debian..."
  KEYRING_DEB="/tmp/nickh-archive-keyring.deb"
  curl -fsSL -o "$KEYRING_DEB" https://pkg.noctalia.dev/deb/nickh-archive-keyring.deb
  run_sudo dpkg -i "$KEYRING_DEB"
  rm -f "$KEYRING_DEB"

  curl -fsSL https://pkg.noctalia.dev/deb/noctalia-trixie.sources | run_sudo tee /etc/apt/sources.list.d/noctalia-trixie.sources >/dev/null || true

  # APT pinning so the Noctalia trixie repository keeps normal priority (500)
  # and resolves dependencies such as libwlroots and libdrm2 without conflicts.
  run_sudo mkdir -p /etc/apt/preferences.d
  run_sudo bash -c 'cat << "EOF" > /etc/apt/preferences.d/noctalia.pref
Package: *
Pin: origin "pkg.noctalia.dev"
Pin-Priority: 500
EOF'

  run_sudo apt-get update -y
  pkg_install noctalia || log_warn "Could not install Noctalia via APT. Check https://docs.noctalia.dev"
  log_ok "Noctalia v5 installed."
else
  # Keep the pinning file in place if the repository was configured before
  if [[ ! -f /etc/apt/preferences.d/noctalia.pref && -f /etc/apt/sources.list.d/noctalia-trixie.sources ]]; then
    run_sudo mkdir -p /etc/apt/preferences.d
    run_sudo bash -c 'cat << "EOF" > /etc/apt/preferences.d/noctalia.pref
Package: *
Pin: origin "pkg.noctalia.dev"
Pin-Priority: 500
EOF'
  fi
  log_ok "Noctalia is already installed: $(noctalia --version 2>/dev/null || echo 'v5')"
fi

# 2. Noctalia Greeter + greetd
log_info "Installing greetd..."
pkg_install greetd || true

log_info "Installing noctalia-greeter..."
run_sudo apt-get install -y -t trixie-backports noctalia-greeter 2>/dev/null || pkg_install noctalia-greeter || true

# Configure /etc/greetd/config.toml
log_info "Configuring /etc/greetd/config.toml for noctalia-greeter..."
run_sudo mkdir -p /etc/greetd
run_sudo bash -c 'cat << "EOF" > /etc/greetd/config.toml
[terminal]
vt = 7

[default_session]
command = "/usr/bin/noctalia-greeter-session"
user = "_greetd"
EOF'

# Configure /var/lib/noctalia-greeter/greeter.toml and the wallpaper
log_info "Configuring the Noctalia Greeter theme and wallpaper..."
run_sudo mkdir -p /var/lib/noctalia-greeter
if [[ -f "$DOTFILES_DIR/noctalia-greeter/greeter.toml" ]]; then
  # Replace ONLY the default user in the [user] section. The [session] default
  # must stay "sway" (a global sed used to rewrite it to "$USER" too, which
  # prevented the greeter from launching the session).
  awk -v user="$USER" '
    /^\[user\]/ { in_user = 1; print; next }
    /^\[/      { in_user = 0 }
    in_user && /^default[[:space:]]*=/ {
      print "default = \"" user "\""
      next
    }
    { print }
  ' "$DOTFILES_DIR/noctalia-greeter/greeter.toml" | run_sudo tee /var/lib/noctalia-greeter/greeter.toml >/dev/null
fi

# Copy the wallpaper used by the greeter
if [[ -f "$DOTFILES_DIR/Pictures/wallpaper4.png" ]]; then
  run_sudo cp "$DOTFILES_DIR/Pictures/wallpaper4.png" /var/lib/noctalia-greeter/wallpaper.png
fi

# Fix permissions for the display-manager user
if id "_greetd" >/dev/null 2>&1; then
  run_sudo chown -R _greetd:_greetd /var/lib/noctalia-greeter 2>/dev/null || true
fi
run_sudo chmod -R 755 /var/lib/noctalia-greeter 2>/dev/null || true

# Enable greetd when its unit is installed
if has_cmd systemctl; then
  if systemctl list-unit-files 2>/dev/null | grep -q "^greetd\.service"; then
    log_info "Enabling greetd in systemd..."
    run_sudo systemctl enable greetd || true
    log_ok "Noctalia Greeter configured and enabled."
  else
    log_warn "greetd.service is not registered in systemd."
  fi
fi

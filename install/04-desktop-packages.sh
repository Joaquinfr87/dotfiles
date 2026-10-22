#!/usr/bin/env bash
# ==============================================================================
# install/04-desktop-packages.sh — Sway, Wayland, PipeWire and desktop tools
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/00-helpers.sh"

log_step "Installing Sway, Wayland, PipeWire and desktop portals"

require_debian_13

pkg_update
pkg_install \
  sway \
  xwayland \
  kanshi \
  wl-clipboard \
  pavucontrol \
  gnome-keyring \
  pipewire \
  wireplumber \
  pipewire-pulse \
  xdg-desktop-portal \
  xdg-desktop-portal-wlr \
  xdg-desktop-portal-gtk \
  fonts-noto-color-emoji \
  bluez \
  kmod \
  xz-utils

# Remove foot (Sway's default terminal on Debian) so Kitty is the only terminal
if has_cmd foot || dpkg -s foot >/dev/null 2>&1; then
  log_info "Removing foot to make sure Kitty is the default terminal..."
  run_sudo apt-get purge -y foot foot-themes 2>/dev/null || true
fi

# Enable PipeWire services for the user session
if has_cmd systemctl; then
  log_info "Enabling PipeWire audio services for the user..."
  systemctl --user enable --now pipewire wireplumber pipewire-pulse || true
  log_ok "PipeWire services are active."
fi

# ------------------------------------------------------------------------------
# Bluetooth: fast Noctalia startup
# ------------------------------------------------------------------------------
# On startup Noctalia registers a Bluetooth agent. When org.bluez is not present
# on the system bus, that D-Bus call blocks for 25 s (sdbus timeout) and stalls
# the shell's "initServices" phase:
#   [WRN] [app] startup phase initServices took 25296.5ms
#
# bluetooth.service does not start on a cold boot because its
# ConditionPathIsDirectory=/sys/class/bluetooth fails while the kernel module is
# not loaded. Loading and persisting the module lets bluetoothd own org.bluez
# from the very first second, even on machines without a Bluetooth adapter.
setup_bluetooth_fast_start() {
  log_info "Preparing Bluetooth so Noctalia starts without delays..."

  local modprobe_bin=""
  for modprobe_bin in /usr/sbin/modprobe /sbin/modprobe "$(command -v modprobe 2>/dev/null || true)"; do
    [[ -n "$modprobe_bin" && -x "$modprobe_bin" ]] && break
  done
  if [[ -n "$modprobe_bin" && -x "$modprobe_bin" ]]; then
    run_sudo "$modprobe_bin" bluetooth 2>/dev/null || true
  else
    log_warn "Could not find 'modprobe' (kmod package); continuing anyway."
  fi

  # Persist the module so /sys/class/bluetooth exists on every boot
  echo "bluetooth" | run_sudo tee /etc/modules-load.d/bluetooth.conf >/dev/null 2>&1 || true

  # bluetooth.service is only WantedBy=bluetooth.target, a static target that
  # nothing pulls in at boot. Hook it into multi-user.target as well.
  if has_cmd systemctl; then
    run_sudo systemctl enable bluetooth 2>/dev/null || true
    run_sudo systemctl add-wants multi-user.target bluetooth.service 2>/dev/null \
      || run_sudo systemctl enable bluetooth 2>/dev/null || true
    run_sudo systemctl start bluetooth 2>/dev/null || true

    # Give org.bluez a few seconds to appear on the bus
    local i
    for i in 1 2 3 4 5; do
      systemctl is-active --quiet bluetooth 2>/dev/null && break
      sleep 1
    done
  fi

  if systemctl is-active --quiet bluetooth 2>/dev/null; then
    if has_cmd busctl && busctl --system status org.bluez >/dev/null 2>&1; then
      log_ok "bluetoothd is active and org.bluez is on the bus: Noctalia will start instantly."
    else
      log_ok "bluetoothd is active: Noctalia will not hit the 25 s timeout."
    fi
  else
    log_warn "bluetoothd is not active; Noctalia may take ~25 s to start."
    log_warn "Diagnose with: systemctl status bluetooth && ls /sys/class/bluetooth"
  fi
}
setup_bluetooth_fast_start

# Install Kitty using Kovid Goyal's official installer
if [[ ! -x "$HOME/.local/kitty.app/bin/kitty" ]] && ! has_cmd kitty; then
  log_info "Installing Kitty from the official installer (https://sw.kovidgoyal.net/kitty/installer.sh)..."
  curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
  mkdir -p "$HOME/.local/bin" "$HOME/.local/share"
  ln -sf "$HOME/.local/kitty.app/bin/kitty" "$HOME/.local/bin/kitty"
  ln -sf "$HOME/.local/kitty.app/bin/kitten" "$HOME/.local/bin/kitten"
  run_sudo ln -sf "$HOME/.local/kitty.app/bin/kitty" /usr/local/bin/kitty 2>/dev/null || true
  run_sudo ln -sf "$HOME/.local/kitty.app/bin/kitten" /usr/local/bin/kitten 2>/dev/null || true
  if [[ -d "$HOME/.local/kitty.app/share" ]]; then
    cp -as "$HOME/.local/kitty.app/share/"* "$HOME/.local/share/" 2>/dev/null || true
  fi
  log_ok "Kitty installed in ~/.local/bin/kitty and linked to /usr/local/bin/kitty"
else
  # Keep both ~/.local/bin and /usr/local/bin symlinks in place
  mkdir -p "$HOME/.local/bin"
  if [[ -x "$HOME/.local/kitty.app/bin/kitty" ]]; then
    ln -sf "$HOME/.local/kitty.app/bin/kitty" "$HOME/.local/bin/kitty"
    ln -sf "$HOME/.local/kitty.app/bin/kitten" "$HOME/.local/bin/kitten"
    run_sudo ln -sf "$HOME/.local/kitty.app/bin/kitty" /usr/local/bin/kitty 2>/dev/null || true
    run_sudo ln -sf "$HOME/.local/kitty.app/bin/kitten" /usr/local/bin/kitten 2>/dev/null || true
  fi
  log_ok "Kitty is already installed: $(kitty --version 2>/dev/null || echo 'OK')"
fi

# System integration (icons, .desktop entry and x-terminal-emulator)
if [[ -f "$HOME/.local/share/applications/kitty.desktop" ]]; then
  run_sudo cp -f "$HOME/.local/share/applications/kitty.desktop" /usr/share/applications/ 2>/dev/null || true
fi
if has_cmd update-alternatives && [[ -x /usr/local/bin/kitty ]]; then
  run_sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator /usr/local/bin/kitty 50 2>/dev/null || true
  run_sudo update-alternatives --set x-terminal-emulator /usr/local/bin/kitty 2>/dev/null || true
fi

# bluetuith (Bluetooth TUI)
if ! has_cmd bluetuith; then
  log_info "Installing bluetuith (Bluetooth TUI)..."
  mkdir -p "$HOME/.local/bin"
  BLUETUITH_URL=$(curl -s https://api.github.com/repos/bluetuith-org/bluetuith/releases/latest | grep -o "https://[^\"]*Linux_x86_64\.tar\.gz" | head -n 1 || echo "")
  if [[ -n "$BLUETUITH_URL" ]]; then
    curl -fsSL -o /tmp/bluetuith.tar.gz "$BLUETUITH_URL"
    tar -xzf /tmp/bluetuith.tar.gz -C "$HOME/.local/bin" bluetuith 2>/dev/null || tar -xzf /tmp/bluetuith.tar.gz -C "$HOME/.local/bin"
    rm -f /tmp/bluetuith.tar.gz
    chmod +x "$HOME/.local/bin/bluetuith" 2>/dev/null || true
    run_sudo ln -sf "$HOME/.local/bin/bluetuith" /usr/local/bin/bluetuith 2>/dev/null || true
    log_ok "bluetuith installed in ~/.local/bin/bluetuith"
  fi
else
  log_ok "bluetuith is already installed."
fi

log_ok "Sway and Wayland base environment complete."

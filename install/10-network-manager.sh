#!/usr/bin/env bash
# ==============================================================================
# install/10-network-manager.sh — Switch the network backend to NetworkManager
# ==============================================================================
# Noctalia's network widget and Control Center talk to NetworkManager through
# nmcli/D-Bus, so the desktop profile must not leave ifupdown owning the NICs.
#
# This module:
#   1. Installs NetworkManager and its Wi-Fi backend.
#   2. Backs up /etc/network/interfaces and the ifupdown/wpa_supplicant config.
#   3. Stops and disables ifupdown (networking.service).
#   4. Replaces /etc/network/interfaces with a loopback-only file.
#   5. Enables and starts NetworkManager.
#   6. Adds the desktop user to the netdev group (PolicyKit access).
#
# Usage:
#   ./install/10-network-manager.sh            # ask for confirmation
#   ./install/10-network-manager.sh --yes      # unattended switch
#   ./install/10-network-manager.sh --restore  # go back to ifupdown
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/00-helpers.sh"

require_debian_13

ASSUME_YES=false
RESTORE=false
for arg in "$@"; do
  case "$arg" in
    -y|--yes)
      ASSUME_YES=true
      ;;
    --restore)
      RESTORE=true
      ;;
    -h|--help)
      echo "Usage: $0 [--yes|--restore]"
      echo ""
      echo "  --yes       Switch to NetworkManager without asking for confirmation"
      echo "  --restore   Restore the ifupdown configuration saved by this installer"
      exit 0
      ;;
    *)
      log_warn "Unrecognized argument: $arg"
      ;;
  esac
done

INTERFACES_FILE="/etc/network/interfaces"
INTERFACES_BACKUP="/etc/network/interfaces.dotfiles-ifupdown-backup"
NM_MARKER="/etc/network/.dotfiles-networkmanager"

# ------------------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------------------
nm_is_active() {
  has_cmd nmcli && [[ "$(nmcli -t -f RUNNING general 2>/dev/null || true)" == "running" ]]
}

ifupdown_is_active() {
  systemctl is-active --quiet networking.service 2>/dev/null
}

networkmanager_installed() {
  dpkg -s network-manager >/dev/null 2>&1 && has_cmd nmcli
}

show_switch_warning() {
  cat <<'EOF'
This step changes the network backend from Debian's ifupdown to NetworkManager:

  - NetworkManager will be installed and enabled.
  - networking.service (ifupdown) will be stopped and disabled.
  - /etc/network/interfaces will be replaced with a loopback-only file.
  - Existing Wi-Fi credentials are NOT imported automatically.

Network connectivity can drop for a few seconds. If you are connected over SSH
or Wi-Fi, configure the connection in NetworkManager before closing the session,
or run this step later from a local terminal.

The original files are saved under /var/backups and in:
  /etc/network/interfaces.dotfiles-ifupdown-backup
EOF
}

confirm_switch() {
  [[ "$ASSUME_YES" == "true" ]] && return 0

  local default_answer="Y"
  local prompt="Switch to NetworkManager now? [Y/n]: "

  if [[ -n "${SSH_CONNECTION:-}" ]]; then
    log_warn "SSH session detected: switching the network backend may lock you out."
    default_answer="N"
    prompt="Switch to NetworkManager now? [y/N]: "
  fi

  local reply
  read -r -p "$prompt" reply
  reply="${reply:-$default_answer}"
  case "${reply,,}" in
    y|yes) return 0 ;;
    *) return 1 ;;
  esac
}

ensure_netdev_group() {
  if ! getent group netdev >/dev/null 2>&1; then
    log_warn "The 'netdev' group does not exist; NetworkManager may ask for authentication."
    return 0
  fi

  if id -nG "$USER" 2>/dev/null | tr ' ' '\n' | grep -qx netdev; then
    log_ok "User '$USER' is already in the 'netdev' group."
  else
    run_sudo usermod -aG netdev "$USER"
    log_ok "Added '$USER' to the 'netdev' group (log out and back in to apply)."
  fi
}

backup_ifupdown_config() {
  # Never overwrite an original backup with an already-trimmed file.
  if [[ -f "$INTERFACES_BACKUP" ]]; then
    log_info "The ifupdown backup already exists; keeping the original copy."
    if [[ ! -f "$NM_MARKER" ]]; then
      printf 'backend=NetworkManager\nbackup=%s\n' "$INTERFACES_BACKUP" \
        | run_sudo tee "$NM_MARKER" >/dev/null
    fi
    return 0
  fi

  local stamp backup_dir
  stamp="$(date +%Y%m%d_%H%M%S)"
  backup_dir="/var/backups/dotfiles-network-$stamp"
  run_sudo install -d -m 0755 "$backup_dir"

  if [[ -f "$INTERFACES_FILE" ]]; then
    run_sudo cp -a "$INTERFACES_FILE" "$backup_dir/interfaces"
    run_sudo cp -a "$INTERFACES_FILE" "$INTERFACES_BACKUP"
  else
    # Keep a usable rollback file even on unusual minimal installations.
    printf 'auto lo\niface lo inet loopback\n' | run_sudo tee "$INTERFACES_BACKUP" >/dev/null
  fi

  if [[ -d /etc/network/interfaces.d ]]; then
    run_sudo cp -a /etc/network/interfaces.d "$backup_dir/interfaces.d" 2>/dev/null || true
  fi

  if [[ -f /etc/wpa_supplicant/wpa_supplicant.conf ]]; then
    run_sudo cp -a /etc/wpa_supplicant/wpa_supplicant.conf "$backup_dir/wpa_supplicant.conf" 2>/dev/null || true
  fi

  {
    printf 'backend=NetworkManager\n'
    printf 'created=%s\n' "$(date -Iseconds)"
    printf 'backup=%s\n' "$backup_dir"
  } | run_sudo tee "$NM_MARKER" >/dev/null

  log_ok "Network configuration backed up to $backup_dir"
}

write_loopback_only_interfaces() {
  log_info "Removing interface definitions from $INTERFACES_FILE so NetworkManager can own them..."
  printf 'auto lo\niface lo inet loopback\n' | run_sudo tee "$INTERFACES_FILE" >/dev/null
  run_sudo chmod 600 "$INTERFACES_FILE"
}

disable_ifupdown() {
  if systemctl cat networking.service >/dev/null 2>&1; then
    log_info "Stopping and disabling ifupdown (networking.service)..."
    if run_sudo systemctl disable --now networking.service 2>/dev/null; then
      log_ok "ifupdown is stopped and disabled."
    else
      log_warn "networking.service could not be stopped cleanly; a reboot may be needed."
    fi
  else
    log_info "networking.service is not installed; nothing to disable."
  fi

  # Optional helper unit: do not leave a boot-time wait for ifupdown.
  run_sudo systemctl disable --now ifupdown-wait-online.service 2>/dev/null || true
}

start_networkmanager() {
  log_info "Enabling and starting NetworkManager..."
  run_sudo systemctl enable NetworkManager.service
  if ! run_sudo systemctl restart NetworkManager.service; then
    log_err "NetworkManager could not be started."
    return 1
  fi

  # Wait until the D-Bus API is reachable before using nmcli.
  local _
  for _ in $(seq 1 20); do
    if nmcli -t general status >/dev/null 2>&1; then
      break
    fi
    sleep 1
  done

  if ! nmcli -t general status >/dev/null 2>&1; then
    log_err "NetworkManager is running but nmcli cannot reach it yet."
    return 1
  fi

  run_sudo nmcli networking on >/dev/null 2>&1 || true
  run_sudo nmcli radio wifi on >/dev/null 2>&1 || true
  return 0
}

wait_for_connection() {
  local _ state
  for _ in $(seq 1 25); do
    state="$(nmcli -t -f STATE general 2>/dev/null || true)"
    case "$state" in
      connected|connected\ \(local\ only\)|connected\ \(site\ only\))
        return 0
        ;;
    esac
    sleep 1
  done
  return 1
}

print_network_status() {
  log_info "NetworkManager device status:"
  nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device status 2>/dev/null || true
}

restore_ifupdown() {
  log_step "Restoring the ifupdown network backend"

  if [[ ! -f "$INTERFACES_BACKUP" ]]; then
    log_err "No backup found at $INTERFACES_BACKUP; cannot restore ifupdown."
    exit 1
  fi

  log_info "Restoring the original $INTERFACES_FILE..."
  run_sudo cp -a "$INTERFACES_BACKUP" "$INTERFACES_FILE"

  log_info "Disabling NetworkManager..."
  run_sudo systemctl disable --now NetworkManager.service 2>/dev/null || true

  log_info "Enabling and starting ifupdown..."
  run_sudo systemctl enable --now networking.service 2>/dev/null || true

  run_sudo rm -f "$NM_MARKER"

  if systemctl is-active --quiet networking.service 2>/dev/null; then
    log_ok "ifupdown is active again. NetworkManager has been disabled."
  else
    log_warn "ifupdown was restored but its service is not active yet."
    log_warn "Try: sudo systemctl restart networking.service"
  fi
}

# ------------------------------------------------------------------------------
# Main
# ------------------------------------------------------------------------------
if [[ "$RESTORE" == "true" ]]; then
  restore_ifupdown
  exit 0
fi

if nm_is_active && ! ifupdown_is_active; then
  log_step "Network backend: NetworkManager"
  log_ok "NetworkManager is already the active backend; nothing to change."
  ensure_netdev_group
  print_network_status
  exit 0
fi

log_step "Switching the network backend to NetworkManager (Noctalia integration)"
show_switch_warning
echo ""

if ! confirm_switch; then
  log_info "Network backend switch skipped."
  # Distinct exit code so install.sh can report that ifupdown is still in use.
  exit 2
fi

if ! networkmanager_installed; then
  log_info "Installing NetworkManager and the Wi-Fi backend..."
  pkg_install network-manager wpasupplicant wireless-regdb
fi

if ! networkmanager_installed; then
  log_err "NetworkManager is not available after the package installation."
  log_err "The ifupdown configuration was left untouched so you keep connectivity."
  exit 1
fi

ensure_netdev_group
backup_ifupdown_config

# Stop ifupdown first: its ifdown step needs the original interfaces file to
# release the currently active links before NetworkManager takes them over.
disable_ifupdown
write_loopback_only_interfaces

if ! start_networkmanager; then
  log_err "NetworkManager could not be started."
  log_warn "Restoring ifupdown automatically so you keep connectivity..."
  restore_ifupdown || true
  exit 1
fi

if wait_for_connection; then
  log_ok "NetworkManager is active and connected."
else
  log_warn "NetworkManager is active, but no connection is up yet."
  log_warn "Connect to Wi-Fi from Noctalia's Control Center (network widget) or run: nmtui"
fi

print_network_status
log_ok "Noctalia network widget/Control Center can now use NetworkManager."
log_info "If you need to return to ifupdown: $0 --restore"

#!/usr/bin/env bash
# ==============================================================================
# install/09-grub.sh — Optional Gruvbox GRUB theme + Plymouth boot splash
# ==============================================================================
# GRUB 2 has no native animation engine: the theme is static and only the
# __timeout__ progress bar moves. Plymouth provides the animated splash after
# GRUB hands off to the kernel.
#
# This step is opt-in. It changes /etc/default/grub, rebuilds the initramfs
# and runs update-grub, so it is intentionally separate from the main install.
#
# Usage:
#   ./install/09-grub.sh            # ask for confirmation and install
#   ./install/09-grub.sh --yes      # install without asking
#   ./install/09-grub.sh --remove   # remove the theme and restore the backup
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/00-helpers.sh"

require_debian_13

ASSUME_YES=false
REMOVE=false
for arg in "$@"; do
  case "$arg" in
    -y|--yes)
      ASSUME_YES=true
      ;;
    --remove|--uninstall)
      REMOVE=true
      ;;
    -h|--help)
      echo "Usage: $0 [--yes|--remove]"
      echo ""
      echo "  --yes        Install without asking for confirmation"
      echo "  --remove     Remove the Gruvbox theme and restore /etc/default/grub"
      exit 0
      ;;
    *)
      log_warn "Unrecognized argument: $arg"
      ;;
  esac
done

GRUB_DEFAULT="/etc/default/grub"
GRUB_BACKUP="/etc/default/grub.dotfiles-backup"
GRUB_THEME_DIR="/boot/grub/themes/gruvbox"
GRUB_THEME_SRC="$DOTFILES_DIR/grub/themes/gruvbox"
PLYMOUTH_THEME_DIR="/usr/share/plymouth/themes/gruvbox"
PLYMOUTH_SRC="$DOTFILES_DIR/grub/plymouth/gruvbox.plymouth"

# ------------------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------------------
set_grub_var() {
  local key="$1" value="$2" escaped=""

  escaped="$(printf '%s' "$value" | sed 's/[\\&|]/\\&/g')"
  if run_sudo grep -qE "^[#[:space:]]*${key}=" "$GRUB_DEFAULT"; then
    run_sudo sed -i -E "s|^[#[:space:]]*${key}=.*|${key}=${escaped}|" "$GRUB_DEFAULT"
  else
    printf '%s=%s\n' "$key" "$value" | run_sudo tee -a "$GRUB_DEFAULT" >/dev/null
  fi
}

backup_grub_default() {
  if [[ ! -f "$GRUB_BACKUP" ]]; then
    run_sudo cp -a "$GRUB_DEFAULT" "$GRUB_BACKUP"
    log_ok "Saved the original GRUB configuration: $GRUB_BACKUP"
  else
    log_info "Keeping the existing GRUB backup: $GRUB_BACKUP"
  fi
}

generate_grub_fonts() {
  local font_src="" size
  local -a sizes=(16 28 36)
  # Keep only printable ASCII + Latin-1. This reduces each PF2 file from
  # several hundred KB to a few KB and avoids loading unrelated glyph tables
  # from the Nerd Font build.
  local range="0x20-0x7e,0xa0-0xff"

  font_src="$(fc-match -f '%{file}' 'IosevkaTerm Nerd Font Mono' 2>/dev/null || true)"
  if [[ ! -f "$font_src" ]]; then
    font_src="$(fc-match -f '%{file}' 'monospace' 2>/dev/null || true)"
  fi
  if [[ ! -f "$font_src" ]]; then
    font_src="/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf"
  fi
  if [[ ! -f "$font_src" ]]; then
    log_warn "No usable TTF font found; the GRUB theme cannot be installed safely."
    return 1
  fi

  log_info "Generating GRUB fonts from: $font_src"
  for size in "${sizes[@]}"; do
    if ! run_sudo grub-mkfont -s "$size" -r "$range" -n Dotfiles \
      -o "$GRUB_THEME_DIR/Dotfiles-${size}.pf2" "$font_src" >/dev/null 2>&1; then
      log_warn "Could not generate the GRUB font at size ${size}."
      return 1
    fi
  done
  return 0
}

install_theme() {
  log_info "Installing the static Gruvbox GRUB theme..."
  run_sudo install -d -m 0755 "$GRUB_THEME_DIR"
  # Remove files from older versions of this theme (old font sizes and the
  # obsolete menu/select pixmap slices); stale PF2 files would otherwise be
  # loaded by 00_header alongside the current ones.
  run_sudo rm -f "$GRUB_THEME_DIR"/Dotfiles-*.pf2 \
    "$GRUB_THEME_DIR"/menu_*.png "$GRUB_THEME_DIR"/select_*.png
  run_sudo cp -a "$GRUB_THEME_SRC/." "$GRUB_THEME_DIR/"
  run_sudo chown -R root:root "$GRUB_THEME_DIR" 2>/dev/null || true
  if ! generate_grub_fonts; then
    log_err "The GRUB menu fonts could not be generated; refusing to install an unreadable theme."
    run_sudo rm -rf "$GRUB_THEME_DIR"
    return 1
  fi

  log_info "Installing the animated Plymouth splash..."
  if ! has_cmd plymouth; then
    pkg_update
  fi
  pkg_install plymouth plymouth-themes

  if [[ ! -d /usr/share/plymouth/themes/spinner ]]; then
    log_warn "The Plymouth spinner theme is missing; skipping the animated splash."
    return 1
  fi
  if [[ ! -x /usr/sbin/plymouth-set-default-theme ]]; then
    log_warn "plymouth-set-default-theme is missing; skipping the animated splash."
    return 1
  fi

  run_sudo install -d -m 0755 "$PLYMOUTH_THEME_DIR"
  run_sudo install -m 0644 "$PLYMOUTH_SRC" "$PLYMOUTH_THEME_DIR/gruvbox.plymouth"
  # Reuse the animation frames shipped by plymouth-themes instead of keeping a
  # second copy of the binary assets in this repository.
  run_sudo cp /usr/share/plymouth/themes/spinner/animation-*.png "$PLYMOUTH_THEME_DIR/"
  run_sudo chown -R root:root "$PLYMOUTH_THEME_DIR" 2>/dev/null || true
  if ! ls "$PLYMOUTH_THEME_DIR"/animation-*.png >/dev/null 2>&1; then
    log_warn "The Plymouth animation frames were not copied; skipping the animated splash."
    return 1
  fi

  run_sudo /usr/sbin/plymouth-set-default-theme gruvbox
  run_sudo /usr/sbin/update-initramfs -u -k all
  return 0
}

update_grub() {
  if [[ -x /usr/sbin/update-grub ]]; then
    run_sudo /usr/sbin/update-grub
  else
    run_sudo /usr/sbin/grub-mkconfig -o /boot/grub/grub.cfg
  fi
}

configure_grub_default() {
  local current=""

  backup_grub_default

  # Preserve existing kernel options and append "splash" once.
  current="$(sed -nE 's/^GRUB_CMDLINE_LINUX_DEFAULT="(.*)"$/\1/p' "$GRUB_DEFAULT" | tail -n1)"
  [[ -n "$current" ]] || current="quiet"
  case " $current " in
    *" splash "*) ;;
    *) current="${current} splash" ;;
  esac

  set_grub_var GRUB_CMDLINE_LINUX_DEFAULT "\"$current\""
  set_grub_var GRUB_GFXMODE '"1920x1080,auto"'
  set_grub_var GRUB_GFXPAYLOAD_LINUX '"keep"'
  set_grub_var GRUB_THEME "\"$GRUB_THEME_DIR/theme.txt\""
  # A graphical theme is only rendered when GRUB uses the gfxterm terminal.
  # GRUB_TERMINAL (if set) overrides GRUB_TERMINAL_OUTPUT, so disable it.
  if run_sudo grep -qE '^[[:space:]]*GRUB_TERMINAL=' "$GRUB_DEFAULT"; then
    run_sudo sed -i -E 's|^([[:space:]]*GRUB_TERMINAL=)|#\1|' "$GRUB_DEFAULT"
    log_info "Commented GRUB_TERMINAL so the graphical theme can be used."
  fi
  set_grub_var GRUB_TERMINAL_OUTPUT 'gfxterm'
  set_grub_var GRUB_TIMEOUT_STYLE 'menu'
}

verify_install() {
  local failed=false

  if [[ ! -f "$GRUB_THEME_DIR/theme.txt" ]]; then
    log_err "GRUB theme not found at $GRUB_THEME_DIR/theme.txt"
    failed=true
  fi
  if [[ ! -f "$GRUB_THEME_DIR/background.png" ]]; then
    log_err "GRUB theme background not found."
    failed=true
  fi
  for size in 16 28 36; do
    if [[ ! -f "$GRUB_THEME_DIR/Dotfiles-${size}.pf2" ]]; then
      log_err "GRUB font Dotfiles-${size}.pf2 was not generated."
      failed=true
    fi
  done
  if [[ ! -f "$PLYMOUTH_THEME_DIR/gruvbox.plymouth" ]]; then
    log_err "Plymouth theme not found at $PLYMOUTH_THEME_DIR/gruvbox.plymouth"
    failed=true
  elif ! ls "$PLYMOUTH_THEME_DIR"/animation-*.png >/dev/null 2>&1; then
    log_err "Plymouth animation frames are missing from $PLYMOUTH_THEME_DIR"
    failed=true
  elif [[ ! -f /etc/plymouth/plymouthd.conf ]] || ! grep -qE '^Theme=[[:space:]]*gruvbox' /etc/plymouth/plymouthd.conf; then
    log_err "Plymouth is not configured to use the gruvbox theme."
    failed=true
  fi
  if ! grep -q '^GRUB_THEME=' "$GRUB_DEFAULT"; then
    log_err "GRUB_THEME was not written to $GRUB_DEFAULT"
    failed=true
  fi
  if ! grep -q '^GRUB_TERMINAL_OUTPUT=gfxterm' "$GRUB_DEFAULT"; then
    log_err "GRUB_TERMINAL_OUTPUT=gfxterm was not written to $GRUB_DEFAULT"
    failed=true
  fi
  if ! grep -q 'splash' "$GRUB_DEFAULT"; then
    log_err "The splash kernel option was not written to $GRUB_DEFAULT"
    failed=true
  fi
  if [[ -f /boot/grub/grub.cfg ]] && has_cmd grub-script-check; then
    if ! grub-script-check /boot/grub/grub.cfg >/dev/null 2>&1; then
      log_warn "grub-script-check reported a problem with /boot/grub/grub.cfg"
    fi
  fi

  [[ "$failed" == "false" ]]
}

remove_theme() {
  log_step "Removing the Gruvbox GRUB theme and Plymouth splash"

  run_sudo rm -rf "$GRUB_THEME_DIR" "$PLYMOUTH_THEME_DIR"

  if [[ -f "$GRUB_BACKUP" ]]; then
    run_sudo cp -a "$GRUB_BACKUP" "$GRUB_DEFAULT"
    run_sudo rm -f "$GRUB_BACKUP"
    log_ok "Restored the original /etc/default/grub."
  else
    # No backup (for example, the theme was installed manually). Remove only the
    # theme line so GRUB falls back to its normal menu.
    run_sudo sed -i -E '/^GRUB_THEME=.*themes\/gruvbox\/theme\.txt"?$/d' "$GRUB_DEFAULT" || true
    log_warn "No backup found; removed the GRUB_THEME line only."
  fi

  if [[ -d /usr/share/plymouth/themes/spinner && -x /usr/sbin/plymouth-set-default-theme ]]; then
    run_sudo /usr/sbin/plymouth-set-default-theme spinner 2>/dev/null || true
  fi
  run_sudo /usr/sbin/update-initramfs -u -k all 2>/dev/null || true
  update_grub 2>/dev/null || true
  log_ok "Boot theme removed. Reboot to return to the default boot screen."
}

# ------------------------------------------------------------------------------
# Main
# ------------------------------------------------------------------------------
if [[ "$REMOVE" == "true" ]]; then
  if [[ "$ASSUME_YES" != "true" ]]; then
    read -r -p "Remove the Gruvbox GRUB/Plymouth theme? [y/N]: " reply
    case "${reply,,}" in
      y|yes) ;;
      *) echo "Operation cancelled."; exit 0 ;;
    esac
  fi
  remove_theme
  exit 0
fi

if [[ ! -d /boot/grub ]]; then
  log_err "/boot/grub is missing; GRUB does not appear to be installed."
  exit 1
fi
if [[ ! -f "$GRUB_THEME_SRC/theme.txt" ]]; then
  log_err "Theme source not found: $GRUB_THEME_SRC/theme.txt"
  exit 1
fi
if ! has_cmd grub-mkfont; then
  log_err "grub-mkfont is missing. Install grub-common first."
  exit 1
fi

log_step "Optional: Gruvbox GRUB theme + Plymouth boot splash"
cat <<'EOF'
GRUB 2 does not support animated GIF/video themes. This step installs:
  - a static Gruvbox GRUB theme (background, menu, timeout bar)
  - an animated Plymouth spinner after GRUB hands off to the kernel
  - the "splash" kernel option and a 1920x1080 GRUB resolution

It will modify /etc/default/grub, rebuild the initramfs and run update-grub.
The original /etc/default/grub is saved before any change.
EOF
echo ""

if [[ "$ASSUME_YES" != "true" ]]; then
  read -r -p "Apply the boot theme now? [y/N]: " reply
  case "${reply,,}" in
    y|yes) ;;
    *) log_info "Skipped the optional GRUB/Plymouth setup."; exit 0 ;;
  esac
fi

configure_grub_default
install_theme || log_warn "Boot theme setup was incomplete; review the output above."
update_grub

if verify_install; then
  log_ok "GRUB theme + Plymouth splash installed."
  log_info "Reboot to see the new boot screen. Roll back with: $0 --remove"
else
  log_err "The boot theme was installed but verification failed. Review the output above."
  exit 1
fi

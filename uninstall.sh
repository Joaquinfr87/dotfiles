#!/usr/bin/env bash
# ==============================================================================
# uninstall.sh — Uninstall and reset the system (Debian 13 only)
# ==============================================================================
# Leaves the machine in its original state without reinstalling the OS:
#   1. Stops and disables services (greetd, noctalia-greeter, pipewire)
#   2. Removes external repositories and APT configuration (noctalia, gierens)
#   3. Reverts the optional GRUB/Plymouth boot theme
#   4. Uninstalls graphical packages and utilities (sway, kitty, noctalia, etc.)
#   5. Removes downloaded binaries (zen-browser, fonts, starship, omz, etc.)
#   6. Cleans deployed configs in ~/.config and restores backups
#   7. Restores the default login shell to /bin/bash
#
# IMPORTANT: this script removes the graphical environment (Sway, greetd, etc.).
# Do NOT run it from inside an active graphical session (Sway/Wayland/X11).
# Switch to a text console first (e.g. Ctrl+Alt+F3) and run it from there.
# ==============================================================================
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$DOTFILES_DIR/install"

# shellcheck disable=SC1091
source "$INSTALL_DIR/00-helpers.sh"

FORCE=false
KEEP_EXTRAS=false
RESTORE_BACKUP=false

for arg in "$@"; do
  case "$arg" in
    -y|--yes|--force)
      FORCE=true
      ;;
    --keep-extras)
      KEEP_EXTRAS=true
      ;;
    --restore-backup)
      RESTORE_BACKUP=true
      ;;
    -h|--help)
      echo "Usage: ./uninstall.sh [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  -y, --yes, --force   Run the uninstall without interactive confirmation"
      echo "  --keep-extras        Keep Node.js, NVM and the extra AI tools"
      echo "  --restore-backup     Restore the previous backup from ~/.dotfiles_backup if present"
      echo "  -h, --help           Show this help"
      exit 0
      ;;
    *)
      log_warn "Unrecognized argument: $arg"
      ;;
  esac
done

require_debian_13

# ------------------------------------------------------------------------------
# Close the graphical session automatically from a text TTY
# ------------------------------------------------------------------------------
close_graphical_session() {
  local session_id=""
  local current_tty
  current_tty="$(tty 2>/dev/null || echo "unknown")"

  log_info "Closing the active graphical session (you are on $current_tty)..."

  # 1. Try loginctl first (clean way to end the user's session)
  if has_cmd loginctl; then
    session_id="$(loginctl list-sessions --no-legend 2>/dev/null \
      | awk -v u="$USER" '$2==u && ($3=="wayland" || $3=="x11" || $3=="mir") {print $1; exit}' \
      || true)"
    if [[ -n "$session_id" ]]; then
      log_info "Terminating graphical session $session_id via loginctl..."
      loginctl terminate-session "$session_id" 2>/dev/null || true
    fi
  fi

  # 2. Fallback: terminate known graphical processes owned by the user
  if pgrep -u "$USER" sway >/dev/null 2>&1; then
    log_info "Terminating sway processes for user $USER..."
    pkill -TERM -u "$USER" sway 2>/dev/null || true
  fi
  if pgrep -u "$USER" greetd >/dev/null 2>&1; then
    log_info "Terminating greetd processes for user $USER..."
    pkill -TERM -u "$USER" greetd 2>/dev/null || true
  fi

  # Wait for them to exit
  sleep 4

  # 3. If they are still alive, force-kill them
  if pgrep -u "$USER" sway >/dev/null 2>&1; then
    log_warn "Sway is still running. Forcing it to close..."
    pkill -KILL -u "$USER" sway 2>/dev/null || true
    sleep 2
  fi

  if pgrep -u "$USER" sway >/dev/null 2>&1; then
    log_err "Could not close the graphical session automatically."
    echo -e "${YELLOW}Log out of the graphical session manually and run the script again.${NC}"
    exit 1
  fi

  log_ok "Graphical session closed."
}

echo -e "${RED}"
echo "  ██╗   ██╗███╗   ██╗██╗███╗   ██╗███████╗████████╗ █████╗ ██╗     ██╗     "
echo "  ██║   ██║████╗  ██║██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║     ██║     "
echo "  ██║   ██║██╔██╗ ██║██║██╔██╗ ██║███████╗   ██║   ███████║██║     ██║     "
echo "  ██║   ██║██║╚██╗██║██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║     ██║     "
echo "  ╚██████╔╝██║ ╚███║██║██║ ╚████║███████║   ██║   ██║  ██║██║  ██║██╗    "
echo "   ╚═════╝ ╚═╝  ╚═══╝╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝    "
echo -e "${NC}"
echo -e "${BOLD}${RED}WARNING: this script will uninstall the graphical environments, utilities${NC}"
echo -e "${BOLD}${RED}and dotfiles configurations installed on this machine, leaving it clean.${NC}"
echo -e "Repository to keep: ${BLUE}$DOTFILES_DIR${NC}\n"

# ------------------------------------------------------------------------------
# 0. Environment check and graphical session shutdown if needed
# ------------------------------------------------------------------------------
log_step "0. Checking the execution environment"

# Are we INSIDE a graphical session (environment variables of this session)?
IN_GRAPHIC_SESSION_ENV=false
if [[ -n "${WAYLAND_DISPLAY:-}" || -n "${DISPLAY:-}" || -n "${SWAYSOCK:-}" ]]; then
  IN_GRAPHIC_SESSION_ENV=true
fi

# Is there an active graphical session for this user (even on another TTY)?
GRAPHIC_SESSION_ACTIVE=false
if pgrep -u "$USER" sway >/dev/null 2>&1 || pgrep -u "$USER" greetd >/dev/null 2>&1; then
  GRAPHIC_SESSION_ACTIVE=true
fi

CURRENT_TTY="$(tty 2>/dev/null || echo "unknown")"

# Case A: we are INSIDE the graphical session -> abort (unless --force)
if [[ "$IN_GRAPHIC_SESSION_ENV" == "true" && "$FORCE" != "true" ]]; then
  log_err "An active graphical session was detected ($CURRENT_TTY)."
  echo ""
  echo -e "${YELLOW}This script uninstalls sway, greetd, kitty and the graphical environment.${NC}"
  echo -e "${YELLOW}Running it from inside the graphical session causes a black screen and${NC}"
  echo -e "${YELLOW}leaves the script half-finished without removing anything correctly.${NC}"
  echo ""
  echo -e "${BOLD}Correct steps:${NC}"
  echo "  1. Switch to a text console: Ctrl + Alt + F3 (or F2/F4)."
  echo "  2. Log in with your username and password on the text console."
  echo "  3. Run this script again from there:"
  echo -e "     ${BOLD}cd $DOTFILES_DIR && ./uninstall.sh${NC}"
  echo ""
  echo "If you really want to run it from the graphical session at your own risk,"
  echo "use the --force flag (not recommended)."
  exit 1
fi

if [[ "$IN_GRAPHIC_SESSION_ENV" == "true" && "$FORCE" == "true" ]]; then
  log_warn "An active graphical session was detected on $CURRENT_TTY but --force is set. Continuing at your own risk."
fi

# Case B: we are on a text TTY but there is an active graphical session for this user
# -> offer to close it automatically before continuing
if [[ "$IN_GRAPHIC_SESSION_ENV" == "false" && "$GRAPHIC_SESSION_ACTIVE" == "true" ]]; then
  log_warn "An active graphical session (Sway/Wayland/greetd) was detected on another TTY."
  echo -e "Your current TTY is: ${BOLD}$CURRENT_TTY${NC}"
  echo ""

  if [[ "$FORCE" != "true" ]]; then
    read -r -p "Close the graphical session automatically and continue with the uninstall? [y/N]: " CLOSE_GRAPHICAL
    case "${CLOSE_GRAPHICAL,,}" in
      y|yes) ;;
      *)
        echo "Operation cancelled."
        exit 0
        ;;
    esac
  fi

  close_graphical_session
fi

if [[ "$FORCE" != "true" ]]; then
  read -r -p "Are you sure you want to reset the system? [y/N]: " CONFIRM
  case "${CONFIRM,,}" in
    y|yes)
      ;;
    *)
      echo "Operation cancelled."
      exit 0
      ;;
  esac
fi

# ------------------------------------------------------------------------------
# 1. System services (greetd, pipewire)
# ------------------------------------------------------------------------------
log_step "1. Stopping and disabling system services"

if has_cmd systemctl; then
  log_info "Disabling the greetd service (display manager)..."
  run_sudo systemctl disable --now greetd.service 2>/dev/null || true

  log_info "Stopping PipeWire user services..."
  systemctl --user stop pipewire wireplumber pipewire-pulse 2>/dev/null || true
  systemctl --user disable pipewire wireplumber pipewire-pulse 2>/dev/null || true
  log_ok "Services stopped."
fi

# ------------------------------------------------------------------------------
# 2. Revert the display manager and greeter
# ------------------------------------------------------------------------------
log_step "2. Cleaning the Noctalia Greeter and greetd configuration"

run_sudo rm -f /etc/greetd/config.toml
run_sudo rm -rf /var/lib/noctalia-greeter
log_ok "greetd and greeter files removed."

# Revert the optional GRUB/Plymouth boot theme before packages are purged.
if [[ -x "$INSTALL_DIR/09-grub.sh" ]]; then
  log_info "Reverting the optional GRUB/Plymouth boot theme..."
  "$INSTALL_DIR/09-grub.sh" --remove --yes || log_warn "Could not fully revert the boot theme."
fi

# ------------------------------------------------------------------------------
# 3. Purge installed packages and remove external repositories
# ------------------------------------------------------------------------------
log_step "3. Purging installed packages (Sway, Noctalia, Kitty, etc.)"

PACKAGES_TO_PURGE=(
  noctalia
  noctalia-greeter
  greetd
  nickh-archive-keyring
  sway
  xwayland
  kanshi
  wl-clipboard
  pavucontrol
  kitty
  foot
  foot-themes
  git-delta
  fastfetch
  zoxide
  eza
  bat
  batcat
  direnv
  plymouth
  plymouth-themes
)

INSTALLED_TO_PURGE=()
for pkg in "${PACKAGES_TO_PURGE[@]}"; do
  if dpkg -s "$pkg" >/dev/null 2>&1; then
    INSTALLED_TO_PURGE+=("$pkg")
  fi
done

if [[ ${#INSTALLED_TO_PURGE[@]} -gt 0 ]]; then
  log_info "Purging installed packages: ${INSTALLED_TO_PURGE[*]}..."
  run_sudo apt-get purge -y "${INSTALLED_TO_PURGE[@]}" || true
fi

log_info "Removing external APT repositories..."
run_sudo rm -f /etc/apt/sources.list.d/noctalia-trixie.sources \
               /etc/apt/preferences.d/noctalia.pref \
               /etc/apt/sources.list.d/gierens.list \
               /etc/apt/keyrings/gierens.gpg
log_ok "External APT sources removed."

run_sudo apt-get autoremove --purge -y 2>/dev/null || true
run_sudo apt-get clean 2>/dev/null || true
log_ok "System packages purged and orphaned dependencies cleaned."

# ------------------------------------------------------------------------------
# 4. Back up shell files before removing them (in case something goes wrong)
# ------------------------------------------------------------------------------
log_step "4. Backing up critical shell files"

BACKUP_SHELL_DIR="$HOME/.dotfiles_backup/shell_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_SHELL_DIR"
for shell_file in "$HOME/.zshrc" "$HOME/.zprofile" "$HOME/.bashrc" "$HOME/.profile"; do
  if [[ -f "$shell_file" ]]; then
    cp -a "$shell_file" "$BACKUP_SHELL_DIR/" 2>/dev/null || true
  fi
done
log_ok "Shell files backed up to: $BACKUP_SHELL_DIR"

# ------------------------------------------------------------------------------
# 5. Remove downloaded applications and manual binaries
# ------------------------------------------------------------------------------
log_step "5. Removing manual binaries and applications"

log_info "Removing Zen Browser..."
rm -rf "$HOME/.local/share/zen" \
       "$HOME/.local/bin/zen" \
       "$HOME/.local/share/applications/zen.desktop" \
       "$HOME/.local/share/icons/hicolor/128x128/apps/zen.png"
run_sudo rm -f /usr/local/bin/zen 2>/dev/null || true

log_info "Removing the Kitty app (official installer)..."
rm -rf "$HOME/.local/kitty.app" \
       "$HOME/.local/bin/kitty" \
       "$HOME/.local/bin/kitten" \
       "$HOME/.local/share/applications/kitty.desktop"
run_sudo rm -f /usr/local/bin/kitty /usr/local/bin/kitten /usr/share/applications/kitty.desktop 2>/dev/null || true
if has_cmd update-alternatives; then
  run_sudo update-alternatives --remove x-terminal-emulator /usr/local/bin/kitty 2>/dev/null || true
fi

log_info "Removing manual Bluetuith, Lazygit and Git-Delta binaries..."
rm -f "$HOME/.local/bin/bluetuith" "$HOME/.local/bin/lazygit" "$HOME/.local/bin/delta"
run_sudo rm -f /usr/local/bin/bluetuith /usr/local/bin/lazygit /usr/local/bin/delta 2>/dev/null || true

log_info "Removing the Starship prompt..."
rm -f "$HOME/.local/bin/starship"
run_sudo rm -f /usr/local/bin/starship 2>/dev/null || true
rm -rf "$HOME/.cache/starship"

log_info "Removing Oh My Zsh (if it was installed)..."
rm -rf "$HOME/.oh-my-zsh"

log_info "Removing Iosevka fonts..."
rm -rf "$HOME/.local/share/fonts/Iosevka"
rm -rf "$HOME/.local/share/fonts/IosevkaTerm"
rm -rf "$HOME/.local/share/fonts/Iosevka-GUI"
run_sudo rm -rf /usr/local/share/fonts/Iosevka /usr/local/share/fonts/IosevkaTerm 2>/dev/null || true
if has_cmd fc-cache; then
  fc-cache -fv "$HOME/.local/share/fonts" >/dev/null 2>&1 || true
  run_sudo fc-cache -f /usr/local/share/fonts >/dev/null 2>&1 || true
fi

log_info "Removing Tmux plugins..."
rm -rf "$HOME/.config/tmux/plugins"

log_info "Removing dot-sync and tmux-sessionizer symlinks..."
rm -f "$HOME/.local/bin/tmux-sessionizer" "$HOME/.local/bin/dot-sync"
run_sudo rm -f /usr/local/bin/tmux-sessionizer /usr/local/bin/dot-sync 2>/dev/null || true

# ------------------------------------------------------------------------------
# 6. Development tools and AI agents (optional)
# ------------------------------------------------------------------------------
if [[ "$KEEP_EXTRAS" != "true" ]]; then
  log_step "6. Removing extra tools (NVM, Node, PNPM, AI agents)"
  rm -rf "$HOME/.nvm" \
         "$HOME/.local/share/pnpm" \
         "$HOME/.npm"
  rm -f "$HOME/.local/bin/node" \
        "$HOME/.local/bin/npm" \
        "$HOME/.local/bin/npx" \
        "$HOME/.local/bin/pnpm" \
        "$HOME/.local/bin/freebuff" \
        "$HOME/.local/bin/opencode" \
        "$HOME/.local/bin/codex" \
        "$HOME/.local/bin/agy"
  log_ok "Extra tools removed."
else
  log_info "Skipping extra tools removal (--keep-extras is set)."
fi

# ------------------------------------------------------------------------------
# 7. Clean dotfiles and restore configurations
# ------------------------------------------------------------------------------
log_step "7. Cleaning user configurations in ~/.config"

CONFIGS_TO_REMOVE=(
  "$HOME/.config/sway"
  "$HOME/.config/noctalia"
  "$HOME/.config/kitty"
  "$HOME/.config/kanshi"
  "$HOME/.config/nvim"
  "$HOME/.config/tmux"
  "$HOME/.config/starship.toml"
  "$HOME/.config/git"
  "$HOME/.local/state/noctalia"
  "$HOME/.dotfiles_profile"
)

for cfg in "${CONFIGS_TO_REMOVE[@]}"; do
  rm -rf "$cfg"
done
log_ok "Configuration folders in ~/.config removed."

# Restore the most recent backup only if the user asks for it
BACKUP_ROOT="$HOME/.dotfiles_backup"
if [[ "$RESTORE_BACKUP" == "true" && -d "$BACKUP_ROOT" ]]; then
  # Only consider deployment backups, not the shell_* snapshots created above
  LATEST_BACKUP=$(find "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d ! -name 'shell_*' | sort -r | head -n 1 || echo "")
  if [[ -n "$LATEST_BACKUP" ]]; then
    log_info "Restoring the previous backup from: $LATEST_BACKUP..."
    cp -r "$LATEST_BACKUP/"* "$HOME/" 2>/dev/null || true
    log_ok "Previous backup restored into your \$HOME."
  fi
else
  log_info "Environment left blank (reset) without restoring dotfiles."
fi

# ------------------------------------------------------------------------------
# 8. Restore the login shell to /bin/bash
# ------------------------------------------------------------------------------
log_step "8. Restoring the default shell to bash"

BASH_BIN="$(command -v bash || echo "/bin/bash")"
if [[ -n "$BASH_BIN" && "${SHELL:-}" != "$BASH_BIN" ]]; then
  if has_cmd usermod; then
    run_sudo usermod -s "$BASH_BIN" "$USER" 2>/dev/null || true
  elif has_cmd chsh; then
    run_sudo chsh -s "$BASH_BIN" "$USER" 2>/dev/null || true
  fi
  log_ok "Shell restored to $BASH_BIN for user $USER."
fi

# Clean leftovers in .zshrc and .zprofile when no backup was restored
if [[ ! -d "$BACKUP_ROOT" ]]; then
  rm -f "$HOME/.zshrc" "$HOME/.zprofile"
fi

echo -e "\n${GREEN}====================================================================${NC}"
echo -e "${BOLD}${GREEN}>> System reset completed successfully!${NC}"
echo -e "${GREEN}====================================================================${NC}"
echo -e "Your machine is clean and ready to test the installer again:"
echo -e "  Run: ${BOLD}./install.sh${NC}\n"
echo -e "${YELLOW}Note:${NC} If you used --force from a graphical session, reboot the machine${NC}"
echo -e "${YELLOW}so the graphical environment changes take effect.${NC}"

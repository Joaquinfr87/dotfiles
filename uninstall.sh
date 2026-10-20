#!/usr/bin/env bash
# ==============================================================================
# uninstall.sh — Script de desinstalación y restablecimiento a 0 del sistema
# ==============================================================================
# Permite dejar la máquina en su estado original sin necesidad de reinstalar el SO:
#   1. Detiene y deshabilita servicios (greetd, noctalia-greeter, pipewire)
#   2. Elimina repositorios externos y configuraciones APT (noctalia, gierens)
#   3. Desinstala paquetes gráficos y utilidades (sway, kitty, noctalia, etc.)
#   4. Elimina binarios descargados (zen-browser, fonts, starship, omz, etc.)
#   5. Limpia configuraciones desplegadas en ~/.config y restaura backups
#   6. Restablece la shell de login por defecto a /bin/bash
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
      echo "Uso: ./uninstall.sh [OPCIONES]"
      echo ""
      echo "Opciones:"
      echo "  -y, --yes, --force   Ejecuta la desinstalación sin pedir confirmación interactiva"
      echo "  --keep-extras        No elimina Node.js, NVM ni herramientas AI extras"
      echo "  --restore-backup     Restaura el backup previo desde ~/.dotfiles_backup si existe"
      echo "  -h, --help           Muestra esta ayuda"
      exit 0
      ;;
    *)
      log_warn "Argumento no reconocido: $arg"
      ;;
  esac
done

echo -e "${RED}"
echo "  ██╗   ██╗███╗   ██╗██╗███╗   ██╗███████╗████████╗ █████╗ ██╗     ██╗     "
echo "  ██║   ██║████╗  ██║██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║     ██║     "
echo "  ██║   ██║██╔██╗ ██║██║██╔██╗ ██║███████╗   ██║   ███████║██║     ██║     "
echo "  ██║   ██║██║╚██╗██║██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║     ██║     "
echo "  ╚██████╔╝██║ ╚████║██║██║ ╚████║███████║   ██║   ██║  ██║███████╗███████╗"
echo "   ╚═════╝ ╚═╝  ╚═══╝╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝"
echo -e "${NC}"
echo -e "${BOLD}${RED}ADVERTENCIA: Este script desinstalará los entornos gráficos, utilidades y${NC}"
echo -e "${BOLD}${RED}configuraciones de dotfiles instaladas, dejando el sistema limpio.${NC}"
echo -e "Repositorio a conservar: ${BLUE}$DOTFILES_DIR${NC}\n"

if [[ "$FORCE" != "true" ]]; then
  read -r -p "¿Estás seguro de que deseas restablecer el sistema a 0? [s/N]: " CONFIRM
  case "${CONFIRM,,}" in
    s|si|y|yes)
      ;;
    *)
      echo "Operación cancelada."
      exit 0
      ;;
  esac
fi

# ------------------------------------------------------------------------------
# 1. Servicios del sistema (greetd, pipewire)
# ------------------------------------------------------------------------------
log_step "1. Deteniendo y deshabilitando servicios del sistema"

if has_cmd systemctl; then
  log_info "Deshabilitando servicio greetd (display manager)..."
  run_sudo systemctl disable --now greetd.service 2>/dev/null || true

  log_info "Deteniendo servicios de usuario PipeWire..."
  systemctl --user stop pipewire wireplumber pipewire-pulse 2>/dev/null || true
  systemctl --user disable pipewire wireplumber pipewire-pulse 2>/dev/null || true
  log_ok "Servicios detenidos."
fi

# ------------------------------------------------------------------------------
# 2. Revertir Display Manager y Greeter
# ------------------------------------------------------------------------------
log_step "2. Limpiando configuración de Noctalia Greeter y greetd"

run_sudo rm -f /etc/greetd/config.toml
run_sudo rm -rf /var/lib/noctalia-greeter
log_ok "Archivos de greetd y greeter eliminados."

# ------------------------------------------------------------------------------
# 3. Purgar paquetes instalados y eliminar repositorios externos
# ------------------------------------------------------------------------------
log_step "3. Purgando paquetes instalados (Sway, Noctalia, Kitty, etc.)"

OS="$(detect_os)"
if [[ "$OS" =~ ^(debian|ubuntu|pop|linuxmint)$ ]]; then
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
  )

  INSTALLED_TO_PURGE=()
  for pkg in "${PACKAGES_TO_PURGE[@]}"; do
    if dpkg -s "$pkg" >/dev/null 2>&1; then
      INSTALLED_TO_PURGE+=("$pkg")
    fi
  done

  if [[ ${#INSTALLED_TO_PURGE[@]} -gt 0 ]]; then
    log_info "Purgando paquetes instalados: ${INSTALLED_TO_PURGE[*]}..."
    run_sudo apt-get purge -y "${INSTALLED_TO_PURGE[@]}" || true
  fi

  log_info "Eliminando repositorios externos de APT..."
  run_sudo rm -f /etc/apt/sources.list.d/noctalia-trixie.sources \
                 /etc/apt/preferences.d/noctalia.pref \
                 /etc/apt/sources.list.d/gierens.list \
                 /etc/apt/keyrings/gierens.gpg
  log_ok "Fuentes APT externas eliminadas."

  run_sudo apt-get autoremove --purge -y 2>/dev/null || true
  run_sudo apt-get clean 2>/dev/null || true
  log_ok "Paquetes del sistema purgados y dependencias huérfanas limpiadas."
fi

# ------------------------------------------------------------------------------
# 5. Eliminar aplicaciones descargadas y binarios manuales
# ------------------------------------------------------------------------------
log_step "5. Eliminando binarios y aplicaciones manuales"

log_info "Eliminando Zen Browser..."
rm -rf "$HOME/.local/share/zen" \
       "$HOME/.local/bin/zen" \
       "$HOME/.local/share/applications/zen.desktop" \
       "$HOME/.local/share/icons/hicolor/128x128/apps/zen.png"
run_sudo rm -f /usr/local/bin/zen 2>/dev/null || true

log_info "Eliminando Kitty app (instalador oficial)..."
rm -rf "$HOME/.local/kitty.app" \
       "$HOME/.local/bin/kitty" \
       "$HOME/.local/bin/kitten" \
       "$HOME/.local/share/applications/kitty.desktop"
run_sudo rm -f /usr/local/bin/kitty /usr/local/bin/kitten /usr/share/applications/kitty.desktop 2>/dev/null || true
if has_cmd update-alternatives; then
  run_sudo update-alternatives --remove x-terminal-emulator /usr/local/bin/kitty 2>/dev/null || true
fi

log_info "Eliminando Bluetuith, Lazygit y Git-Delta manuales..."
rm -f "$HOME/.local/bin/bluetuith" "$HOME/.local/bin/lazygit" "$HOME/.local/bin/delta"
run_sudo rm -f /usr/local/bin/bluetuith /usr/local/bin/lazygit /usr/local/bin/delta 2>/dev/null || true

log_info "Eliminando Starship prompt..."
rm -f "$HOME/.local/bin/starship"
run_sudo rm -f /usr/local/bin/starship 2>/dev/null || true
rm -rf "$HOME/.cache/starship"

log_info "Eliminando Oh My Zsh (si estaba instalado)..."
rm -rf "$HOME/.oh-my-zsh"

log_info "Eliminando fuentes Iosevka..."
rm -rf "$HOME/.local/share/fonts/Iosevka"
if has_cmd fc-cache; then
  fc-cache -fv "$HOME/.local/share/fonts" >/dev/null 2>&1 || true
fi

log_info "Eliminando plugins de Tmux..."
rm -rf "$HOME/.config/tmux/plugins"

log_info "Eliminando symlinks de dot-sync y tmux-sessionizer..."
rm -f "$HOME/.local/bin/tmux-sessionizer" "$HOME/.local/bin/dot-sync"
run_sudo rm -f /usr/local/bin/tmux-sessionizer /usr/local/bin/dot-sync 2>/dev/null || true

# ------------------------------------------------------------------------------
# 6. Herramientas de Desarrollo y Agentes AI (opcional)
# ------------------------------------------------------------------------------
if [[ "$KEEP_EXTRAS" != "true" ]]; then
  log_step "6. Eliminando herramientas extras (NVM, Node, PNPM, Agentes AI)"
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
  log_ok "Herramientas extras eliminadas."
else
  log_info "Omitiendo eliminación de herramientas extras (--keep-extras activo)."
fi

# ------------------------------------------------------------------------------
# 7. Limpiar dotfiles y restaurar configuraciones
# ------------------------------------------------------------------------------
log_step "7. Limpiando configuraciones de usuario en ~/.config"

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
log_ok "Carpetas de configuración en ~/.config eliminadas."

# Restaurar el backup más reciente solo si el usuario lo solicita
BACKUP_ROOT="$HOME/.dotfiles_backup"
if [[ "$RESTORE_BACKUP" == "true" && -d "$BACKUP_ROOT" ]]; then
  LATEST_BACKUP=$(find "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d | sort -r | head -n 1 || echo "")
  if [[ -n "$LATEST_BACKUP" ]]; then
    log_info "Restaurando backup previo desde: $LATEST_BACKUP..."
    cp -r "$LATEST_BACKUP/"* "$HOME/" 2>/dev/null || true
    log_ok "Backup previo restaurado en tu \$HOME."
  fi
else
  log_info "Entorno dejado en blanco (0) sin restaurar dotfiles."
fi

# ------------------------------------------------------------------------------
# 8. Restablecer shell de inicio a /bin/bash
# ------------------------------------------------------------------------------
log_step "8. Restableciendo shell por defecto a bash"

BASH_BIN="$(command -v bash || echo "/bin/bash")"
if [[ -n "$BASH_BIN" && "${SHELL:-}" != "$BASH_BIN" ]]; then
  if has_cmd usermod; then
    run_sudo usermod -s "$BASH_BIN" "$USER" 2>/dev/null || true
  elif has_cmd chsh; then
    run_sudo chsh -s "$BASH_BIN" "$USER" 2>/dev/null || true
  fi
  log_ok "Shell restablecida a $BASH_BIN para el usuario $USER."
fi

# Limpiar posibles restos en .zshrc y .zprofile si no se restauró backup
if [[ ! -d "$BACKUP_ROOT" ]]; then
  rm -f "$HOME/.zshrc" "$HOME/.zprofile"
fi

echo -e "\n${GREEN}====================================================================${NC}"
echo -e "${BOLD}${GREEN}>> ¡Sistema restablecido a 0 con éxito!${NC}"
echo -e "${GREEN}====================================================================${NC}"
echo -e "Tu equipo ha quedado limpio y listo para volver a probar el instalador:"
echo -e "  Ejecuta: ${BOLD}./install.sh${NC}\n"

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
#
# IMPORTANTE: Este script desinstala el entorno gráfico (Sway, greetd, etc.).
# NO debe ejecutarse desde dentro de una sesión gráfica activa (Sway/Wayland/X11).
# Salí primero a una consola de texto (p. ej. Ctrl+Alt+F3) y ejecuta desde allí.
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
      echo "  -h|--help            Muestra esta ayuda"
      exit 0
      ;;
    *)
      log_warn "Argumento no reconocido: $arg"
      ;;
  esac
done

# ------------------------------------------------------------------------------
# Función: cerrar sesión gráfica automáticamente desde una TTY de texto
# ------------------------------------------------------------------------------
cerrar_sesion_grafica() {
  local sesion_id=""
  local tty_actual
  tty_actual="$(tty 2>/dev/null || echo "desconocida")"

  log_info "Cerrando sesión gráfica activa (estás en $tty_actual)..."

  # 1. Intentar vía loginctl (forma limpia de terminar la sesión del usuario)
  if has_cmd loginctl; then
    sesion_id="$(loginctl list-sessions --no-legend 2>/dev/null \
      | awk -v u="$USER" '$2==u && ($3=="wayland" || $3=="x11" || $3=="mir") {print $1; exit}' \
      || true)"
    if [[ -n "$sesion_id" ]]; then
      log_info "Finalizando sesión gráfica $sesion_id mediante loginctl..."
      loginctl terminate-session "$sesion_id" 2>/dev/null || true
    fi
  fi

  # 2. Fallback: terminar procesos gráficos conocidos del usuario
  if pgrep -u "$USER" sway >/dev/null 2>&1; then
    log_info "Finalizando procesos sway del usuario $USER..."
    pkill -TERM -u "$USER" sway 2>/dev/null || true
  fi
  if pgrep -u "$USER" greetd >/dev/null 2>&1; then
    log_info "Finalizando procesos greetd del usuario $USER..."
    pkill -TERM -u "$USER" greetd 2>/dev/null || true
  fi

  # Esperar a que terminen
  sleep 4

  # 3. Si aún persiste, matar por fuerza
  if pgrep -u "$USER" sway >/dev/null 2>&1; then
    log_warn "Sway aún está activo. Forzando cierre..."
    pkill -KILL -u "$USER" sway 2>/dev/null || true
    sleep 2
  fi

  if pgrep -u "$USER" sway >/dev/null 2>&1; then
    log_err "No se pudo cerrar la sesión gráfica automáticamente."
    echo -e "${YELLOW}Cerrá la sesión gráfica manualmente y volvé a ejecutar el script.${NC}"
    exit 1
  fi

  log_ok "Sesión gráfica cerrada."
}

echo -e "${RED}"
echo "  ██╗   ██╗███╗   ██╗██╗███╗   ██╗███████╗████████╗ █████╗ ██╗     ██╗     "
echo "  ██║   ██║████╗  ██║██║███╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║     ██║     "
echo "  ██║   ██║██╔██╗ ██║██║██╔██╗ ██║███████╗   ██║   ███████║██║     ██║     "
echo "  ██║   ██║██║╚██╗██║██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║     ██║     "
echo "  ╚██████╔╝██║ ╚███║██║██║ ╚████║███████║   ██║   ██║  ██║██║  ██║██╗    "
echo "   ╚═════╝ ╚═╝  ╚═══╝╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝    "
echo -e "${NC}"
echo -e "${BOLD}${RED}ADVERTENCIA: Este script desinstalará los entornos gráficos, utilidades y${NC}"
echo -e "${BOLD}${RED}configuraciones de dotfiles instaladas, dejando el sistema limpio.${NC}"
echo -e "Repositorio a conservar: ${BLUE}$DOTFILES_DIR${NC}\n"

# ------------------------------------------------------------------------------
# 0. Verificación de entorno y cierre de sesión gráfica si es necesario
# ------------------------------------------------------------------------------
log_step "0. Verificando entorno de ejecución"

# ¿Estamos DENTRO de una sesión gráfica (variables de entorno de esta sesión)?
IN_GRAPHIC_SESSION_ENV=false
if [[ -n "${WAYLAND_DISPLAY:-}" || -n "${DISPLAY:-}" || -n "${SWAYSOCK:-}" ]]; then
  IN_GRAPHIC_SESSION_ENV=true
fi

# ¿Hay una sesión gráfica activa de este usuario (aunque no sea nuestra TTY)?
GRAPHIC_SESSION_ACTIVE=false
if pgrep -u "$USER" sway >/dev/null 2>&1 || pgrep -u "$USER" greetd >/dev/null 2>&1; then
  GRAPHIC_SESSION_ACTIVE=true
fi

CURRENT_TTY="$(tty 2>/dev/null || echo "desconocida")"

# Caso A: estamos DENTRO de la sesión gráfica -> abortar (a menos que sea --force)
if [[ "$IN_GRAPHIC_SESSION_ENV" == "true" && "$FORCE" != "true" ]]; then
  log_err "Se detectó que estás dentro de una sesión gráfica activa ($CURRENT_TTY)."
  echo ""
  echo -e "${YELLOW}Este script desinstala sway, greetd, kitty y el entorno gráfico.${NC}"
  echo -e "${YELLOW}Ejecutarlo desde dentro de la sesión gráfica provoca pantalla negra y${NC}"
  echo -e "${YELLOW}que el script se detenga a medias sin eliminar nada correctamente.${NC}"
  echo ""
  echo -e "${BOLD}Pasos correctos:${NC}"
  echo "  1. Cambiá a una consola de texto: Ctrl + Alt + F3 (o F2/F4)."
  echo "  2. Iniciá sesión con tu usuario y contraseña en la consola de texto."
  echo "  3. Ejecutá este script nuevamente desde allí:"
  echo -e "     ${BOLD}cd $DOTFILES_DIR && ./uninstall.sh${NC}"
  echo ""
  echo "Si realmente querés ejecutarlo desde la sesión gráfica bajo tu propio riesgo,"
  echo "usá la bandera --force (no recomendado)."
  exit 1
fi

if [[ "$IN_GRAPHIC_SESSION_ENV" == "true" && "$FORCE" == "true" ]]; then
  log_warn "Se detectó sesión gráfica activa en $CURRENT_TTY pero se usa --force. Continuando bajo tu propio riesgo."
fi

# Caso B: estamos en consola de texto (tty) pero hay sesión gráfica activa de este usuario
# -> ofrecer cerrarla automáticamente antes de continuar
if [[ "$IN_GRAPHIC_SESSION_ENV" == "false" && "$GRAPHIC_SESSION_ACTIVE" == "true" ]]; then
  log_warn "Se detectó una sesión gráfica activa (Sway/Wayland/greetd) desde otra TTY."
  echo -e "Tu TTY actual es: ${BOLD}$CURRENT_TTY${NC}"
  echo ""

  if [[ "$FORCE" != "true" ]]; then
    read -r -p "¿Cerrar sesión gráfica automáticamente y continuar con la desinstalación? [s/N]: " CERRAR_GRAFICA
    case "${CERRAR_GRAFICA,,}" in
      s|si|y|yes) ;;
      *)
        echo "Operación cancelada."
        exit 0
        ;;
    esac
  fi

  cerrar_sesion_grafica
fi

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
# 4. Backup de archivos de shell antes de eliminarlos (por si algo sale mal)
# ------------------------------------------------------------------------------
log_step "4. Haciendo backup de archivos de shell críticos"

BACKUP_SHELL_DIR="$HOME/.dotfiles_backup/shell_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_SHELL_DIR"
for shell_file in "$HOME/.zshrc" "$HOME/.zprofile" "$HOME/.bashrc" "$HOME/.profile"; do
  if [[ -f "$shell_file" ]]; then
    cp -a "$shell_file" "$BACKUP_SHELL_DIR/" 2>/dev/null || true
  fi
done
log_ok "Backup de archivos de shell guardado en: $BACKUP_SHELL_DIR"

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
echo -e "${YELLOW}Nota:${NC} Si usaste --force desde una sesión gráfica, reiniciá el equipo${NC}"
echo -e "${YELLOW}para que los cambios de entorno gráfico surtan efecto.${NC}"

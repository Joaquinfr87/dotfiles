#!/usr/bin/env bash
# ==============================================================================
# install.sh — Orquestador de instalación de dotfiles
# ==============================================================================
# Uso:
#   ./install.sh --desktop   -> Entorno gráfico completo (Sway + Noctalia + Dev Tools)
#   ./install.sh --server    -> Entorno solo terminal para SSH (Zsh + Tmux + Neovim + Git)
#   ./install.sh --sync      -> Solo copiar/actualizar configuraciones (con backup)
# ==============================================================================
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$DOTFILES_DIR/install"

# Asegurar permisos de ejecución en scripts
chmod +x "$INSTALL_DIR"/*.sh "$DOTFILES_DIR"/bin/* 2>/dev/null || true

# shellcheck disable=SC1091
source "$INSTALL_DIR/00-helpers.sh"

show_banner() {
  echo -e "${CYAN}"
  echo "  ██████╗  ██████╗ ████████╗███████╗██╗██╗     ███████╗███████╗"
  echo "  ██╔══██╗██╔═══██╗╚══██╔══╝██╔════╝██║██║     ██╔════╝██╔════╝"
  echo "  ██║  ██║██║   ██║   ██║   █████╗  ██║██║     █████╗  ███████╗"
  echo "  ██║  ██║██║   ██║   ██║   ██╔══╝  ██║██║     ██╔══╝  ╚════██║"
  echo "  ██████╔╝╚██████╔╝   ██║   ██║     ██║███████╗███████╗███████║"
  echo "  ╚═════╝  ╚═════╝    ╚═╝   ╚═╝     ╚═╝╚══════╝╚══════╝╚══════╝"
  echo -e "${NC}"
  echo -e "${BOLD}Instalador modular para Debian / Linux${NC}"
  echo -e "Repositorio: ${BLUE}$DOTFILES_DIR${NC}\n"
}

run_server_install() {
  export DOTFILES_PROFILE="server"
  log_info "Iniciando instalación para Servidor / Terminal SSH..."

  "$INSTALL_DIR/01-base-packages.sh"
  "$INSTALL_DIR/02-cli-tools.sh"
  "$INSTALL_DIR/03-shell.sh"
  "$INSTALL_DIR/07-copy-configs.sh" "server"

  log_step "¡Instalación para Servidor / SSH completada con éxito!"
  echo -e "Resumen:"
  echo -e "  - Shell      : Zsh + Powerlevel10k + Autosuggestions"
  echo -e "  - Multiplexer: Tmux con persistencia (resurrect/continuum) y sessionizer"
  echo -e "  - Editor     : Neovim (LazyVim)"
  echo -e "  - Git        : Configuración global con aliases y soporte delta"
  echo -e "  - Sincronizar: Usa el comando ${BOLD}dot-sync${NC} para sincronizar cambios en el futuro."
  echo -e "\n${YELLOW}Nota:${NC} Reinicia tu terminal o ejecuta: ${BOLD}exec zsh${NC}"
}

run_desktop_install() {
  export DOTFILES_PROFILE="desktop"
  log_info "Iniciando instalación para Entorno de Escritorio completo..."

  "$INSTALL_DIR/01-base-packages.sh"
  "$INSTALL_DIR/02-cli-tools.sh"
  "$INSTALL_DIR/03-shell.sh"
  "$INSTALL_DIR/04-desktop-packages.sh"
  "$INSTALL_DIR/05-noctalia.sh"
  "$INSTALL_DIR/06-fonts-wallpapers.sh"
  "$INSTALL_DIR/07-copy-configs.sh" "desktop"

  log_step "¡Instalación de Escritorio completada con éxito!"
  echo -e "Resumen:"
  echo -e "  - Compositor : Sway (Gruvbox Material Dark)"
  echo -e "  - Shell UI   : Noctalia v5 (Barra, Launcher, Notificaciones, Lock)"
  echo -e "  - Monitores  : Kanshi (laptop, presentación, externo)"
  echo -e "  - Terminal   : Kitty + Tmux + Neovim"
  echo -e "  - Navegador  : Zen Browser"
  echo -e "  - Sincronizar: Usa el comando ${BOLD}dot-sync${NC} para sincronizar cambios en el futuro."
  echo -e "\n${YELLOW}Nota:${NC} Para entrar a Sway, inicia sesión en tty1 o ejecuta: ${BOLD}sway${NC}"
}

run_sync_only() {
  local prof
  prof="$(detect_profile)"
  log_info "Sincronizando configuraciones para perfil detectado: $prof"
  "$INSTALL_DIR/07-copy-configs.sh" "$prof"
}

# --- Procesar argumentos ---
ACTION="${1:-}"

case "$ACTION" in
  --desktop|-d)
    show_banner
    run_desktop_install
    ;;
  --server|--cli|-s)
    show_banner
    run_server_install
    ;;
  --sync)
    show_banner
    run_sync_only
    ;;
  --help|-h)
    show_banner
    echo "Uso: ./install.sh [OPCIÓN]"
    echo ""
    echo "Opciones:"
    echo "  --desktop, -d   Instala el entorno gráfico completo (Sway, Noctalia, Kitty, etc.)"
    echo "  --server,  -s   Instala solo entorno terminal (Zsh, Tmux, Neovim, Git, etc.)"
    echo "  --sync          Copia configuraciones con backup sin reinstalar paquetes"
    echo "  --help,    -h   Muestra esta ayuda"
    echo ""
    echo "Si se ejecuta sin opciones, se mostrará el menú interactivo."
    exit 0
    ;;
  "")
    show_banner
    echo "Selecciona el perfil de instalación:"
    echo "  1) Entorno de Escritorio completo (Sway + Noctalia + Terminal + Dev Tools)"
    echo "  2) Entorno Servidor / Terminal SSH (Zsh + Tmux + Neovim + Git + CLI Tools)"
    echo "  3) Solo sincronizar / copiar configuraciones (sin instalar paquetes)"
    echo "  4) Salir"
    echo ""
    read -r -p "Elige una opción [1-4]: " OPTION
    case "$OPTION" in
      1) run_desktop_install ;;
      2) run_server_install ;;
      3) run_sync_only ;;
      4) echo "Instalación cancelada."; exit 0 ;;
      *) log_err "Opción no válida."; exit 1 ;;
    esac
    ;;
  *)
    log_err "Opción no reconocida: $ACTION. Usa './install.sh --help'."
    exit 1
    ;;
esac

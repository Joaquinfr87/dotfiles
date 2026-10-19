#!/usr/bin/env bash
# ==============================================================================
# install.sh — Orquestador de instalación de dotfiles
# ==============================================================================
# Uso:
#   ./install.sh --desktop    -> Entorno gráfico completo (Sway + Noctalia + Greeter + Dev Tools)
#   ./install.sh --server     -> Entorno solo terminal para SSH (Zsh + Tmux + Neovim + Git)
#   ./install.sh --dev-tools  -> Solo herramientas de desarrollo & AI (Node, Docker, OpenCode, etc.)
#   ./install.sh --all        -> Escritorio completo + Stack Dev & AI
#   ./install.sh --sync       -> Solo copiar/actualizar configuraciones (con backup)
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

run_dev_tools() {
  "$INSTALL_DIR/08-dev-ai-tools.sh" all
}

run_server_install() {
  local with_dev=${1:-false}
  export DOTFILES_PROFILE="server"
  log_info "Iniciando instalación para Servidor / Terminal SSH..."

  "$INSTALL_DIR/01-base-packages.sh"
  "$INSTALL_DIR/02-cli-tools.sh"
  "$INSTALL_DIR/03-shell.sh"
  "$INSTALL_DIR/07-copy-configs.sh" "server"

  if [[ "$with_dev" == "true" ]]; then
    run_dev_tools
  fi

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
  local with_dev=${1:-false}
  export DOTFILES_PROFILE="desktop"
  log_info "Iniciando instalación para Entorno de Escritorio completo..."

  "$INSTALL_DIR/01-base-packages.sh"
  "$INSTALL_DIR/02-cli-tools.sh"
  "$INSTALL_DIR/03-shell.sh"
  "$INSTALL_DIR/04-desktop-packages.sh"
  "$INSTALL_DIR/05-noctalia.sh"
  "$INSTALL_DIR/06-fonts-wallpapers.sh"
  "$INSTALL_DIR/07-copy-configs.sh" "desktop"

  if [[ "$with_dev" == "true" ]]; then
    run_dev_tools
  fi

  log_step "¡Instalación de Escritorio completada con éxito!"
  echo -e "Resumen:"
  echo -e "  - Compositor : Sway (Gruvbox Material Dark)"
  echo -e "  - Shell UI   : Noctalia v5 (Barra, Launcher, Notificaciones, Lock)"
  echo -e "  - Greeter    : Noctalia Greeter (greetd display manager)"
  echo -e "  - Monitores  : Kanshi (laptop, presentación, externo)"
  echo -e "  - Terminal   : Kitty + Tmux + Neovim"
  echo -e "  - Navegador  : Zen Browser"
  echo -e "  - Sincronizar: Usa el comando ${BOLD}dot-sync${NC} para sincronizar cambios en el futuro."
  echo -e "\n${YELLOW}Nota:${NC} Para entrar a Sway, inicia sesión mediante greetd o en tty1 con: ${BOLD}sway${NC}"
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
    run_desktop_install false
    ;;
  --server|--cli|-s)
    show_banner
    run_server_install false
    ;;
  --all|-a)
    show_banner
    run_desktop_install true
    ;;
  --dev|--dev-tools)
    show_banner
    run_dev_tools
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
    echo "  --desktop, -d     Instala el entorno gráfico completo (Sway, Noctalia, Greeter, Kitty, etc.)"
    echo "  --server,  -s     Instala solo entorno terminal para SSH (Zsh, Tmux, Neovim, Git, etc.)"
    echo "  --all,     -a     Instala Escritorio completo + Herramientas Dev & AI (Node, Docker, etc.)"
    echo "  --dev-tools       Instala solo las herramientas de desarrollo y agentes AI"
    echo "  --sync            Copia configuraciones con backup sin reinstalar paquetes"
    echo "  --help,    -h     Muestra esta ayuda"
    echo ""
    echo "Si se ejecuta sin opciones, se mostrará el menú interactivo."
    exit 0
    ;;
  "")
    show_banner
    echo "Selecciona el perfil de instalación:"
    echo "  1) Entorno de Escritorio completo (Sway + Noctalia + Greeter + Terminal)"
    echo "  2) Entorno Servidor / Terminal SSH (Zsh + Tmux + Neovim + Git + CLIs)"
    echo "  3) Stack de Desarrollo & AI (Node.js, Docker Compose, OpenCode, Freebuff, etc.)"
    echo "  4) Instalación Total (Escritorio + Dev & AI Tools)"
    echo "  5) Solo sincronizar / copiar configuraciones (sin instalar paquetes)"
    echo "  6) Salir"
    echo ""
    read -r -p "Elige una opción [1-6]: " OPTION
    case "$OPTION" in
      1)
        run_desktop_install false
        read -r -p "¿Deseas instalar también las herramientas de desarrollo e IA (Node, Docker, OpenCode)? [s/N]: " DEV_OPT
        [[ "$DEV_OPT" =~ ^[sS]$ ]] && run_dev_tools
        ;;
      2)
        run_server_install false
        read -r -p "¿Deseas instalar también las herramientas de desarrollo e IA (Node, Docker, OpenCode)? [s/N]: " DEV_OPT
        [[ "$DEV_OPT" =~ ^[sS]$ ]] && run_dev_tools
        ;;
      3)
        run_dev_tools
        ;;
      4)
        run_desktop_install true
        ;;
      5)
        run_sync_only
        ;;
      6)
        echo "Instalación cancelada."; exit 0
        ;;
      *)
        log_err "Opción no válida."; exit 1
        ;;
    esac
    ;;
  *)
    log_err "Opción no reconocida: $ACTION. Usa './install.sh --help'."
    exit 1
    ;;
esac

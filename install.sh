#!/usr/bin/env bash
# ==============================================================================
# install.sh — Orquestador de instalación de dotfiles
# ==============================================================================
# Uso:
#   ./install.sh             -> Menú interactivo simple y modular
#   ./install.sh --desktop   -> Entorno escritorio completo (Sway + Noctalia + Greeter)
#   ./install.sh --server    -> Entorno servidor para SSH (Zsh nativo + Starship + Tmux + Neovim)
#   ./install.sh --sync      -> Solo sincronizar/copiar configuraciones (con backup)
#   ./install.sh --extras    -> Submenú de herramientas extras (Node, Docker, AI, OMZ)
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

# --- 1. ENTORNO SERVIDOR ---
run_server_install() {
  export DOTFILES_PROFILE="server"
  log_info "Iniciando instalación para Servidor / Terminal SSH..."

  "$INSTALL_DIR/01-base-packages.sh"
  "$INSTALL_DIR/02-cli-tools.sh"
  "$INSTALL_DIR/03-shell.sh"
  "$INSTALL_DIR/07-copy-configs.sh" "server"

  log_step "¡Instalación para Servidor / SSH completada con éxito!"
  echo -e "Resumen del entorno:"
  echo -e "  - Shell      : Zsh nativo ultrarrápido (< 20 ms)"
  echo -e "  - Prompt     : Starship (Gruvbox Material Dark)"
  echo -e "  - Multiplexer: Tmux con persistencia (resurrect/continuum) y sessionizer"
  echo -e "  - Editor     : Neovim (LazyVim)"
  echo -e "  - Git        : Configuración global con aliases y soporte delta"
  echo -e "  - Sincronizar: Usa el comando ${BOLD}dot-sync${NC} para gestionar cambios futuros."
  echo -e "\n${YELLOW}Nota:${NC} Reinicia tu terminal o ejecuta: ${BOLD}exec zsh${NC}"
}

# --- 2. ENTORNO ESCRITORIO ---
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
  echo -e "Resumen del entorno:"
  echo -e "  - Compositor : Sway (Gruvbox Material Dark)"
  echo -e "  - Shell UI   : Noctalia v5 (Barra, Launcher, Notificaciones, Lock)"
  echo -e "  - Greeter    : Noctalia Greeter (greetd display manager)"
  echo -e "  - Monitores  : Kanshi (laptop, presentación, externo)"
  echo -e "  - Terminal   : Kitty + Tmux + Neovim"
  echo -e "  - Navegador  : Zen Browser"
  echo -e "  - Sincronizar: Usa el comando ${BOLD}dot-sync${NC} para gestionar cambios futuros."
  echo -e "\n${YELLOW}Nota:${NC} Para entrar a Sway, inicia sesión mediante greetd o en tty1 con: ${BOLD}sway${NC}"
}

# --- 3. SINCRONIZAR CONFIGURACIONES ---
run_sync_only() {
  local prof
  prof="$(detect_profile)"
  log_info "Sincronizando configuraciones para perfil detectado: $prof"
  "$INSTALL_DIR/07-copy-configs.sh" "$prof"
}

# --- 4. SUBMENÚ DE HERRAMIENTAS EXTRAS ---
show_extras_menu() {
  while true; do
    echo -e "\n${CYAN}====================================================================${NC}"
    echo -e "${BOLD}${CYAN}>> Herramientas Extras & Opcionales${NC}"
    echo -e "${CYAN}====================================================================${NC}"
    echo "  1) Instalar todo el stack Dev & AI (Node, Docker, OpenCode, Freebuff, AGY, Codex)"
    echo "  2) Node.js LTS (vía NVM + npm)"
    echo "  3) Docker Engine + Docker Compose + Lazydocker"
    echo "  4) OpenCode CLI"
    echo "  5) Freebuff CLI"
    echo "  6) Oh My Zsh + Powerlevel10k (Alternativa opcional a Starship)"
    echo "  7) Volver al menú principal"
    echo ""
    read -r -p "Selecciona una opción [1-7]: " EXTRA_OPT
    case "$EXTRA_OPT" in
      1) "$INSTALL_DIR/08-dev-ai-tools.sh" all ;;
      2) "$INSTALL_DIR/08-dev-ai-tools.sh" node ;;
      3) "$INSTALL_DIR/08-dev-ai-tools.sh" docker ;;
      4) "$INSTALL_DIR/08-dev-ai-tools.sh" opencode ;;
      5) "$INSTALL_DIR/08-dev-ai-tools.sh" freebuff ;;
      6) "$INSTALL_DIR/03-shell.sh" --omz ;;
      7) break ;;
      *) log_err "Opción no válida." ;;
    esac
    echo -e "\n${GREEN}[OK] Acción completada.${NC}"
    read -r -p "Presiona [Enter] para continuar..."
  done
}

# --- MENÚ PRINCIPAL ---
show_main_menu() {
  while true; do
    show_banner
    echo -e "${BOLD}Selecciona una opción:${NC}"
    echo "  1) Entorno escritorio completo"
    echo "  2) Entorno servidor"
    echo "  3) Sincronizar configuraciones"
    echo "  4) Herramientas extras (Node, Docker, AI, Oh My Zsh...)"
    echo "  5) Salir"
    echo ""
    read -r -p "Elige una opción [1-5]: " OPTION
    case "$OPTION" in
      1)
        run_desktop_install
        break
        ;;
      2)
        run_server_install
        break
        ;;
      3)
        run_sync_only
        break
        ;;
      4)
        show_extras_menu
        ;;
      5)
        echo "Operación cancelada."
        exit 0
        ;;
      *)
        log_err "Opción no válida."
        sleep 1
        ;;
    esac
  done
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
  --extras|--dev-tools)
    show_banner
    show_extras_menu
    ;;
  --omz)
    show_banner
    "$INSTALL_DIR/03-shell.sh" --omz
    ;;
  --help|-h)
    show_banner
    echo "Uso: ./install.sh [OPCIÓN]"
    echo ""
    echo "Opciones principales:"
    echo "  --desktop, -d   Instala el entorno escritorio completo (Sway, Noctalia, Greeter)"
    echo "  --server,  -s   Instala el entorno servidor para SSH (Zsh, Starship, Tmux, Neovim)"
    echo "  --sync          Copia configuraciones con backup sin reinstalar paquetes"
    echo "  --extras        Abre el submenú de herramientas extras (Node, Docker, AI, OMZ)"
    echo "  --omz           Instala Oh My Zsh y Powerlevel10k como alternativa a Starship"
    echo "  --help,    -h   Muestra esta ayuda"
    echo ""
    echo "Si se ejecuta sin opciones, se mostrará el menú principal interactivo."
    exit 0
    ;;
  "")
    show_main_menu
    ;;
  *)
    log_err "Opción no reconocida: $ACTION. Usa './install.sh --help'."
    exit 1
    ;;
esac

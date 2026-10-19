#!/usr/bin/env bash
# ==============================================================================
# install.sh — Orquestador de instalación 100% CLI de dotfiles
# ==============================================================================
# Flujo interactivo:
#   1. Tipo de entorno: Escritorio completo o Servidor SSH
#   2. Prompt / Shell : Starship (Recomendado) u Oh My Zsh + p10k
#   3. Menú interactivo CLI con casillas [X]/[ ] para herramientas extras:
#      (Node.js, pnpm, Docker, OpenCode, Freebuff, Codex, AGY...)
# ==============================================================================
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$DOTFILES_DIR/install"

# Asegurar permisos de ejecución en scripts
chmod +x "$INSTALL_DIR"/*.sh "$DOTFILES_DIR"/bin/* 2>/dev/null || true

# shellcheck disable=SC1091
source "$INSTALL_DIR/00-helpers.sh"

# ==============================================================================
# REGISTRO EXTENSIBLE DE HERRAMIENTAS EXTRAS
# Para añadir una nueva herramienta en el futuro, solo añade una línea aquí:
# Formato: "ID:Nombre legible:Estado inicial (1=seleccionado, 0=deseleccionado)"
# ==============================================================================
EXTRA_TOOLS_REGISTRY=(
  "node:Node.js LTS (JavaScript runtime vía NVM):1"
  "pnpm:pnpm (Gestor de paquetes ultrarrápido):1"
  "docker:Docker Engine + Docker Compose + Lazydocker:1"
  "opencode:OpenCode CLI (Agente AI para terminal):1"
  "freebuff:Freebuff CLI (Agente AI para proyectos):1"
  "codex:Codex CLI (Agente AI interactivo):1"
  "agy:Antigravity CLI (agy):1"
)

show_banner() {
  echo -e "${CYAN}"
  echo "  ██████╗  ██████╗ ████████╗███████╗██╗██╗     ███████╗███████╗"
  echo "  ██╔══██╗██╔═══██╗╚══██╔══╝██╔════╝██║██║     ██╔════╝██╔════╝"
  echo "  ██║  ██║██║   ██║   ██║   █████╗  ██║██║     █████╗  ███████╗"
  echo "  ██║  ██║██║   ██║   ██║   ██╔══╝  ██║██║     ██╔══╝  ╚════██║"
  echo "  ██████╔╝╚██████╔╝   ██║   ██║     ██║███████╗███████╗███████║"
  echo "  ╚═════╝  ╚═════╝    ╚═╝   ╚═╝     ╚═╝╚══════╝╚══════╝╚══════╝"
  echo -e "${NC}"
  echo -e "${BOLD}Instalador modular 100% CLI para Debian / Linux${NC}"
  echo -e "Repositorio: ${BLUE}$DOTFILES_DIR${NC}\n"
}

# ==============================================================================
# PASO 2: Selección de Prompt / Shell
# ==============================================================================
prompt_shell_choice() {
  echo -e "${CYAN}====================================================================${NC}"
  echo -e "${BOLD}${CYAN}>> PASO 2: Selección de Shell y Prompt${NC}"
  echo -e "${CYAN}====================================================================${NC}"
  echo "Selecciona tu entorno de Shell:"
  echo -e "  1) ${BOLD}Starship${NC} (Recomendado — Rust, ultrarrápido < 20ms, tema Gruvbox)"
  echo -e "  2) ${BOLD}Oh My Zsh + Powerlevel10k${NC} (Entorno clásico con plugins OMZ)"
  echo ""
  local choice
  while true; do
    read -r -p "Opción [1-2, por defecto 1]: " choice
    case "${choice:-1}" in
      1)
        SHELL_CHOICE="starship"
        log_ok "Seleccionado: Starship Prompt (Zsh nativo)"
        break
        ;;
      2)
        SHELL_CHOICE="omz"
        log_ok "Seleccionado: Oh My Zsh + Powerlevel10k"
        break
        ;;
      *)
        log_err "Opción no válida. Introduce 1 o 2."
        ;;
    esac
  done
}

# ==============================================================================
# PASO 3: Menú Interactivo CLI de Selección de Herramientas (Tachando [X] / [ ])
# ==============================================================================
prompt_extras_selection() {
  local tool_ids=()
  local tool_labels=()
  local tool_selected=()

  # Cargar herramientas desde el registro
  for entry in "${EXTRA_TOOLS_REGISTRY[@]}"; do
    IFS=':' read -r id label state <<< "$entry"
    tool_ids+=("$id")
    tool_labels+=("$label")
    tool_selected+=("$state")
  done

  while true; do
    echo -e "\n${CYAN}====================================================================${NC}"
    echo -e "${BOLD}${CYAN}>> PASO 3: Herramientas Extras & Agentes AI${NC}"
    echo -e "${CYAN}====================================================================${NC}"
    echo -e "Marca o desmarca las herramientas escribiendo su número [1-${#tool_ids[@]}]:\n"

    for i in "${!tool_ids[@]}"; do
      local num=$((i + 1))
      local mark
      if [[ "${tool_selected[$i]}" -eq 1 ]]; then
        mark="${GREEN}[X]${NC}"
      else
        mark="${RED}[ ]${NC}"
      fi
      echo -e "  [${BOLD}$num${NC}] $mark ${tool_labels[$i]}"
    done

    echo ""
    echo -e "  ${BOLD}[A]${NC} Marcar todos   ${BOLD}[N]${NC} Desmarcar todos"
    echo -e "  ${BOLD}[C]${NC} Continuar con la instalación (o pulsa Enter)"
    echo -e "  ${BOLD}[S]${NC} Saltar herramientas extras"
    echo ""
    read -r -p "Alternar opción o Continuar [1-${#tool_ids[@]}, A, N, C, S]: " opt_input

    case "${opt_input,,}" in
      c|"")
        break
        ;;
      s)
        for i in "${!tool_selected[@]}"; do tool_selected[$i]=0; done
        break
        ;;
      a)
        for i in "${!tool_selected[@]}"; do tool_selected[$i]=1; done
        ;;
      n)
        for i in "${!tool_selected[@]}"; do tool_selected[$i]=0; done
        ;;
      *)
        if [[ "$opt_input" =~ ^[0-9]+$ ]] && (( opt_input >= 1 && opt_input <= ${#tool_ids[@]} )); then
          local idx=$((opt_input - 1))
          if [[ "${tool_selected[$idx]}" -eq 1 ]]; then
            tool_selected[$idx]=0
          else
            tool_selected[$idx]=1
          fi
        else
          log_err "Opción no reconocida: $opt_input"
          sleep 1
        fi
        ;;
    esac
  done

  # Recolectar herramientas seleccionadas
  SELECTED_TOOLS=()
  for i in "${!tool_ids[@]}"; do
    if [[ "${tool_selected[$i]}" -eq 1 ]]; then
      SELECTED_TOOLS+=("${tool_ids[$i]}")
    fi
  done

  if [[ ${#SELECTED_TOOLS[@]} -gt 0 ]]; then
    log_ok "Herramientas seleccionadas para instalar: ${SELECTED_TOOLS[*]}"
  else
    log_info "No se seleccionaron herramientas extras."
  fi
}

# ==============================================================================
# EJECUCIÓN DEL FLUJO DE INSTALACIÓN
# ==============================================================================
execute_installation() {
  local profile=$1
  local shell_mode=$2
  shift 2
  local tools=("$@")

  log_step "Iniciando instalación del sistema (Perfil: $profile)"

  # 1. Paquetes base y utilidades CLI
  "$INSTALL_DIR/01-base-packages.sh"
  "$INSTALL_DIR/02-cli-tools.sh"

  # 2. Configuración de Shell según elección
  if [[ "$shell_mode" == "omz" ]]; then
    "$INSTALL_DIR/03-shell.sh" --omz
  else
    "$INSTALL_DIR/03-shell.sh" --starship
  fi

  # 3. Componentes gráficos (solo para Desktop)
  if [[ "$profile" == "desktop" ]]; then
    "$INSTALL_DIR/04-desktop-packages.sh"
    "$INSTALL_DIR/05-noctalia.sh"
    "$INSTALL_DIR/06-fonts-wallpapers.sh"
  fi

  # 4. Despliegue de configuraciones con backup previo
  "$INSTALL_DIR/07-copy-configs.sh" "$profile"

  # 5. Herramientas extras seleccionadas
  if [[ ${#tools[@]} -gt 0 ]]; then
    "$INSTALL_DIR/08-dev-ai-tools.sh" "${tools[@]}"
  fi

  log_step "¡Instalación completada con éxito!"
  echo -e "Resumen:"
  echo -e "  - Perfil       : ${BOLD}$profile${NC}"
  echo -e "  - Shell        : ${BOLD}$shell_mode${NC}"
  echo -e "  - Extras       : ${tools[*]:-ninguna}"
  echo -e "  - Sincronizar  : Usa ${BOLD}dot-sync${NC} para gestionar cambios en tus dotfiles."
  echo -e "\n${YELLOW}Nota:${NC} Para aplicar los cambios de shell, ejecuta: ${BOLD}exec zsh${NC}"
}

# ==============================================================================
# MENÚ PRINCIPAL
# ==============================================================================
show_main_menu() {
  while true; do
    show_banner
    echo -e "${CYAN}====================================================================${NC}"
    echo -e "${BOLD}${CYAN}>> PASO 1: Selección de Entorno${NC}"
    echo -e "${CYAN}====================================================================${NC}"
    echo "  1) Entorno de escritorio completo (Sway + Noctalia + Greeter + Terminal)"
    echo "  2) Entorno de servidor (Solo terminal para SSH, sin interfaz gráfica)"
    echo "  3) Sincronizar configuraciones (con backup automático)"
    echo "  4) Menú de herramientas extras (instalar solo Node, Docker, AI...)"
    echo "  5) Salir"
    echo ""
    read -r -p "Elige una opción [1-5]: " MAIN_OPT
    case "$MAIN_OPT" in
      1)
        prompt_shell_choice
        prompt_extras_selection
        execute_installation "desktop" "$SHELL_CHOICE" "${SELECTED_TOOLS[@]}"
        break
        ;;
      2)
        prompt_shell_choice
        prompt_extras_selection
        execute_installation "server" "$SHELL_CHOICE" "${SELECTED_TOOLS[@]}"
        break
        ;;
      3)
        local prof
        prof="$(detect_profile)"
        log_info "Sincronizando configuraciones para perfil detectado: $prof"
        "$INSTALL_DIR/07-copy-configs.sh" "$prof"
        break
        ;;
      4)
        prompt_extras_selection
        if [[ ${#SELECTED_TOOLS[@]} -gt 0 ]]; then
          "$INSTALL_DIR/08-dev-ai-tools.sh" "${SELECTED_TOOLS[@]}"
        fi
        break
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

# --- Procesar banderas de línea de comandos directas ---
ACTION="${1:-}"

case "$ACTION" in
  --desktop|-d)
    show_banner
    prompt_shell_choice
    prompt_extras_selection
    execute_installation "desktop" "$SHELL_CHOICE" "${SELECTED_TOOLS[@]}"
    ;;
  --server|--cli|-s)
    show_banner
    prompt_shell_choice
    prompt_extras_selection
    execute_installation "server" "$SHELL_CHOICE" "${SELECTED_TOOLS[@]}"
    ;;
  --sync)
    show_banner
    prof="$(detect_profile)"
    "$INSTALL_DIR/07-copy-configs.sh" "$prof"
    ;;
  --extras|--dev-tools)
    show_banner
    prompt_extras_selection
    if [[ ${#SELECTED_TOOLS[@]} -gt 0 ]]; then
      "$INSTALL_DIR/08-dev-ai-tools.sh" "${SELECTED_TOOLS[@]}"
    fi
    ;;
  --help|-h)
    show_banner
    echo "Uso: ./install.sh [OPCIÓN]"
    echo ""
    echo "Opciones CLI directas:"
    echo "  --desktop, -d   Instala el entorno de escritorio completo (Sway, Noctalia, Greeter)"
    echo "  --server,  -s   Instala el entorno de servidor para SSH (Zsh, Tmux, Neovim)"
    echo "  --sync          Copia configuraciones con backup sin reinstalar paquetes"
    echo "  --extras        Abre directamente el menú de selección de herramientas extras"
    echo "  --help,    -h   Muestra esta ayuda"
    echo ""
    echo "Si se ejecuta sin opciones, iniciará el asistente guiado 100% CLI."
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

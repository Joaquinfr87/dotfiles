#!/usr/bin/env bash
# ==============================================================================
# install.sh — 100% CLI dotfiles installer for Debian 13 (trixie)
# ==============================================================================
# Interactive flow:
#   1. Environment: full desktop or SSH server
#   2. Prompt / shell: Starship (recommended) or Oh My Zsh + p10k
#   3. Interactive CLI menu with [X]/[ ] checkboxes for extra tools:
#      (Node.js, pnpm, Docker, OpenCode, Freebuff, Codex, AGY...)
#   4. Optional (opt-in): Gruvbox GRUB theme + Plymouth boot splash
# ==============================================================================
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$DOTFILES_DIR/install"

# Make sure every script is executable
chmod +x "$INSTALL_DIR"/*.sh "$DOTFILES_DIR"/bin/* 2>/dev/null || true

# shellcheck disable=SC1091
source "$INSTALL_DIR/00-helpers.sh"

# ==============================================================================
# EXTENSIBLE EXTRA TOOLS REGISTRY
# To add a new tool later, just add one line here:
# Format: "ID:Human readable name:Initial state (1=selected, 0=unselected)"
# ==============================================================================
EXTRA_TOOLS_REGISTRY=(
  "node:Node.js LTS (JavaScript runtime via NVM):1"
  "pnpm:pnpm (fast package manager):1"
  "docker:Docker Engine + Docker Compose + Lazydocker:1"
  "opencode:OpenCode CLI (AI agent for the terminal):1"
  "freebuff:Freebuff CLI (AI agent for projects):1"
  "codex:Codex CLI (interactive AI agent):1"
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
  echo -e "${BOLD}Modular 100% CLI installer for Debian 13 (trixie)${NC}"
  echo -e "Repository: ${BLUE}$DOTFILES_DIR${NC}\n"
}

# Detect the profile from the environment or the saved profile file
detect_profile() {
  if [[ -n "${DOTFILES_PROFILE:-}" ]]; then
    echo "$DOTFILES_PROFILE"
  elif [[ -f "$HOME/.dotfiles_profile" ]]; then
    cat "$HOME/.dotfiles_profile"
  elif command -v sway >/dev/null 2>&1 || [[ -d "$HOME/.config/sway" ]]; then
    echo "desktop"
  else
    echo "server"
  fi
}

# ==============================================================================
# STEP 2: Shell / prompt selection
# ==============================================================================
prompt_shell_choice() {
  echo -e "${CYAN}====================================================================${NC}"
  echo -e "${BOLD}${CYAN}>> STEP 2: Shell and prompt selection${NC}"
  echo -e "${CYAN}====================================================================${NC}"
  echo "Choose your shell environment:"
  echo -e "  1) ${BOLD}Starship${NC} (Recommended — Rust, < 20ms startup, Gruvbox theme)"
  echo -e "  2) ${BOLD}Oh My Zsh + Powerlevel10k${NC} (classic environment with OMZ plugins)"
  echo ""
  local choice
  while true; do
    read -r -p "Option [1-2, default 1]: " choice
    case "${choice:-1}" in
      1)
        SHELL_CHOICE="starship"
        log_ok "Selected: Starship prompt (native Zsh)"
        break
        ;;
      2)
        SHELL_CHOICE="omz"
        log_ok "Selected: Oh My Zsh + Powerlevel10k"
        break
        ;;
      *)
        log_err "Invalid option. Enter 1 or 2."
        ;;
    esac
  done
}

# ==============================================================================
# STEP 3: Interactive CLI menu with [X]/[ ] checkboxes
# ==============================================================================
prompt_extras_selection() {
  local tool_ids=()
  local tool_labels=()
  local tool_selected=()

  # Load tools from the registry
  for entry in "${EXTRA_TOOLS_REGISTRY[@]}"; do
    IFS=':' read -r id label state <<< "$entry"
    tool_ids+=("$id")
    tool_labels+=("$label")
    tool_selected+=("$state")
  done

  while true; do
    echo -e "\n${CYAN}====================================================================${NC}"
    echo -e "${BOLD}${CYAN}>> STEP 3: Extra tools and AI agents${NC}"
    echo -e "${CYAN}====================================================================${NC}"
    echo -e "Toggle a tool by typing its number [1-${#tool_ids[@]}]:\n"

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
    echo -e "  ${BOLD}[A]${NC} Select all   ${BOLD}[N]${NC} Deselect all"
    echo -e "  ${BOLD}[C]${NC} Continue with the installation (or press Enter)"
    echo -e "  ${BOLD}[S]${NC} Skip extra tools"
    echo ""
    read -r -p "Toggle an option or continue [1-${#tool_ids[@]}, A, N, C, S]: " opt_input

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
          log_err "Unrecognized option: $opt_input"
          sleep 1
        fi
        ;;
    esac
  done

  # Collect the selected tools
  SELECTED_TOOLS=()
  for i in "${!tool_ids[@]}"; do
    if [[ "${tool_selected[$i]}" -eq 1 ]]; then
      SELECTED_TOOLS+=("${tool_ids[$i]}")
    fi
  done

  if [[ ${#SELECTED_TOOLS[@]} -gt 0 ]]; then
    log_ok "Tools selected for installation: ${SELECTED_TOOLS[*]}"
  else
    log_info "No extra tools selected."
  fi
}

# ==============================================================================
# INSTALLATION FLOW
# ==============================================================================
execute_installation() {
  local profile=$1
  local shell_mode=$2
  shift 2
  local tools=("$@")

  log_step "Starting the system installation (profile: $profile)"

  # 1. Base packages and CLI utilities
  "$INSTALL_DIR/01-base-packages.sh"
  "$INSTALL_DIR/02-cli-tools.sh"

  # 2. Shell configuration according to the user's choice
  if [[ "$shell_mode" == "omz" ]]; then
    "$INSTALL_DIR/03-shell.sh" --omz
  else
    "$INSTALL_DIR/03-shell.sh" --starship
  fi

  # 3. Graphical components (desktop profile only)
  if [[ "$profile" == "desktop" ]]; then
    "$INSTALL_DIR/04-desktop-packages.sh"
    "$INSTALL_DIR/05-noctalia.sh"
    "$INSTALL_DIR/06-fonts-wallpapers.sh"
  fi

  # 4. Deploy configurations with a previous backup
  "$INSTALL_DIR/07-copy-configs.sh" "$profile"

  # 5. Selected extra tools
  if [[ ${#tools[@]} -gt 0 ]]; then
    "$INSTALL_DIR/08-dev-ai-tools.sh" "${tools[@]}"
  fi

  # 6. Optional boot theme (desktop only, opt-in)
  if [[ "$profile" == "desktop" ]]; then
    "$INSTALL_DIR/09-grub.sh" || log_warn "Optional GRUB/Plymouth setup was skipped or failed."
  fi

  log_step "Installation completed successfully!"
  echo -e "Summary:"
  echo -e "  - Profile      : ${BOLD}$profile${NC}"
  echo -e "  - Shell        : ${BOLD}$shell_mode${NC}"
  echo -e "  - Extras       : ${tools[*]:-none}"
  echo -e "  - Sync         : Use ${BOLD}dot-sync${NC} to manage dotfiles changes."
  echo -e "\n${YELLOW}Note:${NC} To apply the shell changes, run: ${BOLD}exec zsh${NC}"
}

# ==============================================================================
# MAIN MENU
# ==============================================================================
show_main_menu() {
  while true; do
    show_banner
    echo -e "${CYAN}====================================================================${NC}"
    echo -e "${BOLD}${CYAN}>> STEP 1: Environment selection${NC}"
    echo -e "${CYAN}====================================================================${NC}"
    echo "  1) Full desktop environment (Sway + Noctalia + Greeter + Terminal)"
    echo "  2) Server environment (terminal only for SSH, no graphical interface)"
    echo "  3) Synchronize configurations (with automatic backup)"
    echo "  4) Extra tools menu (install only Node, Docker, AI tools...)"
    echo "  5) Reset the system (uninstall and clean the environment)"
    echo "  6) Exit"
    echo ""
    read -r -p "Choose an option [1-6]: " MAIN_OPT
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
        log_info "Synchronizing configurations for detected profile: $prof"
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
        "$DOTFILES_DIR/uninstall.sh"
        break
        ;;
      6)
        echo "Operation cancelled."
        exit 0
        ;;
      *)
        log_err "Invalid option."
        sleep 1
        ;;
    esac
  done
}

# --- Direct command-line flags ---
ACTION="${1:-}"

case "$ACTION" in
  --desktop|-d)
    require_debian_13
    show_banner
    prompt_shell_choice
    prompt_extras_selection
    execute_installation "desktop" "$SHELL_CHOICE" "${SELECTED_TOOLS[@]}"
    ;;
  --server|--cli|-s)
    require_debian_13
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
    require_debian_13
    show_banner
    prompt_extras_selection
    if [[ ${#SELECTED_TOOLS[@]} -gt 0 ]]; then
      "$INSTALL_DIR/08-dev-ai-tools.sh" "${SELECTED_TOOLS[@]}"
    fi
    ;;
  --grub)
    require_debian_13
    show_banner
    "$INSTALL_DIR/09-grub.sh"
    ;;
  --reset|--uninstall)
    shift
    exec "$DOTFILES_DIR/uninstall.sh" "$@"
    ;;
  --help|-h)
    show_banner
    echo "Usage: ./install.sh [OPTION]"
    echo ""
    echo "Direct CLI options:"
    echo "  --desktop, -d   Install the full desktop environment (Sway, Noctalia, Greeter)"
    echo "  --server,  -s   Install the server environment for SSH (Zsh, Tmux, Neovim)"
    echo "  --sync          Copy configurations with backup without reinstalling packages"
    echo "  --extras        Open the extra tools selection menu directly"
    echo "  --grub          Install the optional Gruvbox GRUB theme and Plymouth splash"
    echo "  --reset         Reset the system by uninstalling packages and cleaning configs"
    echo "  --help,    -h   Show this help"
    echo ""
    echo "If run without options, the guided 100% CLI wizard starts."
    echo ""
    echo "Supported platform: Debian 13 (trixie) only."
    exit 0
    ;;
  "")
    require_debian_13
    show_main_menu
    ;;
  *)
    log_err "Unrecognized option: $ACTION. Use './install.sh --help'."
    exit 1
    ;;
esac

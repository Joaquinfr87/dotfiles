#!/usr/bin/env bash
# ==============================================================================
# install/08-dev-ai-tools.sh — Node.js, Docker Compose y Herramientas de IA
# ==============================================================================
# Permite instalar de forma modular:
#   - Node.js (vía NVM / FNM + corepack)
#   - Docker Engine + Docker Compose Plugin + Lazydocker
#   - OpenCode CLI
#   - Freebuff CLI (vía npm)
#   - Antigravity CLI (agy)
#   - Codex CLI
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/00-helpers.sh"

log_step "Instalador de Entornos de Desarrollo & Agentes AI"

mkdir -p "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$HOME/.opencode/bin:$PATH"

# ------------------------------------------------------------------------------
# 1. Node.js (vía NVM o FNM)
# ------------------------------------------------------------------------------
install_node() {
  log_info "Configurando Node.js LTS..."
  if ! has_cmd node; then
    # Instalar NVM si no existe
    export NVM_DIR="$HOME/.nvm"
    if [[ ! -d "$NVM_DIR" ]]; then
      log_info "Instalando NVM (Node Version Manager)..."
      curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
    fi
    # Cargar NVM
    # shellcheck disable=SC1091
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    log_info "Instalando última versión LTS de Node.js..."
    nvm install --lts
    nvm use --lts
    nvm alias default 'lts/*'
    log_ok "Node.js $(node --version) y npm $(npm --version) instalados."
  else
    log_ok "Node.js ya está instalado: $(node --version)"
  fi
}

# ------------------------------------------------------------------------------
# 2. Docker & Docker Compose
# ------------------------------------------------------------------------------
install_docker() {
  log_info "Configurando Docker Engine y Docker Compose..."
  if ! has_cmd docker; then
    log_info "Descargando e instalando Docker mediante script oficial..."
    curl -fsSL https://get.docker.com | run_sudo sh
    log_ok "Docker Engine instalado."
  else
    log_ok "Docker ya está instalado: $(docker --version)"
  fi

  # Configurar permisos de usuario para ejecutar docker sin sudo
  if ! groups "$USER" | grep -q "\bdocker\b"; then
    log_info "Añadiendo usuario '$USER' al grupo docker..."
    run_sudo usermod -aG docker "$USER"
    log_ok "Usuario añadido al grupo docker. (Requiere reiniciar sesión para aplicar)."
  fi

  # Habilitar servicio systemd
  if has_cmd systemctl; then
    run_sudo systemctl enable --now docker || true
  fi

  # Comprobar plugin docker-compose
  if docker compose version >/dev/null 2>&1; then
    log_ok "Docker Compose está listo: $(docker compose version)"
  elif has_cmd docker-compose; then
    log_ok "docker-compose standalone está disponible: $(docker-compose --version)"
  else
    log_info "Instalando docker-compose-plugin vía gestor de paquetes..."
    pkg_install docker-compose-plugin || true
  fi

  # Lazydocker (TUI opcional)
  if ! has_cmd lazydocker; then
    log_info "Instalando Lazydocker..."
    curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash || true
    log_ok "Lazydocker instalado en ~/.local/bin/lazydocker"
  fi
}

# ------------------------------------------------------------------------------
# 3. OpenCode CLI
# ------------------------------------------------------------------------------
install_opencode() {
  log_info "Configurando OpenCode CLI..."
  if ! has_cmd opencode; then
    log_info "Instalando OpenCode desde el repositorio oficial..."
    curl -fsSL https://raw.githubusercontent.com/opencode-ai/opencode/refs/heads/main/install | bash || true
    log_ok "OpenCode instalado."
  else
    log_ok "OpenCode ya está instalado: $(opencode --version 2>/dev/null || echo 'instalado')"
  fi
}

# ------------------------------------------------------------------------------
# 4. Freebuff CLI
# ------------------------------------------------------------------------------
install_freebuff() {
  log_info "Configurando Freebuff CLI..."
  if ! has_cmd freebuff; then
    if has_cmd npm; then
      log_info "Instalando freebuff vía npm global..."
      npm install -g freebuff || true
      log_ok "Freebuff instalado."
    else
      log_warn "Se requiere Node/npm para instalar Freebuff. Instala Node primero."
    fi
  else
    log_ok "Freebuff ya está instalado: $(freebuff --version 2>/dev/null || echo 'instalado')"
  fi
}

# ------------------------------------------------------------------------------
# 5. Antigravity CLI (agy)
# ------------------------------------------------------------------------------
install_agy() {
  log_info "Verificando Antigravity CLI (agy)..."
  if ! has_cmd agy; then
    log_info "Para instalar agy, consulta la documentación oficial o ejecuta el instalador de Antigravity."
  else
    log_ok "Antigravity CLI (agy) ya está instalado: $(agy --version 2>/dev/null || echo 'instalado')"
  fi
}

# ------------------------------------------------------------------------------
# 6. Codex CLI
# ------------------------------------------------------------------------------
install_codex() {
  log_info "Verificando Codex CLI..."
  if ! has_cmd codex; then
    log_info "Para instalar Codex CLI, descarga el binario en ~/.local/bin/codex."
  else
    log_ok "Codex CLI ya está disponible: $(codex --version 2>/dev/null || echo 'instalado')"
  fi
}

# ------------------------------------------------------------------------------
# Menú de ejecución
# ------------------------------------------------------------------------------
TARGET="${1:-}"

case "$TARGET" in
  all)
    install_node
    install_docker
    install_opencode
    install_freebuff
    install_agy
    install_codex
    ;;
  node) install_node ;;
  docker) install_docker ;;
  opencode) install_opencode ;;
  freebuff) install_freebuff ;;
  agy) install_agy ;;
  codex) install_codex ;;
  "")
    echo "Selecciona qué herramientas deseas instalar:"
    echo "  1) Todo el stack (Node, Docker, OpenCode, Freebuff, AGY, Codex)"
    echo "  2) Node.js LTS"
    echo "  3) Docker + Docker Compose + Lazydocker"
    echo "  4) OpenCode CLI"
    echo "  5) Freebuff CLI"
    echo "  6) Salir"
    echo ""
    read -r -p "Opción [1-6]: " OPT
    case "$OPT" in
      1)
        install_node
        install_docker
        install_opencode
        install_freebuff
        install_agy
        install_codex
        ;;
      2) install_node ;;
      3) install_docker ;;
      4) install_opencode ;;
      5) install_freebuff ;;
      6) exit 0 ;;
      *) log_err "Opción no válida."; exit 1 ;;
    esac
    ;;
  *)
    log_err "Opción no reconocida: $TARGET. Usa: node | docker | opencode | freebuff | all"
    exit 1
    ;;
esac

log_ok "Configuración de herramientas de desarrollo completada."

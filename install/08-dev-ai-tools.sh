#!/usr/bin/env bash
# ==============================================================================
# install/08-dev-ai-tools.sh — Node.js, pnpm, Docker y Agentes de IA
# ==============================================================================
# Soporta ejecución individual o por lista:
#   ./install/08-dev-ai-tools.sh node pnpm docker opencode freebuff codex agy
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/00-helpers.sh"

log_step "Instalando Herramientas de Desarrollo & Agentes AI Seleccionados"

mkdir -p "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$HOME/.opencode/bin:$PATH"

# Cargar NVM si ya existe en el sistema
export NVM_DIR="$HOME/.nvm"
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
  set +u
  # shellcheck disable=SC1091
  \. "$NVM_DIR/nvm.sh"
  set -u
fi

# ------------------------------------------------------------------------------
# 1. Node.js LTS
# ------------------------------------------------------------------------------
install_node() {
  log_info "Configurando Node.js LTS..."
  export NVM_DIR="$HOME/.nvm"
  if [[ ! -d "$NVM_DIR" ]]; then
    log_info "Instalando NVM (Node Version Manager)..."
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
  fi

  # Cargar NVM protegiendo temporalmente contra variables no definidas en nvm.sh
  set +u
  # shellcheck disable=SC1091
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  if ! has_cmd node; then
    log_info "Descargando última versión LTS de Node..."
    nvm install --lts
    nvm use --lts
    nvm alias default 'lts/*'
  fi
  set -u
  log_ok "Node.js $(node --version 2>/dev/null || echo '') instalado."
}

# ------------------------------------------------------------------------------
# 2. pnpm (Fast Node package manager)
# ------------------------------------------------------------------------------
install_pnpm() {
  log_info "Configurando pnpm..."
  set +u
  [[ -s "$NVM_DIR/nvm.sh" ]] && \. "$NVM_DIR/nvm.sh"
  set -u
  if ! has_cmd pnpm; then
    if has_cmd npm; then
      log_info "Instalando pnpm vía npm..."
      npm install -g pnpm || true
    else
      log_info "Instalando pnpm vía script oficial..."
      curl -fsSL https://get.pnpm.io/install.sh | sh - || true
    fi
    log_ok "pnpm instalado."
  else
    log_ok "pnpm ya está disponible: $(pnpm --version)"
  fi
}

# ------------------------------------------------------------------------------
# 3. Docker & Docker Compose
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

  # Permisos de usuario para docker sin sudo
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

  # Lazydocker
  if ! has_cmd lazydocker; then
    log_info "Instalando Lazydocker..."
    curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash || true
    log_ok "Lazydocker instalado en ~/.local/bin/lazydocker"
  fi
}

# ------------------------------------------------------------------------------
# 4. OpenCode CLI
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
# 5. Freebuff CLI
# ------------------------------------------------------------------------------
install_freebuff() {
  log_info "Configurando Freebuff CLI..."
  set +u
  [[ -s "$NVM_DIR/nvm.sh" ]] && \. "$NVM_DIR/nvm.sh"
  set -u
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
# 6. Codex CLI
# ------------------------------------------------------------------------------
install_codex() {
  log_info "Verificando Codex CLI..."
  if ! has_cmd codex; then
    log_info "Codex CLI: asegúrate de colocar el binario ejecutable en ~/.local/bin/codex."
  else
    log_ok "Codex CLI ya está disponible: $(codex --version 2>/dev/null || echo 'instalado')"
  fi
}

# ------------------------------------------------------------------------------
# 7. Antigravity CLI (agy)
# ------------------------------------------------------------------------------
install_agy() {
  log_info "Verificando Antigravity CLI (agy)..."
  if ! has_cmd agy; then
    log_info "Antigravity CLI: consulta la documentación oficial para autenticarte o instalar."
  else
    log_ok "Antigravity CLI (agy) ya está instalado: $(agy --version 2>/dev/null || echo 'instalado')"
  fi
}

# ------------------------------------------------------------------------------
# Despachador de instalación
# ------------------------------------------------------------------------------
if [[ $# -eq 0 ]]; then
  echo "Uso: $0 [node|pnpm|docker|opencode|freebuff|codex|agy|all] ..."
  exit 0
fi

for tool in "$@"; do
  case "$tool" in
    all)
      install_node
      install_pnpm
      install_docker
      install_opencode
      install_freebuff
      install_codex
      install_agy
      ;;
    node) install_node ;;
    pnpm) install_pnpm ;;
    docker) install_docker ;;
    opencode) install_opencode ;;
    freebuff) install_freebuff ;;
    codex) install_codex ;;
    agy) install_agy ;;
    *)
      log_warn "Herramienta desconocida: $tool"
      ;;
  esac
done

log_ok "Instalación de herramientas seleccionadas completada."

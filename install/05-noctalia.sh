#!/usr/bin/env bash
# ==============================================================================
# install/05-noctalia.sh — Repositorio y componentes de Noctalia v5 (Shell Wayland)
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/00-helpers.sh"

log_step "Instalando Noctalia v5 (Shell, Barra, Launcher, Notificaciones)"

OS="$(detect_os)"

if [[ "$OS" =~ ^(debian|ubuntu)$ ]]; then
  if ! has_cmd noctalia; then
    log_info "Configurando repositorio oficial de Noctalia para Debian/Ubuntu..."
    KEYRING_DEB="/tmp/nickh-archive-keyring.deb"
    curl -fsSL -o "$KEYRING_DEB" https://pkg.noctalia.dev/deb/nickh-archive-keyring.deb
    run_sudo dpkg -i "$KEYRING_DEB"
    rm -f "$KEYRING_DEB"

    run_sudo wget -O /etc/apt/sources.list.d/noctalia-trixie.sources https://pkg.noctalia.dev/deb/noctalia-trixie.sources || true
    run_sudo apt update -y
    pkg_install noctalia || log_warn "No se pudo instalar Noctalia vía APT. Verifica https://docs.noctalia.dev"
    log_ok "Noctalia v5 instalado."
  else
    log_ok "Noctalia ya está instalado: $(noctalia --version 2>/dev/null || echo 'v5')"
  fi

  # Opcional: Noctalia Greeter y Greetd
  read -r -p "¿Deseas instalar Noctalia Greeter (display manager greetd)? [s/N]: " RESP || RESP="n"
  if [[ "$RESP" =~ ^[sS]$ ]]; then
    log_info "Instalando greetd y noctalia-greeter..."
    pkg_install greetd noctalia-greeter || true
    if [[ -f "$SCRIPT_DIR/../noctalia-greeter/greeter.toml" ]]; then
      run_sudo mkdir -p /var/lib/noctalia-greeter
      run_sudo cp "$SCRIPT_DIR/../noctalia-greeter/greeter.toml" /var/lib/noctalia-greeter/greeter.toml
    fi
    log_ok "Noctalia Greeter configurado. (Habilitar con: sudo systemctl enable --now greetd)"
  fi
else
  log_warn "Noctalia en $OS: consulta la documentación oficial en https://docs.noctalia.dev para compilar o instalar vía cargo."
fi

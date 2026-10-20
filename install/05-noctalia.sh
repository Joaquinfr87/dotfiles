#!/usr/bin/env bash
# ==============================================================================
# install/05-noctalia.sh — Repositorio y componentes de Noctalia v5 & Greeter
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/00-helpers.sh"

log_step "Instalando Noctalia v5 y Noctalia Greeter (Login Manager)"

OS="$(detect_os)"

if [[ "$OS" =~ ^(debian|ubuntu)$ ]]; then
  # 1. Repositorio oficial de Noctalia
  if ! has_cmd noctalia; then
    log_info "Configurando repositorio oficial de Noctalia para Debian/Ubuntu..."
    KEYRING_DEB="/tmp/nickh-archive-keyring.deb"
    curl -fsSL -o "$KEYRING_DEB" https://pkg.noctalia.dev/deb/nickh-archive-keyring.deb
    run_sudo dpkg -i "$KEYRING_DEB"
    rm -f "$KEYRING_DEB"

    curl -fsSL https://pkg.noctalia.dev/deb/noctalia-trixie.sources | run_sudo tee /etc/apt/sources.list.d/noctalia-trixie.sources >/dev/null || true

    # Configurar APT Pinning para que trixie-backports de Noctalia tenga prioridad normal (500)
    # y resuelva dependencias como libwlroots y libdrm2 sin conflictos
    run_sudo mkdir -p /etc/apt/preferences.d
    run_sudo bash -c 'cat << "EOF" > /etc/apt/preferences.d/noctalia.pref
Package: *
Pin: origin "pkg.noctalia.dev"
Pin-Priority: 500
EOF'

    run_sudo apt update -y
    pkg_install noctalia || log_warn "No se pudo instalar Noctalia vía APT. Verifica https://docs.noctalia.dev"
    log_ok "Noctalia v5 instalado."
  else
    # Asegurar que el archivo de preferencias de Noctalia exista si el repo ya fue configurado
    if [[ ! -f /etc/apt/preferences.d/noctalia.pref && -f /etc/apt/sources.list.d/noctalia-trixie.sources ]]; then
      run_sudo mkdir -p /etc/apt/preferences.d
      run_sudo bash -c 'cat << "EOF" > /etc/apt/preferences.d/noctalia.pref
Package: *
Pin: origin "pkg.noctalia.dev"
Pin-Priority: 500
EOF'
    fi
    log_ok "Noctalia ya está instalado: $(noctalia --version 2>/dev/null || echo 'v5')"
  fi

  # 2. Instalación y configuración obligatoria de Noctalia Greeter con greetd
  log_info "Instalando greetd..."
  pkg_install greetd || true

  log_info "Instalando noctalia-greeter..."
  run_sudo apt install -y -t trixie-backports noctalia-greeter 2>/dev/null || pkg_install noctalia-greeter || true

  # Configurar /etc/greetd/config.toml
  log_info "Configurando /etc/greetd/config.toml para noctalia-greeter..."
  run_sudo mkdir -p /etc/greetd
  run_sudo bash -c 'cat << "EOF" > /etc/greetd/config.toml
[terminal]
vt = 7

[default_session]
command = "/usr/bin/noctalia-greeter-session"
user = "_greetd"
EOF'

  # Configurar /var/lib/noctalia-greeter/greeter.toml y wallpaper
  log_info "Configurando temas y fondos para Noctalia Greeter..."
  run_sudo mkdir -p /var/lib/noctalia-greeter
  if [[ -f "$DOTFILES_DIR/noctalia-greeter/greeter.toml" ]]; then
    sed "s/default = .*/default = \"$USER\"/" "$DOTFILES_DIR/noctalia-greeter/greeter.toml" | run_sudo tee /var/lib/noctalia-greeter/greeter.toml >/dev/null
  fi

  # Copiar wallpaper para el greeter
  if [[ -f "$DOTFILES_DIR/Pictures/wallpaper4.png" ]]; then
    run_sudo cp "$DOTFILES_DIR/Pictures/wallpaper4.png" /var/lib/noctalia-greeter/wallpaper.png
  fi

  # Ajustar permisos para el usuario del display manager
  if id "_greetd" >/dev/null 2>&1; then
    run_sudo chown -R _greetd:_greetd /var/lib/noctalia-greeter 2>/dev/null || true
  fi
  run_sudo chmod -R 755 /var/lib/noctalia-greeter 2>/dev/null || true

  # Habilitar servicio greetd si la unidad está instalada
  if has_cmd systemctl; then
    if systemctl list-unit-files 2>/dev/null | grep -q "^greetd\.service"; then
      log_info "Habilitando servicio greetd en systemd..."
      run_sudo systemctl enable greetd || true
      log_ok "Noctalia Greeter configurado y habilitado en systemd."
    else
      log_warn "greetd.service no se encuentra registrado en systemd."
    fi
  fi
else
  log_warn "Noctalia en $OS: consulta la documentación oficial en https://docs.noctalia.dev para compilar o instalar vía cargo."
fi

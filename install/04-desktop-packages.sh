#!/usr/bin/env bash
# ==============================================================================
# install/04-desktop-packages.sh — Sway, Wayland, PipeWire y utilidades gráficas
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/00-helpers.sh"

log_step "Instalando Sway, Wayland, Audio PipeWire y Portales de Escritorio"

OS="$(detect_os)"

case "$OS" in
  debian|ubuntu|pop|linuxmint)
    log_info "Instalando paquetes gráficos en Debian/Ubuntu..."
    pkg_update
    pkg_install \
      sway \
      xwayland \
      kanshi \
      wl-clipboard \
      pavucontrol \
      gnome-keyring \
      pipewire \
      wireplumber \
      pipewire-pulse \
      xdg-desktop-portal \
      xdg-desktop-portal-wlr \
      xdg-desktop-portal-gtk \
      fonts-noto-color-emoji \
      bluez \
      xz-utils
    ;;
  arch|cachyos|manjaro)
    log_info "Instalando paquetes gráficos en Arch Linux..."
    pkg_update
    pkg_install \
      sway \
      xorg-xwayland \
      kanshi \
      wl-clipboard \
      pavucontrol \
      gnome-keyring \
      pipewire \
      wireplumber \
      pipewire-pulse \
      xdg-desktop-portal \
      xdg-desktop-portal-wlr \
      xdg-desktop-portal-gtk \
      noto-fonts-emoji
    ;;
  fedora)
    log_info "Instalando paquetes gráficos en Fedora..."
    pkg_install \
      sway \
      xorg-x11-server-Xwayland \
      kanshi \
      wl-clipboard \
      pavucontrol \
      gnome-keyring \
      pipewire \
      wireplumber \
      pipewire-pulseaudio \
      xdg-desktop-portal \
      xdg-desktop-portal-wlr \
      xdg-desktop-portal-gtk \
      google-noto-color-emoji-fonts
    ;;
  *)
    log_warn "Distribución $OS: asegúrate de instalar sway, kanshi, wl-clipboard y pipewire manualmente."
    ;;
esac

# Activar servicios de audio PipeWire para la sesión de usuario
if has_cmd systemctl; then
  log_info "Habilitando servicios de audio PipeWire para el usuario..."
  systemctl --user enable --now pipewire wireplumber pipewire-pulse || true
  log_ok "Servicios PipeWire activos."
fi

# Instalar Kitty si no está presente
if ! has_cmd kitty; then
  log_info "Instalando Kitty terminal..."
  curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin || true
  mkdir -p "$HOME/.local/bin" "$HOME/.local/share"
  ln -sf "$HOME/.local/kitty.app/bin/kitty" "$HOME/.local/bin/kitty"
  ln -sf "$HOME/.local/kitty.app/bin/kitten" "$HOME/.local/bin/kitten"
  run_sudo ln -sf "$HOME/.local/kitty.app/bin/kitty" /usr/local/bin/kitty 2>/dev/null || true
  run_sudo ln -sf "$HOME/.local/kitty.app/bin/kitten" /usr/local/bin/kitten 2>/dev/null || true
  if [[ -d "$HOME/.local/kitty.app/share" ]]; then
    cp -as "$HOME/.local/kitty.app/share/"* "$HOME/.local/share/" 2>/dev/null || true
  fi
  log_ok "Kitty instalado en ~/.local/bin/kitty"
else
  log_ok "Kitty ya está instalado."
fi

# Instalar bluetuith (gestor Bluetooth TUI)
if ! has_cmd bluetuith; then
  log_info "Instalando bluetuith (Bluetooth TUI)..."
  mkdir -p "$HOME/.local/bin"
  BLUETUITH_URL=$(curl -s https://api.github.com/repos/bluetuith-org/bluetuith/releases/latest | grep -o "https://[^\"]*Linux_x86_64\.tar\.gz" | head -n 1 || echo "")
  if [[ -n "$BLUETUITH_URL" ]]; then
    curl -fsSL -o /tmp/bluetuith.tar.gz "$BLUETUITH_URL"
    tar -xzf /tmp/bluetuith.tar.gz -C "$HOME/.local/bin" bluetuith 2>/dev/null || tar -xzf /tmp/bluetuith.tar.gz -C "$HOME/.local/bin"
    rm -f /tmp/bluetuith.tar.gz
    chmod +x "$HOME/.local/bin/bluetuith" 2>/dev/null || true
    run_sudo ln -sf "$HOME/.local/bin/bluetuith" /usr/local/bin/bluetuith 2>/dev/null || true
    log_ok "bluetuith instalado en ~/.local/bin/bluetuith"
  fi
else
  log_ok "bluetuith ya está instalado."
fi

log_ok "Entorno base de Sway y Wayland completado."

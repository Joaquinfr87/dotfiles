#!/usr/bin/env bash
# ==============================================================================
# install/06-fonts-wallpapers.sh — Fuentes tipográficas y Zen Browser
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/00-helpers.sh"

log_step "Instalando fuentes tipográficas (Iosevka Nerd Font) y Zen Browser"

# 1. Iosevka Nerd Font
FONT_DIR="$HOME/.local/share/fonts/Iosevka"
if [[ ! -d "$FONT_DIR" ]] || [[ -z "$(ls -A "$FONT_DIR" 2>/dev/null)" ]]; then
  log_info "Descargando Iosevka Nerd Font..."
  mkdir -p "$FONT_DIR"
  ZIP_PATH="/tmp/Iosevka.zip"
  curl -fsSL -o "$ZIP_PATH" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Iosevka.zip"
  unzip -qo "$ZIP_PATH" -d "$FONT_DIR"
  rm -f "$ZIP_PATH"
  fc-cache -fv "$FONT_DIR" >/dev/null 2>&1 || true
  log_ok "Iosevka Nerd Font instalada."
else
  log_ok "Iosevka Nerd Font ya está instalada."
fi

# 2. Zen Browser (Navegador por defecto)
if ! has_cmd zen; then
  log_info "Descargando e instalando Zen Browser (siguiendo guía de notas)..."
  ZEN_TAR="/tmp/zen.linux-x86_64.tar.xz"
  curl -fsSL -o "$ZEN_TAR" "https://github.com/zen-browser/desktop/releases/latest/download/zen.linux-x86_64.tar.xz"
  mkdir -p "$HOME/.local/share/zen" "$HOME/.local/bin" \
           "$HOME/.local/share/icons/hicolor/128x128/apps" \
           "$HOME/.local/share/applications"
  tar -xf "$ZEN_TAR" -C "/tmp"
  cp -r /tmp/zen/* "$HOME/.local/share/zen/" 2>/dev/null || mv /tmp/zen/* "$HOME/.local/share/zen/"
  rm -rf /tmp/zen "$ZEN_TAR"

  ln -sf "$HOME/.local/share/zen/zen" "$HOME/.local/bin/zen"

  # Enlace del icono de 128px al directorio de iconos del sistema
  if [[ -f "$HOME/.local/share/zen/browser/chrome/icons/default/default128.png" ]]; then
    ln -sf "$HOME/.local/share/zen/browser/chrome/icons/default/default128.png" "$HOME/.local/share/icons/hicolor/128x128/apps/zen.png"
    gtk-update-icon-cache "$HOME/.local/share/icons/hicolor" >/dev/null 2>&1 || true
  fi

  # Acceso directo .desktop
  cat << 'EOF' > "$HOME/.local/share/applications/zen.desktop"
[Desktop Entry]
Name=Zen Browser
Comment=Navegador web rápido y privado
Exec=zen %u
Icon=zen
Type=Application
Categories=Network;WebBrowser;
Terminal=false
StartupNotify=true
MimeType=text/html;text/xml;application/xhtml+xml;application/xml;application/vnd.mozilla.xul+xml;application/rss+xml;application/rdf+xml;image/gif;image/jpeg;image/png;x-scheme-handler/http;x-scheme-handler/https;
EOF

  log_ok "Zen Browser e icono instalados en ~/.local/bin/zen"
else
  log_ok "Zen Browser ya está instalado."
fi

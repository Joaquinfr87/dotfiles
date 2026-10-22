#!/usr/bin/env bash
# ==============================================================================
# install/06-fonts-wallpapers.sh — Iosevka fonts (terminal + GUI) and Zen Browser
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/00-helpers.sh"

log_step "Installing Iosevka fonts (terminal and GUI) and Zen Browser"

require_debian_13

# Make sure the decompression tools are available
if ! has_cmd unzip || ! has_cmd xz; then
  pkg_install unzip xz-utils || true
fi

FONT_ROOT="$HOME/.local/share/fonts"
mkdir -p "$FONT_ROOT"

# ------------------------------------------------------------------------------
# 1a. IosevkaTerm Nerd Font → terminal (Kitty)
# ------------------------------------------------------------------------------
# The "Term" variant is used by the terminal: Nerd Font glyphs with monospaced
# advance widths. Resulting family: "IosevkaTerm Nerd Font Mono".
TERM_FONT_DIR="$FONT_ROOT/IosevkaTerm"
if [[ ! -d "$TERM_FONT_DIR" ]] || [[ -z "$(ls -A "$TERM_FONT_DIR" 2>/dev/null)" ]]; then
  log_info "Downloading IosevkaTerm Nerd Font (terminal)..."
  mkdir -p "$TERM_FONT_DIR"
  ZIP_PATH="/tmp/IosevkaTerm.zip"
  curl -fsSL -o "$ZIP_PATH" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/IosevkaTerm.zip"
  unzip -qo "$ZIP_PATH" -d "$TERM_FONT_DIR"
  rm -f "$ZIP_PATH"
  log_ok "IosevkaTerm Nerd Font installed."
else
  log_ok "IosevkaTerm Nerd Font is already installed."
fi

# ------------------------------------------------------------------------------
# 1b. Vanilla Iosevka (unpatched) → GUI (Noctalia, greeter, GTK/Qt)
# ------------------------------------------------------------------------------
# Official be5invis release in TTC format. Resulting family: "Iosevka".
GUI_FONT_DIR="$FONT_ROOT/Iosevka-GUI"
if [[ ! -d "$GUI_FONT_DIR" ]] || [[ -z "$(ls -A "$GUI_FONT_DIR" 2>/dev/null)" ]]; then
  log_info "Downloading vanilla Iosevka (GUI) from the official release..."
  mkdir -p "$GUI_FONT_DIR"
  IOSEVKA_URL="$(curl -fsSL https://api.github.com/repos/be5invis/Iosevka/releases/latest \
    | grep -o 'https://[^"]*PkgTTC-Iosevka-[0-9][^"]*\.zip' | head -n 1 || true)"
  if [[ -n "$IOSEVKA_URL" ]]; then
    ZIP_PATH="/tmp/Iosevka-GUI.zip"
    curl -fsSL -o "$ZIP_PATH" "$IOSEVKA_URL"
    unzip -qo "$ZIP_PATH" -d "$GUI_FONT_DIR"
    rm -f "$ZIP_PATH"
    log_ok "Vanilla Iosevka (GUI) installed."
  else
    log_warn "Could not resolve the Iosevka release asset from GitHub; skipping the GUI font."
  fi
else
  log_ok "Vanilla Iosevka (GUI) is already installed."
fi

# Refresh the user font cache once
fc-cache -f "$FONT_ROOT" >/dev/null 2>&1 || true

# System-wide availability: the greeter runs as _greetd and cannot see
# ~/.local/share/fonts, so it would ignore Iosevka at the login screen.
if [[ -d "$TERM_FONT_DIR" ]]; then
  run_sudo mkdir -p /usr/local/share/fonts/IosevkaTerm
  run_sudo cp -f "$TERM_FONT_DIR"/*.ttf /usr/local/share/fonts/IosevkaTerm/ 2>/dev/null || true
fi
if [[ -d "$GUI_FONT_DIR" ]]; then
  run_sudo mkdir -p /usr/local/share/fonts/Iosevka
  run_sudo cp -f "$GUI_FONT_DIR"/*.ttc /usr/local/share/fonts/Iosevka/ 2>/dev/null || true
fi
run_sudo fc-cache -f /usr/local/share/fonts >/dev/null 2>&1 || true

# Verify that the family names used by Kitty and Noctalia really exist.
# Nerd Fonts v3 publishes "IosevkaTerm Nerd Font" / "... Mono" / "... Propo";
# if the name does not match, Kitty silently falls back to monospace.
if has_cmd fc-list; then
  check_font_family() {
    fc-list : family 2>/dev/null | tr ',' '\n' | sed 's/^ *//; s/ *$//' | grep -qx "$1"
  }

  if check_font_family "IosevkaTerm Nerd Font Mono"; then
    log_ok "Family 'IosevkaTerm Nerd Font Mono' is available for Kitty."
  else
    log_warn "Family 'IosevkaTerm Nerd Font Mono' not found. Kitty may fall back to monospace."
  fi

  if check_font_family "Iosevka"; then
    log_ok "Family 'Iosevka' is available for Noctalia/GUI."
  else
    log_warn "Family 'Iosevka' not found for GUI/Noctalia."
  fi

  log_info "Detected Iosevka families: $(fc-list : family 2>/dev/null | tr ',' '\n' | grep -i iosevka | sort -u | paste -sd ', ' -)"
fi

# ------------------------------------------------------------------------------
# 2. Zen Browser (default browser)
# ------------------------------------------------------------------------------
if ! has_cmd zen && [[ ! -x "$HOME/.local/bin/zen" ]]; then
  log_info "Downloading and installing Zen Browser..."
  ZEN_TAR="/tmp/zen.linux-x86_64.tar.xz"
  curl -fsSL -o "$ZEN_TAR" "https://github.com/zen-browser/desktop/releases/latest/download/zen.linux-x86_64.tar.xz"
  mkdir -p "$HOME/.local/share/zen" "$HOME/.local/bin" \
           "$HOME/.local/share/icons/hicolor/128x128/apps" \
           "$HOME/.local/share/applications"
  tar -xf "$ZEN_TAR" -C "$HOME/.local/share/zen" --strip-components=1
  rm -f "$ZEN_TAR"

  ln -sf "$HOME/.local/share/zen/zen" "$HOME/.local/bin/zen"
  run_sudo ln -sf "$HOME/.local/share/zen/zen" /usr/local/bin/zen 2>/dev/null || true

  # Link the 128px icon into the system icon theme directory
  if [[ -f "$HOME/.local/share/zen/browser/chrome/icons/default/default128.png" ]]; then
    ln -sf "$HOME/.local/share/zen/browser/chrome/icons/default/default128.png" "$HOME/.local/share/icons/hicolor/128x128/apps/zen.png"
    gtk-update-icon-cache "$HOME/.local/share/icons/hicolor" >/dev/null 2>&1 || true
  fi

  # .desktop entry
  cat << 'EOF' > "$HOME/.local/share/applications/zen.desktop"
[Desktop Entry]
Name=Zen Browser
Comment=Fast and private web browser
Exec=zen %u
Icon=zen
Type=Application
Categories=Network;WebBrowser;
Terminal=false
StartupNotify=true
MimeType=text/html;text/xml;application/xhtml+xml;application/xml;application/vnd.mozilla.xul+xml;application/rss+xml;application/rdf+xml;image/gif;image/jpeg;image/png;x-scheme-handler/http;x-scheme-handler/https;
EOF

  log_ok "Zen Browser and its icon installed in ~/.local/bin/zen"
else
  log_ok "Zen Browser is already installed."
fi

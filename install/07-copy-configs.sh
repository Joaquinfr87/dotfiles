#!/usr/bin/env bash
# ==============================================================================
# install/07-copy-configs.sh — Copia de configuraciones al sistema con backup
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/00-helpers.sh"

PROFILE="${1:-${DOTFILES_PROFILE:-desktop}}"

log_step "Desplegando archivos de configuración para perfil: $PROFILE"

# Ejecutar el sincronizador propio de dotfiles
"$DOTFILES_DIR/bin/dot-sync" deploy "$PROFILE"

log_ok "Todas las configuraciones se han copiado correctamente con backup previo."

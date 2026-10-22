#!/usr/bin/env bash
# ==============================================================================
# install/07-copy-configs.sh — Deploy dotfiles with automatic backups
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/00-helpers.sh"

PROFILE="${1:-${DOTFILES_PROFILE:-desktop}}"

log_step "Deploying configuration files for profile: $PROFILE"

# Use the repository's own dotfiles synchronizer
"$DOTFILES_DIR/bin/dot-sync" deploy "$PROFILE"

log_ok "All configuration files copied successfully (previous versions were backed up)."

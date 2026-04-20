#!/bin/bash
set -euo pipefail

# ==============================================================================
# 🛠️  CONFIGURACIÓN DEL USUARIO (Modifica esto según necesites)
# ==============================================================================
GIT_NAME="Joaquin"
GIT_EMAIL="joaquinfelipezrojas@gmail.com"
GITHUB_USER="Joaquinfr87"
REPO_URL="git@github.com:${GITHUB_USER}/dotfiles.git"
WALLPAPER_NAME="mi-fondo.png"

# Obtener el usuario real (por si se ejecuta con sudo)
REAL_USER=${SUDO_USER:-$USER}
HOME_DIR=$(eval echo ~$REAL_USER)

# ==============================================================================
# 📦 FUNCIONES DE INSTALACIÓN
# ==============================================================================

ask_sudo_permissions() {
    echo "🛡️  Verificando permisos de administrador..."
    sudo -v
    # Mantener sudo vivo en segundo plano
    while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
}

install_base_packages() {
    echo -e "\n📦 Actualizando repositorios e instalando paquetes base de Debian..."
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y git curl tree xclip htop fastfetch stow xdg-user-dirs gh
}

setup_git_and_github() {
    echo -e "\n⚙️ Configurando Git global..."
    git config --global user.name "$GIT_NAME"
    git config --global user.email "$GIT_EMAIL"

    echo -e "\n🔑 Autenticación con GitHub..."
    if ! gh auth status &>/dev/null; then
        echo "No estás autenticado en GitHub. Iniciando proceso con GitHub CLI..."
        echo "Pro-Tip: Selecciona 'SSH' y deja que GitHub CLI genere y suba la llave por ti."
        gh auth login
    else
        echo "✅ Ya estás autenticado en GitHub."
    fi
}

setup_dotfiles_stow() {
    echo -e "\n📂 Configurando repositorio de Dotfiles..."
    mkdir -p "$HOME_DIR/repos"
    
    if [ ! -d "$HOME_DIR/repos/dotfiles" ]; then
        echo "Clonando repositorio de dotfiles..."
        git clone "$REPO_URL" "$HOME_DIR/repos/dotfiles"
    else
        echo "✅ El repositorio ya está clonado."
    fi

    echo -e "\n🔗 Aplicando enlaces simbólicos con GNU Stow..."
    # Limpiamos basura de XFCE antes de hacer stow
    rm -rf "$HOME_DIR/.config/xfce4"
    rm -f "$HOME_DIR/repos/dotfiles/xfce/.config/xfce4/desktop/icons.screen.latest.rc"

    xdg-user-dirs-update
    mkdir -p "$HOME_DIR/Pictures"

    cd "$HOME_DIR/repos/dotfiles"
    stow -t "$HOME_DIR" xfce
    stow -t "$HOME_DIR/Pictures" Pictures
    cd "$HOME_DIR"
}

setup_gui_xfce() {
    echo -e "\n🖼️  Aplicando fondo de pantalla y reiniciando entorno gráfico..."
    local WALLPAPER_PATH="$HOME_DIR/Pictures/$WALLPAPER_NAME" 
    
    if [ -f "$WALLPAPER_PATH" ] && command -v xfconf-query &> /dev/null; then
        # Silenciamos errores si no hay propiedades de escritorio activas aún
        local PROPIEDADES=$(xfconf-query -c xfce4-desktop -l | grep -E "last-image$" || true)
        
        if [ -n "$PROPIEDADES" ]; then
            for prop in $PROPIEDADES; do
                xfconf-query -c xfce4-desktop -p "$prop" -s "$WALLPAPER_PATH"
            done
            xfdesktop --reload &>/dev/null || true
            echo "✅ Fondo de pantalla actualizado."
        fi
    else
        echo "⚠️ No se pudo aplicar el fondo. Verifique que está en XFCE o que la imagen exista."
    fi

    echo -e "\n♻️  Reiniciando componentes del panel de XFCE..."
    killall xfconfd || true
    xfce4-panel -r &
    xfwm4 --replace &
}

# ==============================================================================
# 🚀 EJECUCIÓN PRINCIPAL
# ==============================================================================
echo "=================================================="
echo "🚀 Iniciando configuración del entorno Debian..."
echo "=================================================="

ask_sudo_permissions
install_base_packages
setup_git_and_github
setup_dotfiles_stow

# Solo ejecuta la configuración gráfica si detecta que hay un entorno de ventanas activo
if [ -n "${DISPLAY:-}" ]; then
    setup_gui_xfce
fi

echo "=================================================="
echo "✅ ¡Entorno base configurado exitosamente!"
echo "⚠️  Es recomendable cerrar sesión y volver a entrar."
echo "=================================================="

#!/bin/bash
# Habilitamos strict mode para que falle si hay algún error
set -euo pipefail

# ==============================================================================
# 🛠️  CONFIGURACIÓN DEL USUARIO
# ==============================================================================
GIT_NAME="Joaquin"
GIT_EMAIL="joaquinfelipezrojas@gmail.com"
GITHUB_USER="Joaquinfr87"
REPO_URL="git@github.com:${GITHUB_USER}/dotfiles.git"
WALLPAPER_NAME="mi-fondo.png"

# Obtener el usuario real, incluso si se ejecuta con sudo
REAL_USER=${SUDO_USER:-$USER}
HOME_DIR=$(eval echo ~$REAL_USER)

# ==============================================================================
# 📦 FUNCIONES DE INSTALACIÓN
# ==============================================================================

ask_sudo_permissions() {
    echo "🛡️  Verificando permisos de administrador..."
    sudo -v
    # Mantener sudo vivo en segundo plano mientras corre el script
    while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
}

install_base_packages() {
    echo -e "\n📦 Actualizando repositorios e instalando paquetes base..."
    sudo apt update
    sudo apt upgrade -y
    # Eliminamos 'gh' porque no está en los repos por defecto y usamos las herramientas nativas
    sudo apt install -y git curl tree xclip htop fastfetch stow xdg-user-dirs
}

setup_git_and_ssh() {
    echo -e "\n⚙️ Configurando Git global..."
    git config --global user.name "$GIT_NAME"
    git config --global user.email "$GIT_EMAIL"

    echo -e "\n🔑 Configurando llaves SSH para GitHub..."
    local SSH_KEY_PATH="$HOME_DIR/.ssh/id_ed25519"

    # 1. Generar la llave solo si no existe
    if [ ! -f "$SSH_KEY_PATH" ]; then
        echo "Generando llave SSH Ed25519 (más moderna y segura que RSA)..."
        # Generamos la llave sin passphrase de forma automática
        ssh-keygen -t ed25519 -C "$GIT_EMAIL" -N "" -f "$SSH_KEY_PATH"
        eval "$(ssh-agent -s)" > /dev/null
        ssh-add "$SSH_KEY_PATH"
    else
        echo "✅ La llave SSH ya existe."
    fi

    # 2. Evitar el prompt "Are you sure you want to continue connecting?"
    echo "Agregando GitHub a known_hosts..."
    mkdir -p "$HOME_DIR/.ssh"
    ssh-keyscan -t ed25519 github.com >> "$HOME_DIR/.ssh/known_hosts" 2>/dev/null

    # 3. Pausar para que el usuario agregue la llave a GitHub
    echo -e "\n=================================================="
    echo "⚠️  ACCIÓN REQUERIDA EN GITHUB"
    echo "=================================================="
    echo "Tu llave SSH pública es:"
    echo ""
    cat "${SSH_KEY_PATH}.pub"
    echo ""
    echo "1. Copia el texto de arriba."
    echo "2. Ve a https://github.com/settings/keys y agrégala."
    echo "3. Presiona ENTER cuando hayas terminado para continuar..."
    read -r
}

setup_dotfiles_stow() {
    echo -e "\n📂 Clonando repositorio de Dotfiles..."
    mkdir -p "$HOME_DIR/repos"
    
    if [ ! -d "$HOME_DIR/repos/dotfiles" ]; then
        # Ya que confirmamos SSH arriba, esto no fallará
        git clone "$REPO_URL" "$HOME_DIR/repos/dotfiles"
    else
        echo "✅ El repositorio ya está clonado."
    fi

    echo -e "\n🔗 Aplicando enlaces simbólicos con GNU Stow..."
    # Limpiamos archivos por defecto de Debian/XFCE
    rm -rf "$HOME_DIR/.config/xfce4"
    # Usamos -f para que no lance error si el archivo rc no existe aún
    rm -f "$HOME_DIR/repos/dotfiles/xfce/.config/xfce4/desktop/icons.screen.latest.rc"

    # Actualizamos directorios de usuario de Linux (Crea Pictures, Documents, etc.)
    xdg-user-dirs-update
    mkdir -p "$HOME_DIR/Pictures"

    # Aplicamos Stow
    cd "$HOME_DIR/repos/dotfiles"
    stow -t "$HOME_DIR" xfce
    stow -t "$HOME_DIR/Pictures" Pictures
    cd "$HOME_DIR"
}

setup_gui_xfce() {
    echo -e "\n🖼️  Reiniciando entorno gráfico XFCE..."
    # Nota: No aplicamos el fondo por línea de comandos porque Stow ya enlaza 
    # la configuración de XFCE que debería contener la ruta a tu fondo.
    
    echo "♻️  Reiniciando componentes del panel..."
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
setup_git_and_ssh
setup_dotfiles_stow

# Solo intentamos reiniciar XFCE si hay una interfaz gráfica corriendo
if [ -n "${DISPLAY:-}" ]; then
    setup_gui_xfce
fi

echo -e "\n=================================================="
echo "✅ ¡Entorno base configurado exitosamente!"
echo "⚠️  Es recomendable reiniciar el sistema para que XFCE cargue limpio."
echo "=================================================="

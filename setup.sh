#!/bin/bash
# Habilitar strict mode para detener la ejecución si hay errores
set -euo pipefail

echo "=================================================="
echo "🚀 Iniciando configuración del entorno Debian..."
echo "=================================================="

# 1. Pedir contraseña sudo al inicio y mantenerla activa
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# 2. Actualizar sistema e instalar dependencias
echo -e "\n📦 Actualizando repositorios e instalando paquetes base..."
sudo apt update && sudo apt upgrade -y
# Añadí 'gh' (GitHub CLI) a la lista como pro-tip para el futuro
sudo apt install -y git curl tree xclip htop fastfetch stow xdg-user-dirs gh

# 3. Configuración global de Git
echo -e "\n⚙️ Configurando variables globales de Git..."
git config --global user.name "Joaquin"
git config --global user.email "joaquinfelipezrojas@gmail.com"

# 4. Configuración de SSH para GitHub
echo -e "\n🔑 Configurando llaves SSH..."
if [ ! -f "$HOME/.ssh/id_rsa" ]; then
    ssh-keygen -t rsa -b 4096 -C "joaquinfelipezrojas@gmail.com" -N "" -f "$HOME/.ssh/id_rsa"
    eval "$(ssh-agent -s)"
    ssh-add "$HOME/.ssh/id_rsa"
else
    echo "La llave SSH ya existe, saltando generación."
fi

# Evitar el prompt interactivo de (yes/no/[fingerprint]) al conectar a GitHub
if ! grep -q "github.com" ~/.ssh/known_hosts 2>/dev/null; then
    mkdir -p ~/.ssh
    ssh-keyscan github.com >> ~/.ssh/known_hosts 2>/dev/null
fi

# Copiar al portapapeles y abrir navegador
xclip -sel clip < "$HOME/.ssh/id_rsa.pub"
echo -e "\n⚠️  ¡ATENCIÓN! Tu llave SSH pública ha sido copiada al portapapeles."

echo -e "\n🌐 Abriendo el navegador para que inicies sesión..."
# xdg-open abre las URLs en el navegador por defecto. 
# Usamos '|| true' para que el script no se detenga si estás corriendo esto en una terminal sin entorno gráfico.
xdg-open "https://accounts.google.com/" 2>/dev/null || true
xdg-open "https://github.com/settings/keys" 2>/dev/null || true

echo "Por favor, inicia sesión en Google y pega tu nueva llave en GitHub."
read -p "Presiona [ENTER] cuando hayas terminado en el navegador para continuar con la instalación..."

# 5. Clonar repositorio de Dotfiles
echo -e "\n📂 Configurando repositorio de Dotfiles..."
mkdir -p "$HOME/repos"
if [ ! -d "$HOME/repos/dotfiles" ]; then
    git clone git@github.com:Joaquinfr87/dotfiles.git "$HOME/repos/dotfiles"
else
    echo "El repositorio ya está clonado."
fi

# 6. Aplicar GNU Stow y limpiar basura previa
echo -e "\n🔗 Aplicando enlaces simbólicos con GNU Stow..."
echo "Limpiando configuración por defecto de Debian XFCE..."
rm -rf "$HOME/.config/xfce4"
rm -f "$HOME/repos/dotfiles/xfce/.config/xfce4/desktop/icons.screen.latest.rc"

xdg-user-dirs-update
mkdir -p "$HOME/Pictures"

cd "$HOME/repos/dotfiles"
stow -t "$HOME" xfce
stow -t "$HOME/Pictures" Pictures

# 7. Automatización del Wallpaper
echo -e "\n🖼️  Aplicando fondo de pantalla dinámicamente..."
WALLPAPER_PATH="$HOME/Pictures/mi-fondo.png" 

if [ -f "$WALLPAPER_PATH" ]; then
    PROPIEDADES=$(xfconf-query -c xfce4-desktop -l | grep -E "last-image$" || true)
    if [ -n "$PROPIEDADES" ]; then
        for prop in $PROPIEDADES; do
            xfconf-query -c xfce4-desktop -p "$prop" -s "$WALLPAPER_PATH"
        done
        xfdesktop --reload
        echo "Fondo de pantalla actualizado."
    else
        echo "No se encontraron propiedades de escritorio activas."
    fi
else
    echo "⚠️  No se encontró la imagen en $WALLPAPER_PATH. Verifica el nombre."
fi

# 8. Reiniciar el entorno gráfico
echo -e "\n♻️  Reiniciando componentes del panel..."
killall xfconfd || true
xfce4-panel -r &
xfwm4 --replace &

echo "=================================================="
echo "✅ ¡Entorno base configurado exitosamente!"
echo "⚠️  Es recomendable cerrar sesión y volver a entrar."
echo "=================================================="

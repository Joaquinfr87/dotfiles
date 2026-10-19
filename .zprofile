# ~/.zprofile: ejecutado por intérpretes de comandos para login shells.

# Añadir binarios de usuario al PATH si existen
if [ -d "$HOME/bin" ]; then
    PATH="$HOME/bin:$PATH"
fi

if [ -d "$HOME/.local/bin" ]; then
    PATH="$HOME/.local/bin:$PATH"
fi

if [ -d "$HOME/repos/dotfiles/bin" ]; then
    PATH="$HOME/repos/dotfiles/bin:$PATH"
fi

export PATH

# Si estamos en tty1 y Sway está instalado, iniciar la sesión gráfica (Wayland)
if [ "$(tty)" = "/dev/tty1" ] && command -v sway >/dev/null 2>&1; then
    exec sway
fi

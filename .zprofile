# ~/.zprofile: executed by shells for login shells.

# Add user binaries to PATH when they exist
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

# If we are on tty1 and Sway is installed, start the graphical session (Wayland)
if [ "$(tty)" = "/dev/tty1" ] && command -v sway >/dev/null 2>&1; then
    exec sway
fi

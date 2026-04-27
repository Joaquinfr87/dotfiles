# Guía de Instalación de Dotfiles

Guia para configurar un entorno de desarrollo completo en Debian usando mis dotfiles. Sigue los pasos en orden.

## Requisitos Previos

- Una instalación limpia de Debian
- Acceso a internet
- Permisos de sudo

---

## Paso 1: Configuración Inicial del Sistema

### 1.1 Configurar permisos de sudo

```bash
su -
# Ingresar contraseña de root
```

Edita la configuración de sudo:

```bash
visudo
```

Agrega la siguiente línea debajo de `%sudo ALL=(ALL:ALL) ALL`:

```
%joaquin ALL=(ALL:ALL) ALL
```

Guarda y sal del editor (Ctrl+O, Enter, Ctrl+X en nano).

### 1.2 Actualizar el sistema

```bash
sudo apt update
sudo apt upgrade -y
```

### 1.3 Instalar Git y configurar SSH

```bash
sudo apt install git
```

Genera tu clave SSH:

```bash
ssh-keygen -t rsa -b 4096 -C "joaquinfelipezrojas@gmail.com"
```
Dejar passphrase vacía cuando pregunte.

Agrega la clave al agente SSH:

```bash
ssh-add ~/.ssh/id_rsa
cat ~/.ssh/id_rsa.pub
```

> Copia el contenido mostrado y añádelo a tu cuenta de GitHub en: Settings → SSH and GPG keys → New SSH key.

### 1.4 Clonar el repositorio

```bash
mkdir ~/repos
cd ~/repos
git clone git@github.com:JoaquinFr87/dotfiles.git
```

> Cuando pregunte "Are you sure you want to continue connecting?", escribe: `yes`

---

## Paso 2: Instalar Utilidades Básicas

```bash
sudo apt install tree xclip htop fastfetch
sudo apt update && sudo apt install stow -y
```
> **Stow** es fundamental para este setup - se usa para crear enlaces simbólicos de las configuraciones.

---

## Paso 3: Configurar XFCE4

### 3.1 Limpiar configuración existente

```bash
rm -rf ~/.config/xfce4
rm ~/repos/dotfiles/xfce/.config/xfce4/desktop/icons.screen.latest.rc
```

### 3.2 Enlazar configuración con Stow

```bash
cd ~/repos/dotfiles
stow -t ~ xfce
```

### 3.3 Configurar Wallpaper

```bash
mkdir -p ~/Pictures
cd ~/repos/dotfiles
stow -t ~/Pictures Pictures
```

> **Importante:** Abre la aplicación de escritorio (Desktop Settings), añade el folder `Pictures` y selecciona `wallpaper.jpg` como fondo de pantalla.

---

## Paso 4: Instalar Kitty Terminal

### 4.1 Instalación
Instala herramientas básicas:
```bash
sudo apt install curl -y
```
Instala Kitty usando el script oficial para obtener la última versión. Consulta la guía oficial: https://sw.kovidgoyal.net/kitty/binary/
```bash
curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
```

### 4.2 Configurar PATH

Abre `~/.bashrc` y añade al final:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Luego ejecuta:

```bash
source ~/.bashrc
```

### 4.3 Configurar archivo .desktop

Edita `~/.local/share/applications/kitty.desktop` y cambia las rutas a absolutas:

```
TryExec=/home/joaquin/.local/bin/kitty
Exec=/home/joaquin/.local/bin/kitty
```

### 4.4 Enlazar configuración

```bash
rm -rf ~/.config/kitty
cd ~/repos/dotfiles
stow -t ~ kitty
```

> **Nota:** Ve a Configuración → Aplicaciones por defecto y selecciona Kitty como terminal predeterminada.

---

## Paso 5: Instalar ZSH + Oh-My-Zsh + Powerlevel10k

### 5.1 Instalar ZSH

```bash
sudo apt install zsh
chsh -s $(which zsh)
```
> **Importante:** Cierra sesión y vuelve a entrar para que los cambios surtan efecto.

### 5.2 Instalar Oh-My-Zsh

Usa el script oficial de instalación (más información: https://github.com/ohmyzsh/ohmyzsh/wiki):
```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

### 5.3 Instalar fuentes Meslo Nerd Font

```bash
mkdir -p ~/.local/share/fonts/Meslo
wget https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip -O /tmp/Meslo.zip
unzip /tmp/Meslo.zip -d ~/.local/share/fonts/Meslo/
rm /tmp/Meslo.zip
fc-cache -fv
```

### 5.4 Instalar plugins de ZSH

```bash
sudo apt install zsh-autosuggestions zsh-syntax-highlighting
```

### 5.5 Instalar Powerlevel10k

```bash
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
```

### 5.6 Enlazar configuración de ZSH

```bash
rm -f ~/.zshrc ~/.p10k.zsh ~/.zlogin ~/.zprofile
cd ~/repos/dotfiles
stow -t ~ zsh
zsh
```

### 5.7 Seleccionar fuente en Kitty

```bash
kitten choose-fonts
```

Sigue las instrucciones en pantalla para seleccionar una fuente Meslo.

---

## Paso 6: Instalar Neovim + LazyVim

### 6.1 Descargar e instalar Neovim

```bash
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
sudo rm -rf /opt/nvim-linux-x86_64
sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
rm nvim-linux-x86_64.tar.gz
```

### 6.2 Instalar dependencias

```bash
sudo apt install lazygit tree-sitter-cli build-essential fzf ripgrep fd-find
```

### 6.3 Limpiar configuración previa de Neovim

```bash
rm -rf ~/.config/nvim
rm -rf ~/.local/share/nvim
rm -rf ~/.local/state/nvim
rm -rf ~/.cache/nvim
```

### 6.4 Enlazar configuración de Neovim

```bash
cd ~/repos/dotfiles
stow -t ~ nvim
```

> **Nota:** La primera vez que ejecutes `nvim`, LazyVim instalará automáticamente todos los plugins. Esto puede tardar unos minutos.

---

## Paso 7: Configuración de Máquinas Virtuales (VirtualBox)

Si estás usando una máquina virtual, instala las Guest Additions:

```bash
bash /media/cdrom0/autorun.sh
```

Luego cambia la resolución de pantalla desde la configuración de display de tu VM.

---

## Solución de Problemas

### Stow muestra errores de conflictos

Si Stow te da errores porque los archivos ya existen, elimina los archivos existentes en tu home antes de ejecutar stow:

```bash
rm -rf ~/.config/<nombre-del-programa>
cd ~/repos/dotfiles
stow -t ~ <nombre-del-programa>
```

### ZSH no se activa

Asegúrate de cerrar sesión completamente y volver a entrar, o reinicia la máquina.

### Neovim no encuentra los plugins

Ejecuta `:Lazy sync` dentro de Neovim para sincronizar los plugins manualmente.

---

## Estructura del Repositorio

```
dotfiles/
├── xfce/          # Configuración de XFCE4
├── kitty/         # Configuración de Kitty terminal
├── zsh/           # Configuración de ZSH + Powerlevel10k
├── nvim/          # Configuración de Neovim + LazyVim
└── Pictures/      # Wallpapers e imágenes
```

Para más información y configuraciones adicionales, consulta:

- https://github.com/ohmyzsh/ohmyzsh/wiki
- https://github.com/neovim/neovim
- https://sw.kovidgoyal.net/kitty/
- https://www.lazyvim.org/

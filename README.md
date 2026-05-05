# Guía de Instalación de Dotfiles SWAY o XFCE

Guia para configurar un entorno de desarrollo completo en Debian usando mis dotfiles. Sigue los pasos en orden.

## Requisitos Previos

- Una instalación limpia de Debian
- Acceso a internet


---

## Configuración Inicial del Sistema
### Configurar permisos de sudo

```bash
su -
# Ingresar contraseña de root
```
Instalar sudo
```bash
apt install sudo
```

Edita la configuración de sudo:

```bash
visudo
```

Agrega la siguiente línea debajo de `%sudo ALL=(ALL:ALL) ALL`:

```
joaquin ALL=(ALL:ALL) ALL
```

Guarda y sal del editor (Ctrl+O, Enter, Ctrl+X en nano).
```bash
exit
```
## Instalar sway
```bash 
sudo apt install sway
```

### Instalar y Configurar Firefox

```bash
sudo apt install firefox-esr
```

Anadir cuenta de firefox, gmail y de github.

### Actualizar el sistema

```bash
sudo apt update
sudo apt upgrade -y
```
### Instalar grim shot para tomar captura de pantalla de sway
```bash
sudo apt install grimshot
```
### Creamos una carpeta de recortes

```bash
mkdir ~/recortes
```
### Instalar wofi
```bash 
sudo apt install wofi
```
```bash
sudo apt update
sudo apt install pipewire wireplumber pipewire-pulse pavucontrol brightnessctl network-manager 
```

modificar el archivo /etc/network/interfaces
```bash
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

source /etc/network/interfaces.d/*

# The loopback network interface
auto lo
iface lo inet loopback
```

iniciar los servicios
```bash
sudo systemctl enable --now NetworkManager
systemctl --user enable --now pipewire wireplumber pipewire-pulse
```
copiar los archivos sway, wofi y waybar
```bash
cp -r ~/repos/dotfiles/{sway,wofi, waybar} ~/.config/
```

### Instalar Git y configurar SSH

```bash
sudo apt install git
```
Agrega la configuracion Global
```bash
git config --global user.name "Joaquin Alessandro Felipez Rojas"
git config --global user.email "joaquinfelipezrojas@gmail.com"
```
Genera tu clave SSH:

```bash
ssh-keygen -t rsa -b 4096 -C "joaquinfelipezrojas@gmail.com"
```
Dejar passphrase vacía cuando pregunte.

Iniciar el agente
```bash
eval "$(ssh-agent -s)"
```
Agrega la clave al agente SSH:

```bash
ssh-add ~/.ssh/id_rsa
cat ~/.ssh/id_rsa.pub
```

> Copia el contenido mostrado y añádelo a tu cuenta de GitHub en: Settings → SSH and GPG keys → New SSH key.

### Clonar el repositorio

```bash
mkdir ~/repos
cd ~/repos
git clone git@github.com:JoaquinFr87/dotfiles.git
```

> Cuando pregunte "Are you sure you want to continue connecting?", escribe: `yes`

---

## Instalar Utilidades Básicas

```bash
sudo apt install tree htop fastfetch build-essential 
```
---

## Configurar XFCE4
### Configurar Wallpaper

```bash
cp -r ~/repos/dotfiles/Pictures ~/
```

###Limpiar configuración existente

```bash
rm -rf ~/.config/xfce4
```


## Instalar Kitty Terminal

### Instalación
Instala herramientas básicas:
```bash
sudo apt install curl -y
```
Instala Kitty usando el script oficial para obtener la última versión. Consulta la guía oficial: https://sw.kovidgoyal.net/kitty/binary/
```bash
curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
```
### Crear un enlace de kitty
Crear un enlace de kitty para que sea reconocido por el path del sistema. Crear symlink para kitty y kitten (necesario para herramientas integradas)
```bash
sudo ln -s ~/.local/kitty.app/bin/kitty ~/.local/bin/kitty
sudo ln -s ~/.local/kitty.app/bin/kitten ~/.local/bin/kitten
```
Enlace recursivo
```bash
sudo cp -as ~/.local/kitty.app/share/* ~/.local/share/icons/hicolor/ 
```
> **Nota**: comando sed puede modificar archivos desde solo terminal

### Enlazar configuración

```bash

rm -rf ~/.config/kitty
cp -r ~/repos/dotfiles/kitty/.config/kitty ~/.config/
```
---

## Instalar ZSH + Oh-My-Zsh + Powerlevel10k

### Instalar ZSH

```bash
sudo apt install zsh
chsh -s $(which zsh)
```
> **Importante:** Cierra sesión y vuelve a entrar para que los cambios surtan efecto.

### Instalar Oh-My-Zsh

Usa el script oficial de instalación (más información: https://github.com/ohmyzsh/ohmyzsh/wiki):
```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

### Instalar fuentes Meslo Nerd Font

```bash
mkdir -p ~/.local/share/fonts/Meslo
wget https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip -O /tmp/Meslo.zip
unzip /tmp/Meslo.zip -d ~/.local/share/fonts/Meslo/
rm /tmp/Meslo.zip
fc-cache -fv
```

### Instalar plugins de ZSH

```bash
sudo apt install zsh-autosuggestions zsh-syntax-highlighting
```

### Instalar Powerlevel10k

```bash
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
```

### Enlazar configuración de ZSH

```bash
rm -f ~/.zshrc ~/.p10k.zsh ~/.zlogin ~/.zprofile
cd ~/repos/dotfiles
stow -t ~ zsh
zsh
```

### Seleccionar fuente en Kitty

```bash
kitten choose-fonts
```

Sigue las instrucciones en pantalla para seleccionar una fuente Meslo.

---

## Instalar Neovim + LazyVim

### Descargar e instalar Neovim

Descargar e instalar Rust
```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```
Instalar Bob por medio del script
```bash
curl -fsSL https://raw.githubusercontent.com/MordechaiHadad/bob/master/scripts/install.sh | bash
```
Instalar nvim
```bash
bob use stable
```
> *Nota*: para actualizar nvim bob update stable

anadir un enlace de nvim al share
```bash
sudo cp -as ~/.local/share/bob/{nvim-version}/share/* /usr/share/
```

### Instalar dependencias

```bash
sudo apt install lazygit tree-sitter-cli build-essential fzf ripgrep fd-find
```

### Limpiar configuración previa de Neovim

```bash
rm -rf ~/.config/nvim
rm -rf ~/.local/share/nvim
rm -rf ~/.local/state/nvim
rm -rf ~/.cache/nvim
```

### Enlazar configuración de Neovim

```bash
cp -r ~/repos/dotfile/nvim/.config/nvim ~/.config/
```

> **Nota:** La primera vez que ejecutes `nvim`, LazyVim instalará automáticamente todos los plugins. Esto puede tardar unos minutos.

## Instalar Node.js
```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash
```
```bash
export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
```
```bash
nvm install 24
```
Instalar pnpm
```bash
corepack enable pnpm
```
Verificar
```bash
node -v 
npm -v
pnpm -v
```
## Instalar opencode
### Instalar mediante script
Utilizar el script oficial de opencode (mas informacion: https://opencode.ai/docs)
```bash
curl -fsSL https://opencode.ai/install | bash
```
### Enlazar configuracion opencode
```bash
cp -r ~/repos/dotfiles/opencode/.config/opencode ~/.config/
rm -f ~/.config/opencode
cd ~/repos/dotfiles
stow -t ~ opencode
```

## Instalar Docker Engine
Desinstalar paquetes conflictivos
```bash
sudo apt remove $(dpkg --get-selections docker.io docker-compose docker-doc podman-docker containerd runc | cut -f1)
```
Anadir la oficial GPG key
```bash
sudo apt update
sudo apt install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
```
Anadir el repositorio a las fuentes de apt
```bash
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt update
```
Instalar los paquetes docker
```bash
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```
Verificar Instalacion
```bash
 sudo docker run hello-world
```
## Modificar GRUB
Modificar el tiempo de carga de grub, para cargar el sistema operativo
>*Nota*: cambiar de 0 por si tienes 2 sistemas
```bash
sudo sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /etc/default/grub
```
Actualizar grub
```bash
sudo update-grub
```
## Modificar lightdm (gestor sesiones)
Inicio de sesion automatica al iniciar el sistema
```bash
sudo sed -i '/^\[Seat:\*\]/,/^\[/ s/^#\?autologin-user=.*/autologin-user=joaquin/' /etc/lightdm/lightdm.conf
sudo sed -i '/^\[Seat:\*\]/,/^\[/ s/^#\?autologin-user-timeout=.*/autologin-user-timeout=0/' /etc/lightdm/lightdm.conf
```

---

## Configuración de Máquinas Virtuales (VirtualBox)

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

## Lista de tareas

- [x] Instalación de Node.js
- [x] Instalación de pnpm
- [x] Instalacion de opencode
- [x] Instalación de Docker
- [x] Configuración GRUB
- [x] Configuración sesión
- [ ] Mako
- [ ] screen share

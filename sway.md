# Guía de instalación SWAY + NOCTALIA — DEBIAN 13 (Trixie)

Entorno de escritorio Wayland basado en:

- [Sway](https://swaywm.org) — compositor / tiling WM
- [Noctalia](https://noctalia.dev) — shell (barra, launcher, notificaciones, lock screen, OSD, fondo, clipboard)
- Repo de referencia: [piratheon/sway-noctalia-dots](https://github.com/piratheon/sway-noctalia-dots)
- Paleta: **Gruvbox Material Dark**

> **Noctalia v5 reemplaza**: waybar, mako, wofi, swaybg, swaylock, swayidle, wlogout, grimshot, brightnessctl y los bindings de wpctl. Todo se controla con `noctalia msg`.

---

## 1. SUDO

```bash
su -
# ingresar contraseña de root
```

```bash
apt install sudo
sudo usermod -aG sudo {nombre_usuario}
exit # sale de root
exit # sale al tty
```

### Instalacion de Zen y Firefox

```bash
sudo apt install firefox-esr
```

```bash
wget https://github.com/zen-browser/desktop/releases/latest/download/zen.linux-x86_64.tar.xz

tar -xf zen.linux-x86_64.tar.xz

# Crear las estructuras de directorios locales si no existen
mkdir -p ~/.local/share/zen
mkdir -p ~/.local/bin
mkdir -p ~/.local/share/icons/hicolor/128x128/apps
mkdir -p ~/.local/share/applications

cd zen/
# Mover todo el contenido actual al directorio base de la aplicación
mv * ~/.local/share/zen/
```

```bash
# Enlazar el binario a tu PATH local
ln -s ~/.local/share/zen/zen ~/.local/bin/zen

# Enlazar el ícono de 128px al directorio de íconos del sistema
ln -s ~/.local/share/zen/browser/chrome/icons/default/default128.png ~/.local/share/icons/hicolor/128x128/apps/zen.png

# Opcional: Refrescar la caché de íconos para que tu entorno gráfico lo
# detecte de inmediato
gtk-update-icon-cache ~/.local/share/icons/hicolor
```

creado el acceso directo en `~/.local/share/applications/zen.desktop`

```txt
[Desktop Entry]
Name=Zen Browser
Comment=Navegador web rápido y privado
Exec=zen %u
Icon=zen
Type=Application
Categories=Network;WebBrowser;
Terminal=false
StartupNotify=true
MimeType=text/html;text/xml;application/xhtml+xml;application/xml;application/vnd.mozilla.xul+xml;application/rss+xml;application/rdf+xml;image/gif;image/jpeg;image/png;x-scheme-handler/http;x-scheme-handler/https;
```

---

## 2. BASE

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install git curl unzip wl-clipboard zsh \
  lazygit build-essential fzf ripgrep fd-find \
  clang libclang-dev htop tree fastfetch
```

---

## 3. GIT

```bash
git config --global user.name "Tu nombre"
git config --global user.email "tu email.com"
ssh-keygen -t rsa -b 4096 -C "tu email"   # passphrase vacía
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa
cat ~/.ssh/id_rsa.pub | wl-copy            # agregar a GitHub → Settings → SSH keys
```

Clonar los dotfiles:

```bash
mkdir -p ~/repos
cd ~/repos
git clone git@github.com:Joaquinfr87/dotfiles.git
cd ~
```

---

## 4. Fuentes

Instalar **Iosevka Nerd Font** (la usa la variable `$font` de sway):

```bash
mkdir -p ~/.local/share/fonts/Iosevka
unzip ~/Downloads/{Iosevka-Term-Nerd-Font}.zip -d ~/.local/share/fonts/Iosevka/
fc-cache -fv
```

Instalar la fuente de emojis (fallback de `$font`):

```bash
sudo apt install fonts-noto-color-emoji
```

---

## 5. KITTY

```bash
curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
mkdir -p ~/.local/{bin,share}
ln -s ~/.local/kitty.app/bin/kitty ~/.local/bin/kitty
ln -s ~/.local/kitty.app/bin/kitten ~/.local/bin/kitten
cp -as ~/.local/kitty.app/share/* ~/.local/share/
rm -rf ~/.config/kitty
cp -r ~/repos/dotfiles/kitty ~/.config/
kitten themes   # opcional
```

---

## 5.1 ZSH

cambiar la shell

```bash
chsh -s $(which zsh)
```

> **Importante:** Cierra sesión y vuelve a entrar para que el cambio de shell surta efecto.
instalar [oh-my-zsh](https://github.com/ohmyzsh/ohmyzsh/)

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

instalar plugins de zsh

```bash
sudo apt install zsh-autosuggestions zsh-syntax-highlighting
```

instalar [p10k](https://github.com/romkatv/powerlevel10k)

```bash
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
```

copiar la config

```bash
rm -f ~/.zshrc ~/.p10k.zsh
cp ~/repos/dotfiles/{.zprofile,.zshrc} ~/
```

configurar p10k

```bash
p10k configure
```

seleccionar fuente en kitty

```bash
kitten choose-fonts
```

---

## 5.2 NVIM

Descargar e instalar [Rust](https://rust-lang.org/tools/install/)

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

Instalar por medio del script [Bob](https://github.com/mordechaihadad/bob)

```bash
curl -fsSL https://raw.githubusercontent.com/MordechaiHadad/bob/master/scripts/install.sh | bash
```

Instalar nvim

```bash
bob use stable
```

> *Nota*: para actualizar nvim `bob update stable`

anadir un enlace de nvim al share

```bash
sudo cp -as ~/.local/share/bob/{nvim-version}/share/* ~/.local/share/
```

anadir un enlace al root

```bash
sudo ln -s ~/.local/share/bob/nvim-bin/nvim /usr/bin/
```

instalar tree-sitter-cli
> Se puede instalar por apt install pero la version es antigua para nvim-tree-sitter

```bash
cargo install tree-sitter-cli
```

Limpiar configuración previa de Neovim

```bash
rm -rf ~/.config/nvim
rm -rf ~/.local/share/nvim
rm -rf ~/.local/state/nvim
rm -rf ~/.cache/nvim
```

Enlazar configuración de Neovim

```bash
cp -r ~/repos/dotfiles/nvim ~/.config/
```

> **Nota:** La primera vez que ejecutes `nvim`, LazyVim instalará automáticamente todos los plugins. Esto puede tardar unos minutos.

---

## 6. SWAY

```bash
sudo apt install sway
```

Iniciar la pila de audio PipeWire:

```bash
sudo apt install pipewire wireplumber pipewire-pulse
systemctl --user enable --now pipewire wireplumber pipewire-pulse
```

Red: editar `/etc/network/interfaces` (o instalar `network-manager`, ver [Opcionales](#13-opcionales)):

```bash
source /etc/network/interfaces.d/*
auto lo
iface lo inet loopback
allow-hotplug enp4s0
iface enp4s0 inet dhcp
iface enp4s0 inet6 auto
```

---

## 7. NOCTALIA

Añadir el repositorio APT oficial (Debian Trixie):

```bash
wget https://pkg.noctalia.dev/deb/nickh-archive-keyring.deb
sudo dpkg -i nickh-archive-keyring.deb
sudo wget -O /etc/apt/sources.list.d/noctalia-trixie.sources https://pkg.noctalia.dev/deb/noctalia-trixie.sources
sudo apt update
sudo apt install noctalia
```

> Noctalia necesita en runtime: daemon PipeWire, un proveedor de Secret Service (`gnome-keyring`) y `upower`/`ddcutil` como opcionales para batería/brillo.

---

## 8. Dependencias de la config

```bash
sudo apt install xdg-desktop-portal xdg-desktop-portal-wlr \
  wl-clipboard pavucontrol gnome-keyring autotiling
```

- `autotiling` — lo arranca `config.d/06-autostart`
- `xdg-desktop-portal-wlr` — compartir pantalla / diálogos de archivos
- `wl-clipboard` — portapapeles CLI de Wayland (`wl-copy`/`wl-paste`) para la terminal y scripts (Noctalia no lo instala ni lo sustituye)
- `pavucontrol` — ajustes finos de audio (opcional)
- `gnome-keyring` — Secret Service (clipboard encriptado y calendario de Noctalia)

---

## 9. Configuración (dotfiles)

```bash
rm -rf ~/.config/sway ~/.config/noctalia
cp -r ~/repos/dotfiles/{sway,noctalia} ~/.config/
```

Copiar wallpapers:

```bash
mkdir -p ~/Pictures
cp -r ~/repos/dotfiles/Pictures/* ~/Pictures/
```

> Los cambios de la GUI de Noctalia (Settings) se guardan en `~/.local/state/noctalia/settings.toml`, que **gana** sobre tu `config.toml` si hay valores duplicados. No se edita a mano.

---

## 10. Estructura de archivos

```
~/.config/sway/
├── config                        # entrada delgada (solo includes)
├── config.d/
│   ├── 00-variables              # $mod, $term, $font, paleta Gruvbox
│   ├── 01-outputs                # eDP-1 1366x768, HDMI-A-1, modo pantallas
│   ├── 02-input                  # touchpad, teclado (layout us), cursor
│   ├── 03-theme                  # client colors, gaps, borders
│   ├── 04-bindings               # atajos sway + IPC noctalia
│   ├── 05-floating               # reglas de ventanas flotantes
│   └── 06-autostart              # noctalia, autotiling, portals, gsettings
├── user/                         # fragmentos extra (vacío, .gitkeep)
└── walls/                        # fondos de pantalla
~/.config/noctalia/
└── config.toml                   # configuración del shell (TOML, v5)
```

> ⚠️ El repo `piratheon/sway-noctalia-dots` trae un `settings.json` de **Noctalia v4 (JSON)**. No se copia: en v5 la config es **TOML** en `~/.config/noctalia/`.

---

## 11. Atajos de teclado

| Atajo | Acción |
| --- | --- |
| `$mod+Return` | terminal (kitty) |
| `$mod+d` | launcher Noctalia |
| `$mod+i` | control center |
| `$mod+comma` | settings Noctalia |
| `$mod+t` | lock screen |
| `$mod+p` | modo pantallas [E]xterno / [D]esconectar |
| `Print` / `$mod+Print` | screenshot región / pantalla completa |
| `$mod+Shift+c` | recargar config |
| `$mod+Shift+e` | cerrar sesión |
| `$mod+Shift+q` | matar ventana |
| `$mod+1…0` / `$mod+Shift+1…0` | workspaces / mover a workspace |
| `$mod+$left/…/$right` | mover foco |
| `$mod+Shift+$left/…` | mover ventana |
| `$mod+b` / `$mod+v` / `$mod+s` / `$mod+w` / `$mod+e` | splith / splitv / stacking / tabbed / toggle split |
| `$mod+f` | fullscreen |
| `$mod+space` / `$mod+Shift+space` | focus mode_toggle / floating toggle |
| `$mod+r` | modo resize |
| `$mod+minus` / `$mod+Shift+minus` | scratchpad show / move |
| `XF86AudioPlay/Next/Prev` | control de medios |
| `XF86Audio*/XF86MonBrightness*` | volumen / brillo (noctalia) |

---

## 12. Verificación y primeros pasos

```bash
# Validar configs sin reiniciar
sway --validate -c ~/.config/sway/config
noctalia config validate
```

1. Recarga sway con `$mod+Shift+c` (o reinicia la sesión para que Noctalia lea `config.toml`).
2. Configura la barra/widgets en Settings (`$mod+comma`).
3. Ajusta la localización y el clima en Settings → Location.
4. Si el cursor brilla demasiado: `seat * hide_cursor 2000` en `config.d/02-input`.

---

## 13. Opcionales

- **NetworkManager** — si quieres que el widget de red de la barra funcione:

  ```bash
  sudo apt install network-manager
  sudo systemctl enable --now NetworkManager
  ```

- **wdisplays** — gestor gráfico de monitores (`sudo apt install wdisplays`).
- **swayfx** — el repo de referencia usa blur/redondeo (`config.d/swayfx`), pero requiere el fork `swayfx`; con sway stock se omite.

---

## 14. Referencia

- Sway: `man 5 sway`
- Noctalia: <https://docs.noctalia.dev/v5/>
- IPC de Noctalia: `noctalia msg --help`

# Dotfiles — Sway + Noctalia v5 & Servidores SSH

Configuración modular, estética y profesional de entorno de trabajo para **Linux (Debian 13 Trixie, Ubuntu y servidores remotos por SSH)** con paleta **Gruvbox Material Dark**.

El proyecto cuenta con un **asistente de instalación 100% CLI guiado por pasos**, donde puedes personalizar tu entorno (Escritorio o Servidor), elegir tu prompt favorito (**Starship** o **Oh My Zsh + p10k**) y marcar/tachar con casillas `[X]` / `[ ]` las herramientas extras que deseas instalar (**Node.js, pnpm, Docker, OpenCode, Freebuff, Codex, AGY**).

> **Sin dependencias externas como GNU Stow:** Las sincronizaciones se realizan mediante copias limpias (`cp`) gestionadas por el comando [`bin/dot-sync`](bin/dot-sync) con **backups automáticos previos** en `~/.dotfiles_backup/`.

---

## 🚀 Guía de Instalación Paso a Paso

### Paso 0: Requisitos Previos en una Máquina Limpia

#### Caso A: En Debian Mínimo (Netinst)
Si acabas de instalar Debian desde la imagen mínima, `sudo` no viene configurado. Ejecuta este comando como `root` una sola vez:

```bash
su -c "apt update && apt install -y sudo git curl && usermod -aG sudo $USER"
```
*(Cierra y vuelve a abrir tu terminal para que tome efecto el grupo `sudo`).*

#### Caso B: En Servidores SSH / Ubuntu / Máquinas con `sudo` listo
Solo asegúrate de tener `git` y `curl`:

```bash
sudo apt update && sudo apt install -y git curl
```

---

### Paso 1: Clonar el Repositorio

Clona el repositorio por **HTTPS** (no requiere claves SSH ni configuración previa):

```bash
mkdir -p ~/repos && cd ~/repos
git clone https://github.com/Joaquinfr87/dotfiles.git
cd dotfiles
```

---

### Paso 2: Iniciar el Asistente Guiado CLI

Ejecuta el orquestador principal:

```bash
./install.sh
```

El instalador te guiará interactivamente a través de 3 sencillos pasos en tu terminal:

#### 1. Selección de Entorno
```text
>> PASO 1: Selección de Entorno
  1) Entorno de escritorio completo (Sway + Noctalia + Greeter + Terminal)
  2) Entorno de servidor (Solo terminal para SSH, sin interfaz gráfica)
  3) Sincronizar configuraciones (con backup automático)
  4) Menú de herramientas extras (instalar solo Node, Docker, AI...)
  5) Salir
```
* **Escritorio Completo:** Instala Sway, Noctalia v5, Noctalia Greeter (login con `greetd`), audio PipeWire, gestor Bluetooth `bluetuith`, fuentes Iosevka Nerd Font, Kitty y Zen Browser. Configura perfiles automáticos de resolución para Laptop (768p) y Monitores Externos/Desktop (1080p).
* **Servidor SSH:** Instala únicamente herramientas CLI, Neovim (LazyVim), Tmux con persistencia y Git (cero paquetes gráficos).

#### 2. Selección de Shell y Prompt
```text
>> PASO 2: Selección de Shell y Prompt
  1) Starship (Recomendado — Rust, ultrarrápido < 20ms, tema Gruvbox)
  2) Oh My Zsh + Powerlevel10k (Entorno clásico con plugins OMZ)
```

#### 3. Selector de Herramientas Extras (Casillas interactivas)
```text
>> PASO 3: Herramientas Extras & Agentes AI
Marca o desmarca las herramientas escribiendo su número [1-7]:

  [1] [X] Node.js LTS (JavaScript runtime vía NVM)
  [2] [X] pnpm (Gestor de paquetes ultrarrápido)
  [3] [X] Docker Engine + Docker Compose + Lazydocker
  [4] [X] OpenCode CLI (Agente AI para terminal)
  [5] [X] Freebuff CLI (Agente AI para proyectos)
  [6] [X] Codex CLI (Agente AI interactivo)
  [7] [X] Antigravity CLI (agy)

  [A] Marcar todos   [N] Desmarcar todos
  [C] Continuar con la instalación (o pulsa Enter)
  [S] Saltar herramientas extras
```
* Escribe el número correspondiente para alternar cualquier herramienta entre `[X]` y `[ ]`.
* Pulsa **`C`** (o simplemente **`Enter`**) para comenzar la instalación desatendida.

---

### Paso 3: Configurar Clave SSH para GitHub (Opcional)

Una vez terminada la instalación, si deseas configurar tu clave SSH para hacer `git push` a tus repositorios sin contraseñas:

```bash
# 1. Generar clave moderna Ed25519
ssh-keygen -t ed25519 -C "tu@email.com"

# 2. Iniciar el agente y añadir la clave
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# 3. Copiar la clave pública:
# En Desktop (Wayland):
cat ~/.ssh/id_ed25519.pub | wl-copy

# En Servidor SSH (mostrar en pantalla para copiarla):
cat ~/.ssh/id_ed25519.pub

# 4. Cambiar el remoto de este repositorio a SSH:
git remote set-url origin git@github.com:Joaquinfr87/dotfiles.git
```
*(Pega la clave en: GitHub ➔ Settings ➔ SSH and GPG keys).*

---

## 🔄 Gestión Diaria con `dot-sync` (Sin GNU Stow)

El comando [`bin/dot-sync`](bin/dot-sync) (disponible también con el alias `dots`) te permite mantener sincronizado tu sistema y el repositorio de forma bidireccional y segura:

| Comando | Función |
| --- | --- |
| `dot-sync status` (o `dots status`) | Muestra qué archivos están sincronizados, modificados o faltantes. |
| `dot-sync diff` (o `dots diff`) | Muestra las diferencias exactas de código entre tu sistema y el repo. |
| `dot-sync deploy` (o `dots deploy`) | **Repo ➔ Sistema:** Despliega configs creando un **backup previo** en `~/.dotfiles_backup/`. |
| `dot-sync save` (o `dots save`) | **Sistema ➔ Repo:** Copia los cambios que hiciste en `~/.config` de vuelta al repositorio. |

### Flujo habitual de trabajo:
1. Haces un cambio en tu editor (por ejemplo en `~/.config/sway/config.d/04-bindings`).
2. Compruebas qué cambió: `dot-sync diff`
3. Traes los cambios al repositorio: `dot-sync save`
4. Haces commit en Git: `git add . && git commit -m "feat: nuevo atajo" && git push`

---

## 📁 Estructura del Repositorio

```text
dotfiles/
├── bin/                          # Comandos auxiliares en tu $PATH
│   ├── dot-sync                  # Sincronizador bidireccional con backups automáticos
│   └── tmux-sessionizer          # Selector fzf de sesiones y proyectos para Tmux
├── git/                          # Configuración global de Git
│   ├── config                    # .gitconfig con aliases, delta y rebase
│   └── ignore                    # .gitignore global (.DS_Store, *.local, etc.)
├── install/                      # Scripts de instalación modulares e idempotentes
│   ├── 00-helpers.sh             # Funciones de log, colores y detección de distro
│   ├── 01-base-packages.sh       # Paquetes esenciales (git, curl, fzf, ripgrep, direnv, build-essential)
│   ├── 02-cli-tools.sh           # Neovim (bob/tarball), zoxide, eza, bat, lazygit, plugins tmux
│   ├── 03-shell.sh               # Zsh nativo, Starship y plugins (soporta opción --omz)
│   ├── 04-desktop-packages.sh    # Sway, Wayland, PipeWire, Kanshi, bluetuith, portales
│   ├── 05-noctalia.sh            # Noctalia v5 y Noctalia Greeter (greetd display manager)
│   ├── 06-fonts-wallpapers.sh    # Iosevka Nerd Font y Zen Browser
│   ├── 07-copy-configs.sh        # Copiado con backup según el perfil (server/desktop)
│   └── 08-dev-ai-tools.sh        # Node.js, pnpm, Docker, OpenCode, Freebuff, AGY, Codex
├── kanshi/                       # Perfiles multirresolución automáticos (laptop 768p, desktop 1080p, dual)
│   └── config
├── kitty/                        # Terminal Kitty (tema Gruvbox Dark y teclado CSI-u)
│   ├── current-theme.conf
│   └── kitty.conf
├── noctalia/                     # Configuración de Noctalia v5
│   ├── config.toml               # Estética, colores, atajos y lanzador
│   └── settings.toml             # Configuración de barra, escala y plugins de estado
├── noctalia-greeter/             # Configuración de greetd login manager
│   └── greeter.toml
├── nvim/                         # Neovim (LazyVim, LSP, Blink, Obsidian, Gruvbox)
├── Pictures/                     # Fondos de pantalla Gruvbox
├── starship/                     # Configuración de Starship prompt (Gruvbox Material Dark)
│   └── starship.toml
├── sway/                         # Sway tiling window manager (modular en config.d/)
│   ├── config                    # Archivo principal que incluye config.d/
│   └── config.d/                 # 01-outputs, 02-inputs, 03-windows, 04-bindings, 05-autostart
├── tmux/                         # Tmux (persistencia con resurrect/continuum y sessionizer)
│   └── tmux.conf
├── agents.md                     # Guía de integración de agentes AI (OpenCode y Freebuff)
├── .gitignore                    # Exclusiones de Git (binarios .deb, backups, .freebuff)
├── .zprofile                     # Entorno de login (ejecuta sway solo en tty1 y si existe)
├── .zshrc                        # Shell interactivo ultrarrápido (Zsh nativo + Starship + direnv)
└── install.sh                    # Orquestador principal de instalación 100% CLI
```

---

## ⌨️ Atajos de Teclado Clave (Sway + Wayland)

| Atajo | Acción |
| --- | --- |
| `$mod+Return` | Abrir terminal (**Kitty**) |
| `$mod+Shift+Return` | Abrir **tmux-sessionizer** (selector de proyectos con fzf) |
| `$mod+Shift+b` | Abrir navegador (**Zen Browser**) |
| `$mod+d` | Abrir launcher de aplicaciones (Noctalia) |
| `$mod+i` | Abrir Centro de Control (Noctalia) |
| `$mod+comma` | Ajustes de Noctalia |
| `$mod+t` | Bloquear pantalla (Lock screen) |
| `Ctrl+Alt+Delete` | Menú de sesión (Apagar / Reiniciar / Suspender) |
| `Print` / `$mod+Print` | Captura de pantalla región / pantalla completa |
| `$mod+Shift+q` | Cerrar ventana activa |
| `$mod+f` | Pantalla completa (Fullscreen) |
| `$mod+Shift+space` | Alternar ventana flotante / tiling |
| `$mod+1…0` | Cambiar de workspace |
| `$mod+Shift+1…0` | Mover ventana a workspace |
| `$mod+Shift+c` | Recargar configuración de Sway |

---

## 🖥️ Gestión Dinámica de Pantallas (Kanshi)

El daemon **Kanshi** detecta automáticamente la conexión y desconexión de monitores, aplicando la resolución, posición y asignación de workspaces adecuada al instante:

| Perfil | Dispositivo / Salida | Resolución | Comportamiento |
| --- | --- | --- | --- |
| `laptop` | Pantalla integrada (`eDP-1`) | 1366x768 @ 60Hz | Modo portátil por defecto (escala 1.0) |
| `desktop_hdmi` | PC de escritorio con HDMI (`HDMI-A-1`) | 1920x1080 @ 60Hz | Full HD nativo |
| `desktop_dp` / `desktop_dp2` | PC de escritorio con DisplayPort (`DP-1`/`DP-2`) | 1920x1080 @ 60Hz | Full HD nativo |
| `presentacion` | Laptop + Monitor externo HDMI | Dual (768p + 1080p) | HDMI a la derecha, workspace 1 en el monitor externo |
| `laptop_dp` | Laptop + Monitor externo DP (Dock/USB-C) | Dual (768p + 1080p) | DP a la derecha, workspace 1 en el monitor externo |
| `laptop_clamshell` | Laptop con tapa cerrada conectada a HDMI | 1920x1080 @ 60Hz | Apaga `eDP-1` y mantiene activo solo el monitor externo |
| `desktop_dual` | PC de escritorio con doble monitor (DP + HDMI) | Dual 1080p | DP principal (workspace 1), HDMI secundario |

---

## 🎧 Bluetooth & Utilidades de Terminal

* **Bluetooth TUI (`bluetuith`)**: Ejecuta `bluetuith` en cualquier terminal Kitty para buscar, emparejar y conectar auriculares o periféricos Bluetooth con una interfaz interactiva y ligera.
* **Entornos automáticos (`direnv`)**: Integrado de forma nativa en `.zshrc`. Detecta archivos `.envrc` y carga variables o entornos virtuales de Python/Node automáticamente al entrar a tus directorios de trabajo.

---

## 🔒 Variables y Personalizaciones Locales

Para mantener tokens, claves API o rutas privadas sin subirlas al repositorio público:
* **Shell:** Crea el archivo `~/.zshrc.local` (este archivo es leído automáticamente por `.zshrc` y está ignorado en Git).
* **Git:** Crea el archivo `~/.gitconfig.local` para configurar tu nombre y email por máquina:
  ```ini
  [user]
      name = Tu Nombre
      email = tu@correo.com
  ```

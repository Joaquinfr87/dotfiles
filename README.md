# Dotfiles — Sway + Noctalia v5 & Servidores SSH

Configuración modular, estética y profesional de entorno de trabajo para **Linux (Debian 13 Trixie, Ubuntu y servidores remotos)** con paleta **Gruvbox Material Dark**.

Diseñado con dos perfiles de instalación independientes:
1. **Perfil Desktop:** Entorno gráfico completo basado en Wayland ([Sway](https://swaywm.org) + [Noctalia v5](https://noctalia.dev) + [Kitty](https://sw.kovidgoyal.net/kitty/) + [Zen Browser](https://zen-browser.app/)).
2. **Perfil Server / SSH:** Entorno de terminal ultraligero y de alta productividad ([Zsh](https://www.zsh.org/) + [Tmux](https://github.com/tmux/tmux) + [Neovim](https://neovim.io/) + Git profesional + CLIs modernas) para servidores sin entorno gráfico.

> **Sin dependencias de herramientas externas como GNU Stow:** Las sincronizaciones se realizan mediante copias limpias (`cp`) gestionadas por el script [`bin/dot-sync`](bin/dot-sync) con **backups automáticos previos** en `~/.dotfiles_backup/`.

---

## ⚡ Instalación Rápida (Quickstart)

Clona el repositorio en tu carpeta de repositorios:

```bash
mkdir -p ~/repos && cd ~/repos
git clone git@github.com:Joaquinfr87/dotfiles.git
cd dotfiles
```

### Opción A: Entorno de Escritorio Completo (Laptop / PC)

Instala paquetes del sistema, Sway, Noctalia v5, audio PipeWire, fuentes Iosevka, Kitty, Zen Browser y despliega las configuraciones:

```bash
./install.sh --desktop
```

### Opción B: Servidor Remoto / SSH (Headless)

Instala únicamente herramientas de línea de comandos, Neovim (LazyVim), Zsh, Tmux con persistencia, configuración de Git y CLIs modernas (zoxide, eza, bat):

```bash
./install.sh --server
```

### Opción C: Stack de Desarrollo & Agentes AI

Instala Node.js LTS, Docker Engine, Docker Compose, Lazydocker, OpenCode CLI, Freebuff, AGY y Codex:

```bash
./install.sh --dev-tools
```

### Opción D: Instalación Total (Escritorio + Dev Stack)

```bash
./install.sh --all
```

### Opción E: Menú Interactivo

Si ejecutas el script sin banderas, se abrirá el menú interactivo para que elijas entre todas las opciones:

```bash
./install.sh
```

---

## 🔄 Gestión y Sincronización con `dot-sync`

El comando [`bin/dot-sync`](bin/dot-sync) gestiona el ciclo de vida de tus configuraciones sin necesidad de GNU Stow:

| Comando | Acción |
| --- | --- |
| `dot-sync status` (o `dots status`) | Muestra el estado de sincronización entre el repo y tu sistema. |
| `dot-sync diff` (o `dots diff`) | Muestra las diferencias exactas de código entre el repo y tu sistema. |
| `dot-sync deploy` (o `dots deploy`) | **Repo ➔ Sistema:** Copia las configuraciones al sistema creando un **backup previo**. |
| `dot-sync save` (o `dots save`) | **Sistema ➔ Repo:** Copia las modificaciones que hiciste en tu sistema de vuelta al repo. |

### Flujo de trabajo habitual:
1. Modificas un archivo en tu editor (por ejemplo `~/.config/sway/config.d/04-bindings`).
2. Compruebas los cambios con: `dot-sync diff`
3. Guardas los cambios en el repositorio con: `dot-sync save`
4. Haces commit en Git: `git add . && git commit -m "feat: nuevo atajo" && git push`

---

## 📁 Estructura del Repositorio

```text
dotfiles/
├── bin/                          # Comandos auxiliares en tu $PATH
│   ├── dot-sync                  # Sincronizador bidireccional (con backup)
│   └── tmux-sessionizer          # Selector fzf de sesiones y proyectos para Tmux
├── git/                          # Configuración global de Git
│   ├── config                    # .gitconfig con aliases, delta y rebase
│   └── ignore                    # .gitignore global (.DS_Store, *.local, etc.)
├── install/                      # Scripts de instalación modulares e idempotentes
│   ├── 00-helpers.sh             # Funciones de log, colores y detección de distro
│   ├── 01-base-packages.sh       # Paquetes esenciales (git, curl, fzf, ripgrep, build-essential)
│   ├── 02-cli-tools.sh           # Neovim (bob/tarball), zoxide, eza, bat, lazygit, plugins tmux
│   ├── 03-shell.sh               # Zsh, Oh My Zsh, Powerlevel10k y plugins
│   ├── 04-desktop-packages.sh    # Sway, Wayland, PipeWire, Kanshi, portales
│   ├── 05-noctalia.sh            # Repositorio oficial y paquetes de Noctalia v5
│   ├── 06-fonts-wallpapers.sh    # Iosevka Nerd Font y Zen Browser
│   └── 07-copy-configs.sh        # Copiado con backup según el perfil (server/desktop)
├── kanshi/                       # Perfiles multi-monitor (laptop, presentación, externo)
├── kitty/                        # Terminal Kitty (tema Gruvbox Dark)
├── noctalia/                     # Noctalia v5 config.toml (barra, notificaciones, lockscreen)
├── noctalia-greeter/             # Configuración de greetd login manager
├── nvim/                         # Neovim (LazyVim, LSP, Blink, Obsidian, Gruvbox)
├── Pictures/                     # Fondos de pantalla
├── sway/                         # Sway tiling window manager (modular en config.d/)
├── tmux/                         # Tmux (persistencia con resurrect/continuum y sessionizer)
├── .gitignore                    # Exclusiones de Git (binarios .deb, backups, .freebuff)
├── .zprofile                     # Entorno de login (ejecuta sway solo en tty1 y si existe)
├── .zshrc                        # Shell interactivo rápido y portable
└── install.sh                    # Orquestador principal de instalación
```

---

## 🛠️ Componentes y Tecnologías

### Núcleo Terminal (Ambos perfiles: Desktop y Server)
* **Shell:** Zsh con Oh My Zsh, Powerlevel10k, zsh-autosuggestions y zsh-syntax-highlighting.
* **Editor:** Neovim (LazyVim) con soporte LSP, formateo con conform, completion con blink.cmp y notas en Obsidian.
* **Multiplexor:** Tmux con prefijo `C-Space`, persistencia de sesiones tras reinicio (`tmux-resurrect` + `tmux-continuum`), y navegación de proyectos con `tmux-sessionizer` (`prefix + f`).
* **Git:** `.gitconfig` profesional con aliases de alta frecuencia, rebase en pull, y soporte para visor de diffs `delta`.
* **Herramientas CLI:** `fzf`, `ripgrep`, `fd`, `zoxide`, `eza`, `bat`, `btop`, `lazygit`.

### Entorno Gráfico (Solo perfil Desktop)
* **Compositor:** Sway (Wayland) con configuración modular en `sway/config.d/`.
* **Shell UI:** Noctalia v5 (sustituye Waybar, Mako, Wofi, Swaylock, Swayidle y OSD de volumen/brillo en una sola herramienta eficiente vía IPC).
* **Terminal GUI:** Kitty con soporte de teclado extendido CSI-u (Shift+Enter nativo).
* **Gestión de Pantallas:** Kanshi con perfiles para `laptop`, `presentacion` y `externo`.
* **Navegador:** Zen Browser.

---

## ⌨️ Atajos de Teclado Clave (Sway)

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
| `Print` / `$mod+Print` | Captura de pantalla de región / pantalla completa |
| `$mod+Shift+q` | Cerrar ventana activa |
| `$mod+f` | Pantalla completa (Fullscreen) |
| `$mod+Shift+space` | Alternar ventana flotante / tiling |
| `$mod+1…0` | Cambiar de workspace |
| `$mod+Shift+1…0` | Mover ventana a workspace |
| `$mod+Shift+c` | Recargar configuración de Sway |

---

## 🔒 Variables y Personalizaciones Locales

Para mantener credenciales, tokens o rutas de trabajo privadas sin subirlas al repositorio público:
* **Shell:** Crea el archivo `~/.zshrc.local` (este archivo es leído automáticamente por `.zshrc` y está ignorado en Git).
* **Git:** Crea el archivo `~/.gitconfig.local` para configurar tu `user.name` y `user.email` privados por máquina:
  ```ini
  [user]
      name = Tu Nombre
      email = tu@correo.com
  ```

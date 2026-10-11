# Guía TMUX — Sesiones y ventanas

Configuración de [tmux](https://github.com/tmux/tmux) para el stack
**Debian 13 + kitty + sway + nvim**, enfocada en **sesiones** y en las
utilidades que traen (persistencia, detach/attach, ventanas, copy-mode). Los
**panes** (splits) se dejan con su comportamiento por defecto y no se usan.

> Basada en la wiki oficial: <https://github.com/tmux/tmux/wiki/Getting-Started>
> y `man tmux`. Paleta **Gruvbox Material Dark**, la misma de
> `sway/config.d/00-variables`.
>
> 📖 **¿Quieres aprender tmux a fondo?** La guía extensa (modelo mental,
> anatomía línea por línea de `tmux.conf`, referencia de comandos y recetas)
> está en **[`GUIA.md`](GUIA.md)**. Este README es el arranque rápido.

---

## 1. Qué es tmux (conceptos)

tmux es un **multiplexor de terminal**: ejecuta varios programas dentro de un
único terminal y permite **desconectarse** (detach) dejándolos corriendo, para
**volver a conectarse** (attach) después — desde la misma terminal, otra, o por
SSH.

Términos clave de la wiki:

| Término | Qué es |
|---|---|
| **Servidor** | Proceso en segundo plano que corre todo. Se inicia solo y muere si no queda nada dentro. |
| **Cliente** | Cada terminal conectada a una sesión (tu ventana de kitty). |
| **Sesión** | Agrupa ventanas. Tiene nombre único. Es la unidad de persistencia. |
| **Ventana** | Ocupa toda la terminal; agrupa uno o más panes. |
| **Pane** | Terminal dentro de una ventana (los splits). |
| **Prefijo** | Tecla que precede a los comandos de tmux. Aquí es **`C-Space`**. |

La jerarquía es: **sesión → ventanas → panes**. Como no usas panes, en la
práctica cada ventana es una terminal.

> **¿Por qué tmux y no las pestañas de kitty?** kitty ya sabe dividir ventanas y
> pestañas, e incluso su FAQ desaconseja los multiplexores. La diferencia real
> de tmux es la **persistencia**: `detach` deja los programas vivos, puedes
> reconectar tras cerrar kitty, reiniciar sway o reconectar por SSH. Usamos tmux
> por eso, no por los splits.

---

## 2. Instalación

```bash
sudo apt install tmux
tmux -V   # necesita >= 3.2 para la config de este repo (Debian 13 trae 3.5a)
```

La config usa `extended-keys`, `display-popup`, `copy-command` y `prefix2`, todos
disponibles desde tmux 3.2.

---

## 3. Instalar esta configuración

```bash
mkdir -p ~/.config/tmux
cp ~/repos/dotfiles/tmux/tmux.conf ~/.config/tmux/tmux.conf

mkdir -p ~/.local/bin
ln -sf ~/repos/dotfiles/tmux/scripts/tmux-sessionizer ~/.local/bin/tmux-sessionizer

# Persistencia de sesiones (ver §9)
mkdir -p ~/.config/tmux/plugins
git clone --depth 1 https://github.com/tmux-plugins/tmux-resurrect \
  ~/.config/tmux/plugins/tmux-resurrect
git clone --depth 1 https://github.com/tmux-plugins/tmux-continuum \
  ~/.config/tmux/plugins/tmux-continuum
```

tmux lee `~/.config/tmux/tmux.conf` automáticamente (soporte XDG desde tmux 3.1),
así que no hace falta tocar `~/.tmux.conf`. El enlace del sessionizer en
`~/.local/bin` es el mismo patrón que usas para `zen`. Los plugins de
persistencia van fuera del repo (son de terceros); para actualizarlos,
`git -C <carpeta> pull`.

Verificar que no hay errores de sintaxis:

```bash
tmux -L test -f ~/.config/tmux/tmux.conf new-session -d -s ok && tmux -L test kill-server
```

---

## 4. Integración con kitty

La config ya trae lo necesario; esto es para entender el porqué:

- **Color de 24 bits** — kitty se identifica como `TERM=xterm-kitty`. La línea
  `set -as terminal-features ',xterm-kitty*:RGB:extkeys'` le dice a tmux que esa
  terminal soporta **RGB** (color real), de modo que el tema de nvim se vea igual
  que en kitty (sin colores apagados).
- **Teclado extendido CSI-u** — tmux **no** implementa el protocolo de teclado de
  kitty completo, pero sí reenvía secuencias `CSI-u`:
  ```
  set -g extended-keys always
  set -g extended-keys-format csi-u
  set -as terminal-features ',xterm-kitty*:RGB:extkeys'
  ```
  Con esto funcionan teclas como `Shift+Enter` en nvim y en CLIs que lo usan.
- **`escape-time 0`** — sin esto, `Esc` se siente lento en nvim dentro de tmux.
- **`allow-passthrough on`** — deja pasar secuencias OSC (p. ej. `kitten icat`)
  a través de tmux.

> **Scrollback:** el `scrollback_pager nvim` de `kitty/kitty.conf` aplica al
> scrollback **de kitty** (fuera de tmux). Dentro de tmux el scrollback es el de
> tmux y se navega con **copy-mode** (ver §7).

---

## 5. Integración con sway

Añadido a `sway/config.d/`:

```
# 00-variables
set $sessionizer ~/.local/bin/tmux-sessionizer

# 04-bindings
bindsym $mod+Shift+Return exec $term -e $sessionizer
```

- **`$mod+Shift+Return`** abre kitty y lanza el **sessionizer** (selector de
  sesiones con fzf). `$mod+Return` sigue abriendo una terminal normal.
- Las sesiones de tmux viven en el **servidor** de tmux, que es independiente de
  sway: puedes **recargar o reiniciar sway** (`$mod+Shift+c` / relogin) y las
  sesiones siguen vivas. Vuelves con `prefix + s` o `tmux attach`.

---

## 6. Integración con nvim

No hace falta ningún plugin ni cambio en nvim: nvim corre dentro de una ventana
de tmux como en cualquier terminal. Dos detalles ya resueltos:

- **`focus-events on`** — nvim recibe `FocusGained`/`FocusLost`, útil para
  `autoread`, autoguardado al perder foco, etc.
- **`escape-time 0`** + **CSI-u** — sin retardo en `Esc` y con `Shift+Enter`.

> Si algún día empiezas a usar panes y quieres moverte entre nvim y tmux con las
> mismas teclas, ese es el caso de `vim-tmux-navigator`. Como no usas panes, no
> se instala.

---

## 7. Uso: sesiones (lo esencial)

### Desde el shell

| Comando | Qué hace |
|---|---|
| `tmux` / `tmux new` | Nueva sesión (la primera arranca el servidor) |
| `tmux new -As trabajo` | Crea la sesión `trabajo` o se conecta si ya existe |
| `tmux ls` | Lista sesiones |
| `tmux attach` | Se conecta a la última sesión usada |
| `tmux attach -t trabajo` | Se conecta a `trabajo` |
| `tmux kill-session -t trabajo` | Mata la sesión `trabajo` |
| `tmux kill-server` | Mata tmux entero |

### Con el prefijo (`C-Space`, o `C-b` como secundario)

| Atajo | Acción |
|---|---|
| `C-Space d` | **Detach**: cierra el cliente, la sesión sigue viva |
| `C-Space s` | **Tree mode**: ver/​elegir sesiones (y ventanas) |
| `C-Space w` | Tree mode con ventanas expandidas |
| `C-Space $` | Renombrar sesión |
| `C-Space X` | Matar la sesión actual (con confirmación) |
| `C-Space (` / `)` | Sesión anterior / siguiente |
| `C-Space C-p` / `C-n` | Igual, pero **repetible** sin re-pulsar el prefijo |
| `C-Space D` | Detach de otros clientes conectados a la misma sesión |

El flujo típico: abres una sesión por proyecto, trabajas, `C-Space d` y la
dejas corriendo. Al volver, `tmux attach` (o el sessionizer) y sigues donde
estabas.

### Ventanas (dentro de una sesión)

| Atajo | Acción |
|---|---|
| `C-Space c` | Nueva ventana |
| `C-Space n` / `p` | Siguiente / anterior |
| `C-Space 1` … `9` | Ir a la ventana N (numeradas desde 1) |
| `C-Space l` | Última ventana |
| `C-Space ,` | Renombrar ventana |
| `C-Space &` | Cerrar ventana |

### Copiar/pegar y scrollback

La rueda del mouse entra en copy-mode automáticamente (`mouse on`). También
`Alt+↑` / `Alt+↓` para paginar.

| Atajo | Acción |
|---|---|
| `C-Space [` | Entrar a copy-mode (teclas vi) |
| `Alt+↑` / `Alt+↓` | Subir / bajar página (entra a copy-mode) |
| `v` … `y` | En copy-mode: seleccionar (`v`) y **copiar al portapapeles** (`y` → `wl-copy`) |
| `C-Space ]` | Pegar el último buffer |
| `C-Space =` | Elegir buffer (historial de copias) |

El `y` envía la selección a `wl-copy` (portapapeles de Wayland), así que lo
pegado está disponible en todo sway, no solo dentro de tmux.

### Utilidades

| Atajo | Acción |
|---|---|
| `C-Space ?` | Lista de todos los atajos con su descripción |
| `C-Space :` | Prompt de comandos de tmux (p. ej. `:kill-server`) |
| `C-Space r` | **Recargar `tmux.conf`** |
| `C-Space f` | Abrir el **sessionizer** en un popup (fzf) |
| `C-Space t` | Reloj en la ventana |

---

## 8. Sessionizer (fzf)

`tmux/scripts/tmux-sessionizer` abre un menú **fzf** con tres
modos y crea/entra a una **sesión de tmux por proyecto** (el
nombre es el del directorio):

- **`ctrl-s`: sesiones de tmux existentes** (por defecto; muestra
  nombre y ruta). Elegir una **cambia a ella**.
- **`ctrl-t`: proyectos** — primer nivel de `~/repos`,
  `~/Downloads` y las rutas de
  `~/.config/tmux/sessionizer.dirs`.
- **`ctrl-a`: todo `$HOME`** (hasta 5 niveles de profundidad).

Elegir una carpeta crea la sesión si no existe; si ya existe,
solo cambia a ella (no reinicia nada).

- Desde **sway**: `$mod+Shift+Return`.
- Desde **dentro de tmux**: `C-Space f` (popup).
- Desde el **shell**: alias `ts`.

Para que aparezcan carpetas que **no** están en `~/repos` ni
`~/Downloads`, añade su ruta (una por línea) a
`~/.config/tmux/sessionizer.dirs`:

```bash
echo '~/mis-proyectos' >> ~/.config/tmux/sessionizer.dirs
```

Valen `~`, comentarios `#` y líneas en blanco. (Equivalente: edita
`search_dirs` al inicio del script.)

---

## 9. Persistencia de sesiones (resurrect + continuum)

Las sesiones **sobreviven a reinicios y apagados** con
[tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect) y
[tmux-continuum](https://github.com/tmux-plugins/tmux-continuum)
(clonados en `~/.config/tmux/plugins/` y cargados al final de
`tmux.conf`):

- **Guardado:** automático cada 10 min (continuum) o manual con
  `C-Space C-s`.
- **Restauración:** automática al arrancar el servidor tmux; `C-Space C-r`
  la fuerza a mano.
- Se guardan sesiones, ventanas, panes, **directorios de trabajo** y el
  **contenido de los panes** en `~/.local/share/tmux/resurrect/`.

Notas:

- La restauración automática ocurre cuando **arranca el servidor**
  (al crear/adjuntar la primera sesión tras el arranque).
- El guardado es una **foto de todo el servidor**: sesiones que no
  quieras recuperar, mátalas antes del siguiente guardado
  (`C-Space X`).
- Si un directorio guardado ya no existe (p. ej. un disco no
  montado), el pane arranca en `$HOME`.

---

## 10. Aliases de zsh

Añadidos a `.zshrc`:

| Alias | Equivale a |
|---|---|
| `ta <sesión>` | `tmux attach -t <sesión>` |
| `tn <sesión>` | `tmux new -As <sesión>` (crear o adjuntar) |
| `tls` | `tmux ls` |
| `tk <sesión>` | `tmux kill-session -t <sesión>` |
| `ts` | `tmux-sessionizer` |

Tras copiar el `.zshrc`, aplica con `source ~/.zshrc` o abre una shell nueva.

---

## 11. Estructura de archivos

```
~/repos/dotfiles/tmux/
├── tmux.conf                   # se instala en ~/.config/tmux/tmux.conf
├── README.md                   # esta guía
└── scripts/
    └── tmux-sessionizer        # enlazado en ~/.local/bin/
```

---

## 12. Decisiones de la config (referencia)

- **Prefijo `C-Space`** (antes `C-b`), con `C-b` mantenido como `prefix2` por
  compatibilidad. `C-Space` no choca con `C-b`/`C-a` de readline ni con kitty.
- **`base-index 1`** — ventanas desde 1 (como tus workspaces de sway).
- **`renumber-windows on`** — sin huecos al cerrar ventanas.
- **`detach-on-destroy off`** — al matar una sesión salta a otra en vez de
  cerrarse todo.
- **`mode-keys vi` / `status-keys vi`** — coherente con nvim.
- **`set-clipboard on` + `copy-command wl-copy`** — integración con el
  portapapeles de Wayland.
- **Sin atajos de split** — los panes no se usan; `%` y `"` siguen existiendo por
  si algún día hacen falta, pero no se promueven.

---

## 13. Primeros pasos

```bash
# 1. Instala la config (ver §3) y abre una sesión de prueba
tmux new -As prueba

# 2. Prueba: C-Space c (nueva ventana), C-Space 1/2, C-Space , (renombrar)
# 3. Detach y reattach
#    C-Space d   (vuelves al shell, tmux sigue vivo)
tmux ls         # la sesión 'prueba' sigue listada
tmux attach -t prueba

# 4. Sessionizer
#    C-Space f  o  ts  o  $mod+Shift+Return en sway

# 5. Limpieza
tmux kill-session -t prueba
```

---

## 14. Referencia

- Getting Started (wiki oficial): <https://github.com/tmux/tmux/wiki/Getting-Started>
- Manual: `man 1 tmux` · <https://man.openbsd.org/tmux>
- FAQ (problemas de config): <https://github.com/tmux/tmux/wiki/FAQ>
- kitty + teclado extendido: <https://sw.kovidgoyal.net/kitty/keyboard-protocol/>
- kitty FAQ (opinión sobre multiplexores): <https://sw.kovidgoyal.net/kitty/faq/>

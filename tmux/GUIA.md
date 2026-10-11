# Guía completa de TMUX — aprender y usar

Guía extensa para **aprender tmux desde cero** y para entender **toda la
configuración** de este repo (`tmux/tmux.conf`), pensada para el stack
**Debian 13 + kitty + sway + nvim + zsh**.

> Enfoque del repo: **sesiones** y **utilidades**. Los panes (splits) se
> explican aquí para que sepas que existen, pero la config no los promueve.
>
> Fuentes: wiki oficial <https://github.com/tmux/tmux/wiki/Getting-Started>,
> `man tmux` (probado con tmux **3.5a**) y pruebas directas sobre esa versión.

---

## Índice

1. [Qué es tmux y por qué usarlo](#1-qué-es-tmux-y-por-qué-usarlo)
2. [Modelo mental: servidor, sesión, ventana, pane](#2-modelo-mental-servidor-sesión-ventana-pane)
3. [Instalación y primer arranque](#3-instalación-y-primer-arranque)
4. [Dónde vive la configuración y cómo se carga](#4-dónde-vive-la-configuración-y-cómo-se-carga)
5. [Anatomía de `tmux.conf`, bloque por bloque](#5-anatomía-de-tmuxconf-bloque-por-bloque)
6. [Aprender tmux por niveles](#6-aprender-tmux-por-niveles)
7. [Referencia de comandos](#7-referencia-de-comandos)
8. [Chuleta de atajos (prefijo `C-Space`)](#8-chuleta-de-atajos-prefijo-c-space)
9. [Copy-mode, buffers y portapapeles](#9-copy-mode-buffers-y-portapapeles)
10. [El prompt de comandos y las secuencias](#10-el-prompt-de-comandos-y-las-secuencias)
11. [Objetivos (`-t`): apuntar a sesiones, ventanas y panes](#11-objetivos--t-apuntar-a-sesiones-ventanas-y-panes)
12. [Opciones comunes de tmux](#12-opciones-comunes-de-tmux)
13. [Integraciones: kitty, sway, nvim, zsh](#13-integraciones-kitty-sway-nvim-zsh)
14. [El sessionizer explicado](#14-el-sessionizer-explicado)
15. [Solución de problemas](#15-solución-de-problemas)
16. [Recetas y patrones de uso](#16-recetas-y-patrones-de-uso)
17. [Referencia](#17-referencia)

---

## 1. Qué es tmux y por qué usarlo

**tmux** es un **multiplexor de terminal**: un programa que se ejecuta dentro de
tu terminal (kitty) y dentro del cual corren otros programas, cada uno con su
propio terminal virtual gestionado por tmux.

Lo que aporta:

- **Persistencia (detach/attach).** Puedes *soltar* (detach) la sesión y los
  programas siguen corriendo en segundo plano. Al *engancharte* (attach) de
  nuevo, todo sigue donde lo dejaste. Cierras kitty, recargas sway, reconectas
  por SSH… y sigues igual.
- **Sesiones por contexto.** Una sesión por proyecto. Cambiar de proyecto es
  cambiar de sesión, sin cerradas ni procesos perdidos.
- **Ventanas.** Varias terminales dentro de la misma sesión, como pestañas.
- **Automatización.** Todo se controla por comandos, así que se puede scriptear.

### Cuándo NO usar tmux

kitty ya tiene pestañas y splits propios, y su FAQ incluso desaconseja los
multiplexores para uso puramente local. La razón para usar tmux aquí **no** es
dividir la pantalla, sino la **persistencia**: dejar procesos vivos entre
reinicios de terminal/compositor y trabajar cómodo por SSH. Si solo quisieras
splits locales, con kitty bastaría.

---

## 2. Modelo mental: servidor, sesión, ventana, pane

tmux tiene cuatro conceptos. Entenderlos es el 80% de aprenderlo.

```
                       ┌───────────────────────────────────────────┐
   kitty (cliente 1)   │  tmux SERVIDOR  (proceso en segundo plano) │
   ───────────────────▶│                                            │
                       │   SESIÓN "trabajo"                         │
   kitty (cliente 2)   │   ├── VENTANA 1  (una terminal: nvim)      │
   ───────────────────▶│   ├── VENTANA 2  (una terminal: shell)     │
                       │   └── VENTANA 3  ┌────────┬────────┐       │
                       │                  │ PANE 0 │ PANE 1 │       │
                       │                  └────────┴────────┘       │
                       └───────────────────────────────────────────┘
```

- **Servidor.** Un único proceso en segundo plano. Guarda *todo* el estado
  (sesiones, ventanas, panes, programas). Arranca solo la primera vez y muere
  cuando no queda nada dentro.
- **Cliente.** Cada terminal conectada a una sesión (p. ej. tu ventana de
  kitty). Se comunica con el servidor por un **socket** en `/tmp` (o
  `$TMUX_TMPDIR`).
- **Sesión.** Agrupa ventanas. Tiene **nombre único** (por defecto `0`, `1`, …).
  Es la unidad que se *detach*/*attach*. No tiene índice.
- **Ventana.** Ocupa toda la terminal conectada. Tiene **nombre** (por defecto el
  del programa) e **índice** dentro de su sesión (`1`, `2`, … con nuestra
  config). Cada sesión tiene una *ventana actual*.
- **Pane.** Una terminal dentro de una ventana; los splits viven aquí. Cada
  ventana tiene un *pane activo*.

**Puntos clave:**

- Una sesión puede estar **attached** (visible en una o más terminales) o
  **detached** (sin cliente, sigue viva).
- Las ventanas se identifican por **sesión + índice**.
- `attach` no desconecta otros clientes salvo que uses `-d`.

Notación de atajos: `C-` = Ctrl, `M-` = Meta (Alt), `S-` = Shift.
`C-Space c` significa: prefijo `C-Space`, soltar, y luego `c`.

---

## 3. Instalación y primer arranque

```bash
sudo apt install tmux
tmux -V                # Debian 13 trae 3.5a; la config pide >= 3.2
```

Primer arranque (crea el servidor y la primera sesión, y te conecta):

```bash
tmux                   # equivale a: tmux new-session
```

Para salir dejando todo vivo, **detach**: `C-Space` seguido de `d`.
Para reconectar:

```bash
tmux attach            # a la última sesión usada
```

> Si prefieres empezar con la config de este repo antes de trastear, ve a §4.

---

## 4. Dónde vive la configuración y cómo se carga

tmux lee **un** archivo de configuración al arrancar el servidor. Rutas posibles:

| Ruta | Notas |
| --- | --- |
| `~/.config/tmux/tmux.conf` | Soporte XDG. **Es la que usa este repo.** |
| `~/.tmux.conf` | Ubicación clásica. |

**Precedencia (verificado en tmux 3.5a):** si existen las dos,
**gana `~/.config/tmux/tmux.conf`**. Por eso el repo instala ahí y puedes dejar
`~/.tmux.conf` libre sin miedo.

Instalación de esta config:

```bash
mkdir -p ~/.config/tmux
cp ~/repos/dotfiles/tmux/tmux.conf ~/.config/tmux/tmux.conf

mkdir -p ~/.local/bin
ln -sf ~/repos/dotfiles/tmux/scripts/tmux-sessionizer ~/.local/bin/tmux-sessionizer
```

**Cargar cambios:**

- Con un servidor corriendo NO se recarga sola. Fuerza la recarga con
  **`C-Space r`** (bind propio) o desde el prompt `C-Space :` → `:source-file ~/.config/tmux/tmux.conf`.
- Si no hay servidor, la próxima vez que arranques se lee sola.

Comprobar que carga sin errores:

```bash
tmux -L test -f ~/.config/tmux/tmux.conf new-session -d -s ok && tmux -L test kill-server
```

---

## 5. Anatomía de `tmux.conf`, bloque por bloque

### 5.1 Sintaxis de los comandos de config

Un `tmux.conf` es una lista de **comandos de tmux** (los mismos del prompt `:`)
sin el `tmux` delante. Los que usamos:

| Forma | Significado |
| --- | --- |
| `set -g opción valor` | Opción **global de sesión** (todas las sesiones nuevas). |
| `set -s opción valor` | Opción de **servidor** (afecta a todo el servidor). |
| `setw -g opción valor` | Opción de **ventana** (global). `setw` = `set-window-option`. |
| `set -as opción valor` | **Añadir** (`-a`) a una opción de lista (no reemplaza). |
| `bind tecla comando` | Ata un atajo en la tabla **prefix**. |
| `bind -n tecla comando` | Ata un atajo **sin prefijo** (tabla *root*). |
| `bind -T tabla tecla cmd` | Ata en otra tabla (`copy-mode-vi`, etc.). |
| `bind -r tecla comando` | Permite **repetir** sin re-pulsar el prefijo. |
| `unbind tecla` | Quita un atajo. |

> Varias opciones de este archivo (`extended-keys`, `set-clipboard`,
> `allow-passthrough`, `escape-time`…) son de servidor; tmux las acepta y quedan
> activas (verificado: la config carga con exit 0 y los valores son los
> esperados). Usamos `-g` por uniformidad.

### 5.2 Bloque: terminal (integración con kitty)

```tmux
set -g default-terminal "tmux-256color"
set -g extended-keys always
set -g extended-keys-format csi-u
set -as terminal-features ',xterm-kitty*:RGB:extkeys'
set -g allow-passthrough on
```

- **`default-terminal "tmux-256color"`** — valor de `TERM` para los programas
  dentro de tmux. `tmux-256color` es la entrada terminfo recomendada por tmux
  (trae las capacidades extra de tmux: estilos, etc.).
- **`extended-keys always`** + **`extended-keys-format csi-u`** — pide al
  terminal de fuera las **teclas extendidas** en formato **CSI-u** y las reenvía
  a las apps. Es lo que hace que `Shift+Enter` funcione en nvim y CLIs.
- **`terminal-features ',xterm-kitty*:RGB:extkeys'`** — anuncia que la terminal
  externa (`xterm-kitty`) soporta **RGB** (color de 24 bits) y **extkeys**. El
  `-a` *añade* a la lista por defecto (el `,` inicial es el separador).
- **`allow-passthrough on`** — deja pasar secuencias **OSC** de la app al
  terminal externo (imágenes de `kitten icat`, portapapeles OSC 52, etc.).

### 5.3 Bloque: comportamiento general

```tmux
set -sg escape-time 0
set -g focus-events on
set -g mouse on
set -g history-limit 50000
set -g base-index 1
setw -g pane-base-index 1
setw -g automatic-rename on
set -g renumber-windows on
setw -g aggressive-resize on
set -g detach-on-destroy off
set -g set-clipboard on
```

- **`escape-time 0`** — tiempo que tmux espera para decidir si una tecla es una
  secuencia de escape. Sin esto, `Esc` se siente lento **dentro de nvim**. `-s`
  = opción de servidor.
- **`focus-events on`** — reenvía eventos de foco a las apps; nvim los usa
  (`autoread`, acciones al ganar/perder foco).
- **`mouse on`** — rueda entra en copy-mode, arrastrar selecciona, clic activa
  ventanas/panes.
- **`history-limit 50000`** — líneas de scrollback por pane en memoria.
- **`base-index 1`** — ventanas numeradas desde **1** (como tus workspaces de
  sway), no desde 0.
- **`pane-base-index 1`** — los panes también desde 1.
- **`automatic-rename on`** — la ventana toma el nombre del programa activo.
- **`renumber-windows on`** — al cerrar una ventana **no quedan huecos**
  (`1,3` → `1,2`).
- **`aggressive-resize on`** — la ventana se redimensiona según su propio
  tamaño, no según la sesión más grande.
- **`detach-on-destroy off`** — al matar la sesión actual, **salta** a otra en vez
  de cerrar tmux entero. Cómodo para no perder el hilo.
- **`set-clipboard on`** — permite que las apps pongan texto en el portapapeles
  vía OSC 52 y que tmux sincronice con el sistema.

### 5.4 Bloque: estilo vi

```tmux
setw -g mode-keys vi
set -g status-keys vi
```

- **`mode-keys vi`** — navegación tipo **vi** en copy-mode (coherente con nvim).
- **`status-keys vi`** — atajos tipo vi en el prompt de comandos (`C-Space :`).

### 5.5 Bloque: prefijo

```tmux
set -g prefix C-Space
set -g prefix2 C-b
bind C-Space send-prefix
```

- **`prefix C-Space`** — el prefijo pasa de `C-b` a **`C-Space`**. No choca con
  `C-b` (screen/readline) ni con `C-a` (inicio de línea), y es cómodo.
- **`prefix2 C-b`** — mantiene `C-b` como **segundo prefijo**, por si lo usas.
- **`bind C-Space send-prefix`** — pulsar el prefijo **dos veces** envía
  `C-Space` a la app de dentro (por ejemplo, para pasar `C-Space` a un programa).

### 5.6 Bloque: portapapeles Wayland

```tmux
set -s copy-command 'wl-copy'
bind -T copy-mode-vi v send-keys -X begin-selection
bind -T copy-mode-vi y send-keys -X copy-selection-and-cancel
bind -T copy-mode-vi C-v send-keys -X rectangle-toggle
```

- **`copy-command 'wl-copy'`** — hace que copiar dentro de tmux use
  **`wl-copy`** (portapapeles de Wayland), así lo copiado está disponible en todo
  sway. Requiere `wl-clipboard` (ya lo instalas; ver README raíz §8).
- **`v`** — en copy-mode, inicia la **selección** (como en vim; tb. `Space`).
- **`y`** — **copia** la selección y sale de copy-mode (a `wl-copy`).
- **`C-v`** — selección **rectangular** (por columnas).

> Nota real: por defecto tmux ata `v` a `rectangle-toggle`. Este repo lo
> reasigna a *iniciar selección* para que sea 100% vim-like; la selección
> rectangular pasa a `C-v`.

### 5.7 Bloque: utilidades propias

```tmux
bind r source-file ~/.config/tmux/tmux.conf \; display-message "tmux.conf recargado"
bind X confirm-before -p "matar sesión #S? (y/n)" kill-session
bind f display-popup -E -w 80% -h 60% "~/.local/bin/tmux-sessionizer"
```

- **`r`** — **recarga** la config sin reiniciar tmux. El `\;` encadena un segundo
  comando (mostrar un mensaje). Es un *command sequence*.
- **`X`** — **mata la sesión** actual pidiendo confirmación (`#S` = nombre de la
  sesión).
- **`f`** — abre el **sessionizer** en un **popup** (`display-popup`) al 80%×60%.

### 5.8 Bloque: scrollback y sesiones rápidas

```tmux
bind -n M-Up   copy-mode \; send-keys -X page-up
bind -n M-Down copy-mode \; send-keys -X page-down
bind -T copy-mode M-Up   send-keys -X page-up
bind -T copy-mode M-Down send-keys -X page-down

bind -r C-n switch-client -n
bind -r C-p switch-client -p
```

- **`M-Up`/`M-Down` (sin prefijo)** — entran a copy-mode y **suben/bajan una
  página**, sin depender de `PageUp`/`PageDown` (cómodo en teclados compactos y
  laptops). Como no hay `Ctrl` de por medio, funcionan también **dentro de nvim**:
  si algún día quieres que nvim reciba `Alt+↑`, hay que quitar estos binds.
- **`C-n`/`C-p` (con prefijo, `-r`)** — **siguiente/anterior sesión**,
  repetible sin volver a pulsar el prefijo.

### 5.9 Bloque: barra de estado (Gruvbox Material)

```tmux
set -g status-interval 5
set -g status-style "bg=#282828,fg=#a89984"
set -g status-left  "#[bg=#b8bb26,fg=#282828,bold] #S #[bg=#3c3836,fg=#b8bb26,nobold] "
set -g status-right "#[fg=#928374]%d/%m #[fg=#83a598]%H:%M "
setw -g window-status-format " #I:#W "
setw -g window-status-current-format "#[bg=#3c3836,fg=#fabd2f,bold] #I:#W "
...
```

- **`status-interval 5`** — se refresca cada 5 s (reloj, contadores).
- **`status-left`** — a la izquierda: nombre de la **sesión** (`#S`).
- **`status-right`** — a la derecha: fecha y hora (`%d/%m %H:%M`).
- **`window-status-format`** — cómo se muestra cada ventana: `#I:#W` =
  **índice:nombre**.
- **`window-status-current-format`** — la ventana activa, resaltada en amarillo.
- Colores con la paleta Gruvbox Material (`#282828` fondo, `#b8bb26` verde,
  `#fabd2f` amarillo, `#a89984` gris, etc.). Los `#[...]` son **estilos
  inline**; `#I`, `#W`, `#S` son **variables** de tmux.

---

## 6. Aprender tmux por niveles

Ve en orden. Cada nivel añade una herramienta nueva.

### Nivel 1 — Sesiones mínimas

```bash
tmux new -s trabajo     # crea la sesión "trabajo" y te conecta
# ...trabajas...
# C-Space d             # detach: la sesión sigue viva
tmux ls                 # lista sesiones
tmux attach -t trabajo  # vuelve a entrar
```

Aprendido: `new`, `attach`, `ls`, detach con `d`.

### Nivel 2 — Ventanas (varias terminales en una sesión)

Dentro de la sesión:

- `C-Space c` → nueva ventana.
- `C-Space 1` … `9` → ir a la ventana N.
- `C-Space n` / `p` → siguiente / anterior.
- `C-Space ,` → renombrar.
- `C-Space &` → cerrar (confirma).

### Nivel 3 — Persistencia real (el punto de tmux)

1. Abre una sesión, lanza algo largo (p. ej. `sleep 300 &` o un `cargo build`).
2. `C-Space d` (detach) y **cierra kitty**.
3. Abre kitty, `tmux attach`. El proceso sigue allí.
4. Repite pero **recarga sway** (`$mod+Shift+c`) o cierra sesión y vuelve: sigue.

Esto demuestra por qué tmux es útil aunque kitty ya divida ventanas.

### Nivel 4 — Copy-mode y portapapeles

- Rueda del mouse o `Alt+↑` → entras a copy-mode.
- `v` inicia selección, `y` copia (a `wl-copy`), `q` sale.
- `C-Space ]` pega el último buffer.
- `C-Space =` abre la lista de buffers (historial de copias).

### Nivel 5 — Árbol, clientes y buffers

- `C-Space s` → **tree mode**: ver y saltar entre sesiones/ventanas; `Enter`
  elige; `x` mata; `q` sale.
- `C-Space w` → tree mode con ventanas expandidas.
- `C-Space D` → **client mode**: lista de terminales conectadas; `Enter` detach.
- `C-Space =` → **buffer mode**.

### Nivel 6 — Configurar y automatizar

- `C-Space :` → prompt de comandos (`:set -g mouse off` para probar en vivo).
- `C-Space r` → recarga tras editar `tmux.conf`.
- Escribe tus propios `bind`/`set` (ver §5, §12).
- Usa el sessionizer (`C-Space f`) para no escribir nombres de sesión.

---

## 7. Referencia de comandos

Todos los comandos tienen **alias**. Desde el shell se llaman con `tmux` delante;
en el prompt `:` sin él.

### Sesiones

| Comando | Alias | Qué hace |
| --- | --- | --- |
| `new-session` | `new` | Nueva sesión. |
| `attach-session` | `attach` | Conectar a una sesión. |
| `list-sessions` | `ls` | Listar sesiones. |
| `kill-session` | — | Matar una sesión (y todo lo suyo). |
| `rename-session` | — | Renombrar la sesión actual. |
| `switch-client` | — | Cambiar el cliente a otra sesión (usado por `C-n`/`C-p`). |
| `has-session` | — | ¿Existe la sesión? (útil en scripts). |

Flags útiles: `-s nombre`, `-t objetivo`, `-d` (crear sin conectar),
`-A` (conectar si existe, si no crear), `-D` (al conectar, detacha a otros),
`-c dir` (directorio de arranque).

Ejemplos:

```bash
tmux new -As trabajo          # crea "trabajo" o se conecta si ya está
tmux new -d -s build -c ~/repos/app   # sesión "build" en segundo plano
tmux attach -dt trabajo       # conectar y echar a otros clientes
tmux kill-session -t build
```

### Ventanas

| Comando | Alias | Qué hace |
| --- | --- | --- |
| `new-window` | `neww` | Nueva ventana. |
| `select-window` | — | Ir a una ventana. |
| `next-window` / `previous-window` | — | Siguiente / anterior. |
| `rename-window` | — | Renombrar. |
| `kill-window` | — | Cerrar. |
| `last-window` | — | Ventana anterior. |
| `move-window` | `movew` | Mover a otro índice (`-r` para renumerar). |
| `swap-window` | — | Intercambiar con la marcada. |

`neww -n editor nvim` → nueva ventana llamada `editor` corriendo nvim.

### Panes (para saber que existen)

| Comando | Alias | Qué hace |
| --- | --- | --- |
| `split-window` | `splitw` | Dividir (`-h` horizontal, `-v` vertical). |
| `select-pane` | — | Cambiar de pane. |
| `resize-pane` | — | Redimensionar. |
| `kill-pane` | — | Cerrar pane. |
| `break-pane` | — | Sacar un pane a su propia ventana. |
| `display-panes` | — | Mostrar números de pane. |

> Estos atajos **siguen existiendo** (`C-Space %`, `C-Space "`, `C-Space z` para
> zoom…) pero no los usamos. Los *floating panes* de la wiki llegan en **tmux
> 3.8**, que no está en Debian 13; no hacen falta aquí.

### Clientes y servidor

| Comando | Alias | Qué hace |
| --- | --- | --- |
| `list-clients` | `lsc` | Ver terminales conectadas. |
| `detach-client` | `detach` | Desconectar cliente(s). |
| `choose-client` | — | client mode (`C-Space D`). |
| `kill-server` | — | Matar tmux entero. |
| `source-file` | — | Recargar config. |
| `list-keys` | `lsk` | Ver atajos (`lsk -N` con descripciones). |
| `display-message` | `display` | Mostrar un mensaje en la barra. |

```bash
tmux lsk -N | less            # todos los atajos con descripción (equivale a C-Space ?)
tmux list-windows -t trabajo  # ventanas de una sesión
tmux kill-server              # cierra TODO (con cuidado)
```

---

## 8. Chuleta de atajos (prefijo `C-Space`)

> Funciona también `C-b` (prefix2).

**Sesiones**

| Atajo | Acción |
| --- | --- |
| `d` | Detach (deja la sesión viva) |
| `s` | Tree mode de sesiones |
| `(` / `)` | Sesión anterior / siguiente |
| `C-p` / `C-n` | Igual, repetible sin re-pulsar prefijo |
| `$` | Renombrar sesión |
| `X` | Matar sesión (confirma) |
| `D` | Detach de otros clientes |

**Ventanas**

| Atajo | Acción |
| --- | --- |
| `c` | Nueva ventana |
| `n` / `p` | Siguiente / anterior |
| `1`…`9` | Ir a la ventana N |
| `l` | Última ventana |
| `,` | Renombrar ventana |
| `&` | Cerrar ventana |
| `w` | Tree mode con ventanas |

**Copy-mode / portapapeles**

| Atajo | Acción |
| --- | --- |
| `[` | Entrar a copy-mode |
| `Alt+↑` / `Alt+↓` | Página arriba / abajo (entra a copy-mode) |
| `v` / `Space` | Iniciar selección |
| `y` / `Enter` | Copiar y salir (→ `wl-copy`) |
| `C-v` | Selección rectangular |
| `]` | Pegar último buffer |
| `=` | Lista de buffers |

**Utilidades**

| Atajo | Acción |
| --- | --- |
| `?` | Lista de atajos con descripción |
| `:` | Prompt de comandos |
| `r` | Recargar `tmux.conf` |
| `f` | Sessionizer (popup fzf) |
| `t` | Reloj |

**Sistema (siguen los defaults de tmux)**

| Atajo | Acción |
| --- | --- |
| `%` / `"` | Split horizontal / vertical |
| `z` | Zoom del pane |
| `Space` | Rotar layouts |
| `q` | Mostrar números de pane |

---

## 9. Copy-mode, buffers y portapapeles

**Copy-mode** congela la salida de un pane para poder navegar y copiar.
Se entra con `C-Space [` o con la rueda del mouse.

**Teclas vi dentro de copy-mode:**

| Tecla | Acción |
| --- | --- |
| `h j k l` | Mover (arriba/abajo/izq/der) |
| `w` / `b` | Palabra siguiente / anterior |
| `0` / `$` | Inicio / fin de línea |
| `C-u` / `C-d` | Media página arriba / abajo |
| `g` / `G` | Inicio / fin del historial |
| `/` / `?` | Buscar hacia adelante / atrás |
| `n` / `N` | Siguiente / anterior resultado |
| `v` / `Space` | Iniciar selección |
| `V` | Seleccionar línea |
| `C-v` | Selección rectangular |
| `y` / `Enter` | Copiar y salir |
| `q` | Salir sin copiar |

**Buffers.** Un texto copiado es un *paste buffer*.

- Automáticos (`buffer0`…) — se guardan hasta 50; el más viejo se descarta.
- Con nombre — no se borran nunca.
- `C-Space =` abre **buffer mode** (lista + previsualización).
- Comandos: `set-buffer` (`setb`), `load-buffer` (`loadb`), `save-buffer`
  (`saveb`).

**Portapapeles del sistema.** Con `copy-command 'wl-copy'`, copiar dentro de tmux
va al portapapeles de Wayland. Así puedes pegar en cualquier app de sway.

---

## 10. El prompt de comandos y las secuencias

`C-Space :` abre un **prompt** (aparece sobre la barra de estado) donde escribes
comandos de tmux como en el shell; con `status-keys vi` puedes editarlo como en
vim.

- **Comandos encadenados (command sequence):** sepáralos con `;` **en la config**,
  o con `\;` dentro de un `bind`:

  ```tmux
  bind r source-file ~/.config/tmux/tmux.conf \; display-message "recargado"
  ```

- Probar algo **en vivo** sin tocar el archivo:

  ```
  C-Space :  set -g mouse off      ⏎
  C-Space :  display-message "hola"
  C-Space :  kill-server
  ```

---

## 11. Objetivos (`-t`): apuntar a sesiones, ventanas y panes

Muchos comandos aceptan `-t` (*target*) con la forma:

```
sesión:ventana.pane
```

Ejemplos:

```bash
tmux select-window -t trabajo:2        # ventana 2 de "trabajo"
tmux kill-pane     -t trabajo:1.0      # pane 0 de la ventana 1
tmux attach -t trabajo                  # por nombre de sesión
tmux new-window -t trabajo:9            # crear en un índice concreto
tmux move-window -t 5                   # mover ventana actual al índice 5
```

En comandos internos suele bastar `:` o un índice (p. ej. `select-window -t 3`).

---

## 12. Opciones comunes de tmux

Tabla de opciones que querrás tocar (las de este repo en **negrita**).

| Opción | Ámbito | Qué hace |
| --- | --- | --- |
| `prefix` / `prefix2` | sesión | Tecla(s) prefijo. |
| `escape-time` | servidor | Espera para resolver `Esc` (bájalo con nvim). |
| `mouse` | sesión | Ratón on/off. |
| `history-limit` | sesión | Scrollback en memoria. |
| `base-index` | sesión | Primer índice de ventana. |
| `renumber-windows` | sesión | Renumerar sin huecos. |
| `detach-on-destroy` | sesión | Qué hacer al destruir la sesión actual. |
| `set-clipboard` | servidor | Sincronización con el portapapeles. |
| `copy-command` | servidor | Programa de copia (p. ej. `wl-copy`). |
| `mode-keys` | ventana | `emacs` o `vi` en copy-mode. |
| `status-keys` | sesión | `emacs` o `vi` en el prompt. |
| `status-left`/`right` | sesión | Barra de estado. |
| `window-status-format` | ventana | Formato de la lista de ventanas. |
| `default-terminal` | sesión | `TERM` interno. |
| `focus-events` | sesión | Reenviar eventos de foco. |
| `allow-passthrough` | servidor | Dejar pasar OSC. |
| `extended-keys`/`format` | servidor | Teclado extendido CSI-u. |
| `terminal-features` | servidor | Capacidades de la terminal externa. |
| `automatic-rename` | ventana | Nombrar ventana según el programa. |
| `status-interval` | sesión | Cada cuántos segundos se refresca la barra. |

Consultar valores en vivo:

```bash
tmux show-options -g                 # opciones globales de sesión
tmux show-options -s                 # opciones de servidor
tmux show-window-options -g          # opciones de ventana
tmux show-options -g prefix          # una en concreto
```

---

## 13. Integraciones: kitty, sway, nvim, zsh

### kitty

- **Color 24 bits** y **teclado extendido**: resueltos en §5.2. `TERM=xterm-kitty`
  se declara con `RGB:extkeys`.
- **`escape-time 0`**: `Esc` instantáneo dentro de nvim.
- **`allow-passthrough on`**: imágenes/OSC de kitty pasan por tmux.
- **Scrollback:** el `scrollback_pager nvim` de `kitty/kitty.conf` aplica al
  scrollback **de kitty** (fuera de tmux). Dentro de tmux usa copy-mode (§9).
- **SSH:** para hosts remotos, `kitten ssh user@host` copia la terminfo correcta
  y evita problemas de `TERM`/colores.

### sway

Añadido en `sway/config.d/`:

```
# 00-variables
set $sessionizer ~/.local/bin/tmux-sessionizer
# 04-bindings
bindsym $mod+Shift+Return exec $term -e $sessionizer
```

- `$mod+Shift+Return` → kitty + sessionizer.
- El **servidor de tmux es independiente de sway**: recargar/reiniciar sway no
  mata tus sesiones; vuelves con `tmux attach` o `C-Space s`.

### nvim

- No necesita plugin ni cambios: corre dentro de una ventana como en cualquier
  terminal.
- `focus-events on` y `escape-time 0` ya lo integran bien.
- Si algún día usaras panes y quisieras moverte entre nvim/tmux con las mismas
  teclas, ese es el caso de `vim-tmux-navigator`. **No se usa aquí.**

### zsh

Aliases añadidos a `.zshrc`:

| Alias | Equivale a |
| --- | --- |
| `ta <sesión>` | `tmux attach -t <sesión>` |
| `tn <sesión>` | `tmux new -As <sesión>` |
| `tls` | `tmux ls` |
| `tk <sesión>` | `tmux kill-session -t <sesión>` |
| `ts` | `tmux-sessionizer` |

---

## 14. El sessionizer explicado

`tmux/scripts/tmux-sessionizer` (enlazado en `~/.local/bin`) automatiza el flujo
"una sesión por proyecto".

Cómo funciona, paso a paso:

1. Muestra por defecto las **sesiones de tmux existentes**
   (`ctrl-s`; nombre y ruta). Elegir una **cambia a ella**.
2. Otros modos del menú: `ctrl-t` = proyectos (primer nivel de
   `~/repos`, `~/Downloads` y `~/.config/tmux/sessionizer.dirs`)
   y `ctrl-a` = **todo `$HOME`** (hasta 5 niveles).
3. Al elegir una **carpeta**, deriva el **nombre de sesión** del
   nombre del directorio (tmux no admite `.` ni `:` en nombres,
   se reemplazan por `_`).
4. Si la sesión **ya existe**, solo **cambia a ella** (no reinicia nada).
   Si no, la **crea** en segundo plano con `-c` apuntando al directorio.
5. Si estás **dentro** de tmux, usa `switch-client`; si estás **fuera**,
   `attach`.

Formas de lanzarlo:

- **sway:** `$mod+Shift+Return`.
- **dentro de tmux:** `C-Space f` (popup).
- **shell:** `ts`.

---

## 15. Solución de problemas

**Los colores de nvim se ven apagados dentro de tmux.**
Falta `RGB` en `terminal-features` o el `default-terminal` no es correcto. Comprueba:

```bash
echo $TERM                    # dentro de tmux: tmux-256color (o similar)
tmux show-options -s terminal-features
```

Debe aparecer `xterm-kitty*:RGB:extkeys`.

**`Esc` tarda en reaccionar en nvim.**
`escape-time` alto. Debe estar en `0`:

```bash
tmux show-options -s escape-time
```

**`Shift+Enter` no hace salto de línea en nvim/CLIs.**
Necesitas extended keys CSI-u (§5.2). Verifica `extended-keys always` y
`extended-keys-format csi-u`.

**El ratón selecciona en vez de copiar a mi portapapeles.**
`mouse on` hace que arrastrar entre en copy-mode. Selecciona y pulsa `y` (va a
`wl-copy`). Asegúrate de tener `wl-clipboard` instalado.

**`wl-copy` no pega nada / error.**
Comprueba que estás en Wayland y que `wl-copy` existe:

```bash
echo $WAYLAND_DISPLAY ; command -v wl-copy ; echo test | wl-copy && wl-paste
```

**Al cerrar kitty desaparece todo.**
Cerrar kitty solo desconecta el **cliente**; la sesión debería seguir viva. Si de
verdad se perdió, seguramente saliste con `exit` de la **última** ventana (eso
mata la sesión) o corriste `tmux kill-server`. Para dejarlo todo vivo, sal con
`C-Space d` (detach), no con `exit`. Comprueba con `tmux ls`.

**La barra de estado se ve rara / sin colores.**
La terminal externa no soporta lo que pides. Revisa `terminal-features` y que no
haya un `~/.tmux.conf` viejo peleando (gana `~/.config/tmux/tmux.conf`, §4).

**Recargo la config y no cambia nada.**
Con varios servidores o sockets, o no recargaste. Usa `C-Space r` o
`:source-file ~/.config/tmux/tmux.conf`. Opciones de servidor pueden requerir
reiniciar el servidor:

```bash
tmux kill-server && tmux new
```

**Dos tmux pelean / quiero aislar pruebas.**
Usa un **socket** distinto con `-L`:

```bash
tmux -L pruebas new -s x
tmux -L pruebas ls
tmux -L pruebas kill-server
```

**SSH remoto con colores/terminfo rotos.**
Usa `kitten ssh` (copia terminfo), o dentro del remoto instala la terminfo de
`xterm-kitty`.

---

## 16. Recetas y patrones de uso

**Una sesión por proyecto (con el sessionizer):**
`$mod+Shift+Return` → elige el proyecto → trabajas → `C-Space d`. Vuelves con
`tmux attach` o `ts`.

**Lanzar una sesión en segundo plano y entrar luego:**

```bash
tmux new -d -s build -c ~/repos/app 'cargo build 2>&1 | tee build.log'
# ... luego:
tmux attach -t build
```

**Ejecutar algo en una sesión existente sin entrar:**

```bash
tmux send-keys -t build 'ls -la' Enter
```

**Sesión de larga duración en un servidor (SSH):**

```bash
ssh host
tmux new -As trabajo
# lanzas procesos, C-Space d, y puedes cerrar SSH
# otra vez: ssh host && tmux attach -t trabajo
```

**Cambiar de proyecto rápido:** dentro de tmux, `C-Space f` (sessionizer) o
`C-Space s` (árbol).

**Reiniciar la config desde cero (emergencia):**

```bash
tmux kill-server      # mata todo
tmux                  # arranca limpio leyendo la config
```

---

## 17. Persistencia de sesiones

Las sesiones sobreviven a reinicios y apagados con
**tmux-resurrect** + **tmux-continuum** (en
`~/.config/tmux/plugins/`, cargados al final de `tmux.conf`):

- **Guardado:** automático cada 10 min, o manual con `C-Space C-s`.
- **Restauración:** automática al arrancar el servidor tmux; `C-Space C-r`
  la fuerza a mano.
- Se guardan sesiones, ventanas, panes, directorios de trabajo y el
  contenido de los panes en `~/.local/share/tmux/resurrect/`.

Cómo funciona, paso a paso:

1. continuum (o `C-Space C-s`) ejecuta `resurrect/scripts/save.sh`:
   vuelca el estado del servidor a un fichero con marca de tiempo.
2. Al **arrancar el servidor**, continuum detecta que es recién
   iniciado y ejecuta `resurrect/scripts/restore.sh` en segundo
   plano: recrea sesiones, ventanas y panes con sus directorios.
3. Si un directorio guardado ya no existe, el pane arranca en `$HOME`.

Notas:

- El guardado es una **foto de todo el servidor**: mata las sesiones
  que no quieras recuperar antes del siguiente guardado (`C-Space X`).
- Para actualizar los plugins: `git -C ~/.config/tmux/plugins/tmux-resurrect pull`
  (y lo mismo para `tmux-continuum`).

---

## 18. Referencia

- **Getting Started (wiki oficial):** <https://github.com/tmux/tmux/wiki/Getting-Started>
- **Manual:** `man 1 tmux` · <https://man.openbsd.org/tmux>
- **FAQ (problemas de configuración):** <https://github.com/tmux/tmux/wiki/FAQ>
- **kitty — teclado extendido:** <https://sw.kovidgoyal.net/kitty/keyboard-protocol/>
- **kitty — FAQ (opinión sobre multiplexores):** <https://sw.kovidgoyal.net/kitty/faq/>
- **README del repo:** [`tmux/README.md`](README.md) (instalación e integración)
- **Config:** [`tmux/tmux.conf`](tmux.conf) · **Sessionizer:** [`tmux/scripts/tmux-sessionizer`](scripts/tmux-sessionizer)

> Probado con **tmux 3.5a** (Debian 13). Funciones de versiones posteriores
> (p. ej. *floating panes*, tmux 3.8) no están disponibles y no se usan.

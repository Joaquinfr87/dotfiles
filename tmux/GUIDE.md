# Complete TMUX Guide — learn and use

Extensive guide to **learn tmux from scratch** and to understand **the whole
configuration** of this repo (`tmux/tmux.conf`), designed for the
**Debian 13 + kitty + sway + nvim + zsh** stack.

> Repo focus: **sessions** and **utilities**. Panes (splits) are
> explained here so you know they exist, but the config does not promote them.
>
> Sources: official wiki <https://github.com/tmux/tmux/wiki/Getting-Started>,
> `man tmux` (tested with tmux **3.5a**) and direct tests on that version.

---

## Table of contents

1. [What tmux is and why use it](#1-what-tmux-is-and-why-use-it)
2. [Mental model: server, session, window, pane](#2-mental-model-server-session-window-pane)
3. [Installation and first launch](#3-installation-and-first-launch)
4. [Where the configuration lives and how it is loaded](#4-where-the-configuration-lives-and-how-it-is-loaded)
5. [Anatomy of `tmux.conf`, block by block](#5-anatomy-of-tmuxconf-block-by-block)
6. [Learning tmux in levels](#6-learning-tmux-in-levels)
7. [Command reference](#7-command-reference)
8. [Keybinding cheat sheet (prefix `C-Space`)](#8-keybinding-cheat-sheet-prefix-c-space)
9. [Copy-mode, buffers and clipboard](#9-copy-mode-buffers-and-clipboard)
10. [The command prompt and sequences](#10-the-command-prompt-and-sequences)
11. [Targets (`-t`): pointing at sessions, windows and panes](#11-targets--t-pointing-at-sessions-windows-and-panes)
12. [Common tmux options](#12-common-tmux-options)
13. [Integrations: kitty, sway, nvim, zsh](#13-integrations-kitty-sway-nvim-zsh)
14. [The sessionizer explained](#14-the-sessionizer-explained)
15. [Troubleshooting](#15-troubleshooting)
16. [Recipes and usage patterns](#16-recipes-and-usage-patterns)
17. [Session persistence](#17-session-persistence)
18. [Reference](#18-reference)

---

## 1. What tmux is and why use it

**tmux** is a **terminal multiplexer**: a program that runs inside your terminal
(kitty) and inside which other programs run, each with its own virtual terminal
managed by tmux.

What it gives you:

- **Persistence (detach/attach).** You can *let go* (detach) the session and the
  programs keep running in the background. When you *hook on* (attach) again,
  everything is where you left it. You close kitty, reload sway, reconnect over
  SSH… and it's still the same.
- **Sessions per context.** One session per project. Switching projects is
  switching sessions, without closing anything or losing processes.
- **Windows.** Several terminals inside the same session, like tabs.
- **Automation.** Everything is controlled by commands, so it can be scripted.

### When NOT to use tmux

kitty already has its own tabs and splits, and its FAQ even advises against
multiplexers for purely local use. The reason to use tmux here is **not**
splitting the screen, but **persistence**: keeping processes alive across
terminal/compositor restarts and working comfortably over SSH. If you only
wanted local splits, kitty would be enough.

---

## 2. Mental model: server, session, window, pane

tmux has four concepts. Understanding them is 80% of learning it.

```
                       ┌───────────────────────────────────────────┐
   kitty (client 1)    │  tmux SERVER  (background process)        │
   ───────────────────▶│                                           │
                       │   SESSION "work"                          │
   kitty (client 2)    │   ├── WINDOW 1  (one terminal: nvim)      │
   ───────────────────▶│   ├── WINDOW 2  (one terminal: shell)     │
                       │   └── WINDOW 3  ┌────────┬────────┐       │
                       │                 │ PANE 0 │ PANE 1 │       │
                       │                 └────────┴────────┘       │
                       └───────────────────────────────────────────┘
```

- **Server.** A single background process. It holds *all* the state
  (sessions, windows, panes, programs). It starts on its own the first time and
  dies when nothing is left inside.
- **Client.** Each terminal connected to a session (e.g. your kitty window). It
  communicates with the server over a **socket** in `/tmp` (or
  `$TMUX_TMPDIR`).
- **Session.** It groups windows. It has a **unique name** (by default `0`, `1`, …).
  It is the unit that gets *detached*/*attached*. It has no index.
- **Window.** It fills the whole connected terminal. It has a **name** (by default
  the program's) and an **index** inside its session (`1`, `2`, … with our
  config). Each session has a *current window*.
- **Pane.** A terminal inside a window; splits live here. Each
  window has an *active pane*.

**Key points:**

- A session can be **attached** (visible in one or more terminals) or
  **detached** (no client, still alive).
- Windows are identified by **session + index**.
- `attach` does not disconnect other clients unless you use `-d`.

Shortcut notation: `C-` = Ctrl, `M-` = Meta (Alt), `S-` = Shift.
`C-Space c` means: prefix `C-Space`, release, and then `c`.

---

## 3. Installation and first launch

```bash
sudo apt install tmux
tmux -V                # Debian 13 ships 3.5a; the config requires >= 3.2
```

First launch (creates the server and the first session, and connects you):

```bash
tmux                   # same as: tmux new-session
```

To exit leaving everything alive, **detach**: `C-Space` followed by `d`.
To reconnect:

```bash
tmux attach            # to the last used session
```

> If you prefer to start with this repo's config before poking around, go to §4.

---

## 4. Where the configuration lives and how it is loaded

tmux reads **one** configuration file when the server starts. Possible paths:

| Path | Notes |
| --- | --- |
| `~/.config/tmux/tmux.conf` | XDG support. **This is the one this repo uses.** |
| `~/.tmux.conf` | Classic location. |

**Precedence (verified on tmux 3.5a):** if both exist,
**`~/.config/tmux/tmux.conf` wins**. That is why the repo installs there and you can leave
`~/.tmux.conf` free without fear.

Installing this config:

```bash
mkdir -p ~/.config/tmux
cp ~/repos/dotfiles/tmux/tmux.conf ~/.config/tmux/tmux.conf

mkdir -p ~/.local/bin
ln -sf ~/repos/dotfiles/tmux/scripts/tmux-sessionizer ~/.local/bin/tmux-sessionizer
```

**Loading changes:**

- With a server running it does NOT reload by itself. Force the reload with
  **`C-Space r`** (own bind) or from the `C-Space :` prompt → `:source-file ~/.config/tmux/tmux.conf`.
- If there is no server, it is read on its own the next time you start one.

Check that it loads without errors:

```bash
tmux -L test -f ~/.config/tmux/tmux.conf new-session -d -s ok && tmux -L test kill-server
```

---

## 5. Anatomy of `tmux.conf`, block by block

### 5.1 Syntax of the config commands

A `tmux.conf` is a list of **tmux commands** (the same ones as in the `:` prompt)
without the leading `tmux`. The ones we use:

| Form | Meaning |
| --- | --- |
| `set -g option value` | **Session-global** option (all new sessions). |
| `set -s option value` | **Server** option (affects the whole server). |
| `setw -g option value` | **Window** option (global). `setw` = `set-window-option`. |
| `set -as option value` | **Append** (`-a`) to a list option (does not replace). |
| `bind key command` | Binds a shortcut in the **prefix** table. |
| `bind -n key command` | Binds a shortcut **without prefix** (*root* table). |
| `bind -T table key cmd` | Binds in another table (`copy-mode-vi`, etc.). |
| `bind -r key command` | Allows **repeating** without pressing the prefix again. |
| `unbind key` | Removes a shortcut. |

> Several options in this file (`extended-keys`, `set-clipboard`,
> `allow-passthrough`, `escape-time`…) are server options; tmux accepts them and they stay
> active (verified: the config loads with exit 0 and the values are the
> expected ones). We use `-g` for consistency.

### 5.2 Block: terminal (kitty integration)

```tmux
set -g default-terminal "tmux-256color"
set -g extended-keys always
set -g extended-keys-format csi-u
set -as terminal-features ',xterm-kitty*:RGB:extkeys'
set -g allow-passthrough on
```

- **`default-terminal "tmux-256color"`** — `TERM` value for the programs
  inside tmux. `tmux-256color` is the terminfo entry recommended by tmux
  (it brings tmux's extra capabilities: styles, etc.).
- **`extended-keys always`** + **`extended-keys-format csi-u`** — asks the
  outer terminal for **extended keys** in **CSI-u** format and forwards them
  to the apps. This is what makes `Shift+Enter` work in nvim and CLIs.
- **`terminal-features ',xterm-kitty*:RGB:extkeys'`** — announces that the
  external terminal (`xterm-kitty`) supports **RGB** (24-bit color) and **extkeys**. The
  `-a` *appends* to the default list (the leading `,` is the separator).
- **`allow-passthrough on`** — lets the app's **OSC** sequences through to the
  external terminal (`kitten icat` images, OSC 52 clipboard, etc.).

### 5.3 Block: general behavior

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

- **`escape-time 0`** — time tmux waits to decide whether a key is an
  escape sequence. Without this, `Esc` feels slow **inside nvim**. `-s`
  = server option.
- **`focus-events on`** — forwards focus events to the apps; nvim uses them
  (`autoread`, actions on gaining/losing focus).
- **`mouse on`** — the wheel enters copy-mode, dragging selects, clicking activates
  windows/panes.
- **`history-limit 50000`** — scrollback lines per pane in memory.
- **`base-index 1`** — windows numbered from **1** (like your sway
  workspaces), not from 0.
- **`pane-base-index 1`** — panes also from 1.
- **`automatic-rename on`** — the window takes the name of the active program.
- **`renumber-windows on`** — when a window is closed **no gaps are left**
  (`1,3` → `1,2`).
- **`aggressive-resize on`** — the window resizes according to its own
  size, not according to the largest session.
- **`detach-on-destroy off`** — when killing the current session, it **jumps** to another one instead
  of closing all of tmux. Handy so you don't lose your thread.
- **`set-clipboard on`** — lets apps put text on the clipboard
  via OSC 52 and lets tmux sync with the system.

### 5.4 Block: vi style

```tmux
setw -g mode-keys vi
set -g status-keys vi
```

- **`mode-keys vi`** — **vi**-style navigation in copy-mode (consistent with nvim).
- **`status-keys vi`** — vi-style shortcuts in the command prompt (`C-Space :`).

### 5.5 Block: prefix

```tmux
set -g prefix C-Space
set -g prefix2 C-b
bind C-Space send-prefix
```

- **`prefix C-Space`** — the prefix goes from `C-b` to **`C-Space`**. It doesn't clash with
  `C-b` (screen/readline) or with `C-a` (beginning of line), and it is comfortable.
- **`prefix2 C-b`** — keeps `C-b` as a **second prefix**, in case you use it.
- **`bind C-Space send-prefix`** — pressing the prefix **twice** sends
  `C-Space` to the inner app (for example, to pass `C-Space` to a program).

### 5.6 Block: Wayland clipboard

```tmux
set -s copy-command 'wl-copy'
bind -T copy-mode-vi v send-keys -X begin-selection
bind -T copy-mode-vi y send-keys -X copy-selection-and-cancel
bind -T copy-mode-vi C-v send-keys -X rectangle-toggle
```

- **`copy-command 'wl-copy'`** — makes copying inside tmux use
  **`wl-copy`** (the Wayland clipboard), so what you copy is available across all of
  sway. It requires `wl-clipboard` (already installed; see root README §8).
- **`v`** — in copy-mode, starts the **selection** (like in vim; `Space` too).
- **`y`** — **copies** the selection and leaves copy-mode (to `wl-copy`).
- **`C-v`** — **rectangular** (column) selection.

> Real note: by default tmux binds `v` to `rectangle-toggle`. This repo
> reassigns it to *start selection* so that it is 100% vim-like; rectangular
> selection moves to `C-v`.

### 5.7 Block: own utilities

```tmux
bind r source-file ~/.config/tmux/tmux.conf \; display-message "tmux.conf reloaded"
bind X confirm-before -p "kill session #S? (y/n)" kill-session
bind f display-popup -E -w 80% -h 60% "~/.local/bin/tmux-sessionizer"
```

- **`r`** — **reloads** the config without restarting tmux. The `\;` chains a second
  command (show a message). It is a *command sequence*.
- **`X`** — **kills** the current session asking for confirmation (`#S` = session
  name).
- **`f`** — opens the **sessionizer** in a **popup** (`display-popup`) at 80%×60%.

### 5.8 Block: scrollback and quick sessions

```tmux
bind -n M-Up   copy-mode \; send-keys -X page-up
bind -n M-Down copy-mode \; send-keys -X page-down
bind -T copy-mode M-Up   send-keys -X page-up
bind -T copy-mode M-Down send-keys -X page-down

bind -r C-n switch-client -n
bind -r C-p switch-client -p
```

- **`M-Up`/`M-Down` (no prefix)** — enter copy-mode and **move up/down one
  page**, without depending on `PageUp`/`PageDown` (handy on compact keyboards and
  laptops). Since there is no `Ctrl` involved, they also work **inside nvim**:
  if you ever want nvim to receive `Alt+↑`, you must remove these binds.
- **`C-n`/`C-p` (with prefix, `-r`)** — **next/previous session**,
  repeatable without pressing the prefix again.

### 5.9 Block: status bar (Gruvbox Material)

```tmux
set -g status-interval 5
set -g status-style "bg=#282828,fg=#a89984"
set -g status-left  "#[bg=#b8bb26,fg=#282828,bold] #S #[bg=#3c3836,fg=#b8bb26,nobold] "
set -g status-right "#[fg=#928374]%d/%m #[fg=#83a598]%H:%M "
setw -g window-status-format " #I:#W "
setw -g window-status-current-format "#[bg=#3c3836,fg=#fabd2f,bold] #I:#W "
...
```

- **`status-interval 5`** — refreshes every 5 s (clock, counters).
- **`status-left`** — on the left: the **session** name (`#S`).
- **`status-right`** — on the right: date and time (`%d/%m %H:%M`).
- **`window-status-format`** — how each window is shown: `#I:#W` =
  **index:name**.
- **`window-status-current-format`** — the active window, highlighted in yellow.
- Colors from the Gruvbox Material palette (`#282828` background, `#b8bb26` green,
  `#fabd2f` yellow, `#a89984` gray, etc.). The `#[...]` are **inline
  styles**; `#I`, `#W`, `#S` are tmux **variables**.

---

## 6. Learning tmux in levels

Go in order. Each level adds a new tool.

### Level 1 — Minimal sessions

```bash
tmux new -s work     # creates the "work" session and connects you
# ...you work...
# C-Space d             # detach: the session stays alive
tmux ls                 # list sessions
tmux attach -t work  # enter again
```

Learned: `new`, `attach`, `ls`, detach with `d`.

### Level 2 — Windows (several terminals in one session)

Inside the session:

- `C-Space c` → new window.
- `C-Space 1` … `9` → go to window N.
- `C-Space n` / `p` → next / previous.
- `C-Space ,` → rename.
- `C-Space &` → close (confirms).

### Level 3 — Real persistence (the point of tmux)

1. Open a session, launch something long (e.g. `sleep 300 &` or a `cargo build`).
2. `C-Space d` (detach) and **close kitty**.
3. Open kitty, `tmux attach`. The process is still there.
4. Repeat but **reload sway** (`$mod+Shift+c`) or log out and back in: it is still there.

This shows why tmux is useful even though kitty already splits windows.

### Level 4 — Copy-mode and clipboard

- Mouse wheel or `Alt+↑` → you enter copy-mode.
- `v` starts selection, `y` copies (to `wl-copy`), `q` exits.
- `C-Space ]` pastes the last buffer.
- `C-Space =` opens the buffer list (copy history).

### Level 5 — Tree, clients and buffers

- `C-Space s` → **tree mode**: view and jump between sessions/windows; `Enter`
  chooses; `x` kills; `q` exits.
- `C-Space w` → tree mode with windows expanded.
- `C-Space D` → **client mode**: list of connected terminals; `Enter` detaches.
- `C-Space =` → **buffer mode**.

### Level 6 — Configure and automate

- `C-Space :` → command prompt (`:set -g mouse off` to try live).
- `C-Space r` → reload after editing `tmux.conf`.
- Write your own `bind`/`set` (see §5, §12).
- Use the sessionizer (`C-Space f`) so you don't have to type session names.

---

## 7. Command reference

All commands have **aliases**. From the shell they are called with `tmux` in front;
in the `:` prompt without it.

### Sessions

| Command | Alias | What it does |
| --- | --- | --- |
| `new-session` | `new` | New session. |
| `attach-session` | `attach` | Connect to a session. |
| `list-sessions` | `ls` | List sessions. |
| `kill-session` | — | Kill a session (and everything in it). |
| `rename-session` | — | Rename the current session. |
| `switch-client` | — | Switch the client to another session (used by `C-n`/`C-p`). |
| `has-session` | — | Does the session exist? (useful in scripts). |

Useful flags: `-s name`, `-t target`, `-d` (create without connecting),
`-A` (connect if it exists, create otherwise), `-D` (on connecting, detach other clients),
`-c dir` (startup directory).

Examples:

```bash
tmux new -As work          # creates "work" or connects if it already exists
tmux new -d -s build -c ~/repos/app   # "build" session in the background
tmux attach -dt work       # connect and kick out other clients
tmux kill-session -t build
```

### Windows

| Command | Alias | What it does |
| --- | --- | --- |
| `new-window` | `neww` | New window. |
| `select-window` | — | Go to a window. |
| `next-window` / `previous-window` | — | Next / previous. |
| `rename-window` | — | Rename. |
| `kill-window` | — | Close. |
| `last-window` | — | Previous window. |
| `move-window` | `movew` | Move to another index (`-r` to renumber). |
| `swap-window` | — | Swap with the marked one. |

`neww -n editor nvim` → new window named `editor` running nvim.

### Panes (so you know they exist)

| Command | Alias | What it does |
| --- | --- | --- |
| `split-window` | `splitw` | Split (`-h` horizontal, `-v` vertical). |
| `select-pane` | — | Change pane. |
| `resize-pane` | — | Resize. |
| `kill-pane` | — | Close pane. |
| `break-pane` | — | Take a pane out into its own window. |
| `display-panes` | — | Show pane numbers. |

> These shortcuts **still exist** (`C-Space %`, `C-Space "`, `C-Space z` for
> zoom…) but we don't use them. The wiki's *floating panes* arrive in **tmux
> 3.8**, which is not in Debian 13; they are not needed here.

### Clients and server

| Command | Alias | What it does |
| --- | --- | --- |
| `list-clients` | `lsc` | See connected terminals. |
| `detach-client` | `detach` | Disconnect client(s). |
| `choose-client` | — | client mode (`C-Space D`). |
| `kill-server` | — | Kill all of tmux. |
| `source-file` | — | Reload config. |
| `list-keys` | `lsk` | See shortcuts (`lsk -N` with descriptions). |
| `display-message` | `display` | Show a message in the status bar. |

```bash
tmux lsk -N | less            # all shortcuts with description (same as C-Space ?)
tmux list-windows -t work  # windows of a session
tmux kill-server              # closes EVERYTHING (careful)
```

---

## 8. Keybinding cheat sheet (prefix `C-Space`)

> `C-b` works too (prefix2).

**Sessions**

| Shortcut | Action |
| --- | --- |
| `d` | Detach (leaves the session alive) |
| `s` | Tree mode for sessions |
| `(` / `)` | Previous / next session |
| `C-p` / `C-n` | Same, repeatable without pressing the prefix again |
| `$` | Rename session |
| `X` | Kill session (confirms) |
| `D` | Detach other clients |

**Windows**

| Shortcut | Action |
| --- | --- |
| `c` | New window |
| `n` / `p` | Next / previous |
| `1`…`9` | Go to window N |
| `l` | Last window |
| `,` | Rename window |
| `&` | Close window |
| `w` | Tree mode with windows |

**Copy-mode / clipboard**

| Shortcut | Action |
| --- | --- |
| `[` | Enter copy-mode |
| `Alt+↑` / `Alt+↓` | Page up / down (enters copy-mode) |
| `v` / `Space` | Start selection |
| `y` / `Enter` | Copy and exit (→ `wl-copy`) |
| `C-v` | Rectangular selection |
| `]` | Paste last buffer |
| `=` | Buffer list |

**Utilities**

| Shortcut | Action |
| --- | --- |
| `?` | List of shortcuts with description |
| `:` | Command prompt |
| `r` | Reload `tmux.conf` |
| `f` | Sessionizer (fzf popup) |
| `t` | Clock |

**System (tmux defaults still apply)**

| Shortcut | Action |
| --- | --- |
| `%` / `"` | Split horizontal / vertical |
| `z` | Pane zoom |
| `Space` | Rotate layouts |
| `q` | Show pane numbers |

---

## 9. Copy-mode, buffers and clipboard

**Copy-mode** freezes a pane's output so you can navigate and copy.
You enter it with `C-Space [` or with the mouse wheel.

**vi keys inside copy-mode:**

| Key | Action |
| --- | --- |
| `h j k l` | Move (up/down/left/right) |
| `w` / `b` | Next / previous word |
| `0` / `$` | Beginning / end of line |
| `C-u` / `C-d` | Half page up / down |
| `g` / `G` | Beginning / end of history |
| `/` / `?` | Search forward / backward |
| `n` / `N` | Next / previous result |
| `v` / `Space` | Start selection |
| `V` | Select line |
| `C-v` | Rectangular selection |
| `y` / `Enter` | Copy and exit |
| `q` | Exit without copying |

**Buffers.** A copied text is a *paste buffer*.

- Automatic (`buffer0`…) — up to 50 are kept; the oldest is discarded.
- Named — never deleted.
- `C-Space =` opens **buffer mode** (list + preview).
- Commands: `set-buffer` (`setb`), `load-buffer` (`loadb`), `save-buffer`
  (`saveb`).

**System clipboard.** With `copy-command 'wl-copy'`, copying inside tmux
goes to the Wayland clipboard. So you can paste in any sway app.

---

## 10. The command prompt and sequences

`C-Space :` opens a **prompt** (it appears over the status bar) where you type
tmux commands as in the shell; with `status-keys vi` you can edit it like in
vim.

- **Chained commands (command sequence):** separate them with `;` **in the config**,
  or with `\;` inside a `bind`:

  ```tmux
  bind r source-file ~/.config/tmux/tmux.conf \; display-message "reloaded"
  ```

- Try something **live** without touching the file:

  ```
  C-Space :  set -g mouse off      ⏎
  C-Space :  display-message "hello"
  C-Space :  kill-server
  ```

---

## 11. Targets (`-t`): pointing at sessions, windows and panes

Many commands accept `-t` (*target*) with the form:

```
session:window.pane
```

Examples:

```bash
tmux select-window -t work:2        # window 2 of "work"
tmux kill-pane     -t work:1.0      # pane 0 of window 1
tmux attach -t work                  # by session name
tmux new-window -t work:9            # create at a specific index
tmux move-window -t 5                   # move current window to index 5
```

In internal commands `:` or an index is usually enough (e.g. `select-window -t 3`).

---

## 12. Common tmux options

Table of options you will want to touch (this repo's ones in **bold**).

| Option | Scope | What it does |
| --- | --- | --- |
| `prefix` / `prefix2` | session | Prefix key(s). |
| `escape-time` | server | Wait to resolve `Esc` (lower it with nvim). |
| `mouse` | session | Mouse on/off. |
| `history-limit` | session | Scrollback in memory. |
| `base-index` | session | First window index. |
| `renumber-windows` | session | Renumber without gaps. |
| `detach-on-destroy` | session | What to do when destroying the current session. |
| `set-clipboard` | server | Clipboard synchronization. |
| `copy-command` | server | Copy program (e.g. `wl-copy`). |
| `mode-keys` | window | `emacs` or `vi` in copy-mode. |
| `status-keys` | session | `emacs` or `vi` in the prompt. |
| `status-left`/`right` | session | Status bar. |
| `window-status-format` | window | Format of the window list. |
| `default-terminal` | session | Internal `TERM`. |
| `focus-events` | session | Forward focus events. |
| `allow-passthrough` | server | Let OSC through. |
| `extended-keys`/`format` | server | CSI-u extended keyboard. |
| `terminal-features` | server | Capabilities of the external terminal. |
| `automatic-rename` | window | Name the window after the program. |
| `status-interval` | session | How often the bar refreshes, in seconds. |

Check values live:

```bash
tmux show-options -g                 # global session options
tmux show-options -s                 # server options
tmux show-window-options -g          # window options
tmux show-options -g prefix          # one in particular
```

---

## 13. Integrations: kitty, sway, nvim, zsh

### kitty

- **24-bit color** and **extended keyboard**: handled in §5.2. `TERM=xterm-kitty`
  is declared with `RGB:extkeys`.
- **`escape-time 0`**: instant `Esc` inside nvim.
- **`allow-passthrough on`**: kitty images/OSC pass through tmux.
- **Scrollback:** the `scrollback_pager nvim` from `kitty/kitty.conf` applies to
  **kitty's** scrollback (outside tmux). Inside tmux use copy-mode (§9).
- **SSH:** for remote hosts, `kitten ssh user@host` copies the right terminfo
  and avoids `TERM`/color problems.

### sway

Added in `sway/config.d/`:

```
# 00-variables
set $sessionizer ~/.local/bin/tmux-sessionizer
# 04-bindings
bindsym $mod+Shift+Return exec $term -e $sessionizer
```

- `$mod+Shift+Return` → kitty + sessionizer.
- The **tmux server is independent of sway**: reloading/restarting sway does not
  kill your sessions; you return with `tmux attach` or `C-Space s`.

### nvim

- It needs no plugin or changes: it runs inside a window as in any
  terminal.
- `focus-events on` and `escape-time 0` already integrate it well.
- If you ever used panes and wanted to move between nvim/tmux with the same
  keys, that is the case for `vim-tmux-navigator`. **Not used here.**

### zsh

Aliases added to `.zshrc`:

| Alias | Equivalent to |
| --- | --- |
| `ta <session>` | `tmux attach -t <session>` |
| `tn <session>` | `tmux new -As <session>` |
| `tls` | `tmux ls` |
| `tk <session>` | `tmux kill-session -t <session>` |
| `ts` | `tmux-sessionizer` |

---

## 14. The sessionizer explained

`tmux/scripts/tmux-sessionizer` (symlinked in `~/.local/bin`) automates the
"one session per project" flow.

How it works, step by step:

1. By default it shows the **existing tmux sessions**
   (`ctrl-s`; name and path). Choosing one **switches to it**.
2. Other menu modes: `ctrl-t` = projects (first level of
   `~/repos`, `~/Downloads` and `~/.config/tmux/sessionizer.dirs`)
   and `ctrl-a` = **all of `$HOME`** (up to 5 levels).
3. When you choose a **folder**, it derives the **session name** from the
   directory name (tmux does not accept `.` or `:` in names,
   they are replaced with `_`).
4. If the session **already exists**, it only **switches to it** (nothing is restarted).
   If not, it **creates** it in the background with `-c` pointing at the directory.
5. If you are **inside** tmux, it uses `switch-client`; if you are **outside**,
   `attach`.

Ways to launch it:

- **sway:** `$mod+Shift+Return`.
- **inside tmux:** `C-Space f` (popup).
- **shell:** `ts`.

---

## 15. Troubleshooting

**nvim colors look washed out inside tmux.**
`RGB` is missing from `terminal-features` or `default-terminal` is not correct. Check:

```bash
echo $TERM                    # inside tmux: tmux-256color (or similar)
tmux show-options -s terminal-features
```

`xterm-kitty*:RGB:extkeys` must appear.

**`Esc` is slow to react in nvim.**
`escape-time` too high. It should be `0`:

```bash
tmux show-options -s escape-time
```

**`Shift+Enter` does not insert a line break in nvim/CLIs.**
You need extended keys CSI-u (§5.2). Verify `extended-keys always` and
`extended-keys-format csi-u`.

**The mouse selects instead of copying to my clipboard.**
`mouse on` makes dragging enter copy-mode. Select and press `y` (it goes to
`wl-copy`). Make sure you have `wl-clipboard` installed.

**`wl-copy` pastes nothing / error.**
Check that you are in Wayland and that `wl-copy` exists:

```bash
echo $WAYLAND_DISPLAY ; command -v wl-copy ; echo test | wl-copy && wl-paste
```

**Everything disappears when I close kitty.**
Closing kitty only disconnects the **client**; the session should stay alive. If it
really was lost, you probably exited with `exit` from the **last** window (that
kills the session) or ran `tmux kill-server`. To leave everything alive, exit with
`C-Space d` (detach), not with `exit`. Check with `tmux ls`.

**The status bar looks odd / without colors.**
The external terminal does not support what you are asking for. Check `terminal-features` and that there is no
old `~/.tmux.conf` fighting (`~/.config/tmux/tmux.conf` wins, §4).

**I reload the config and nothing changes.**
With several servers or sockets, or you did not reload. Use `C-Space r` or
`:source-file ~/.config/tmux/tmux.conf`. Server options may require
restarting the server:

```bash
tmux kill-server && tmux new
```

**Two tmux instances fight / I want to isolate tests.**
Use a different **socket** with `-L`:

```bash
tmux -L tests new -s x
tmux -L tests ls
tmux -L tests kill-server
```

**Remote SSH with broken colors/terminfo.**
Use `kitten ssh` (copies terminfo), or inside the remote install the terminfo for
`xterm-kitty`.

---

## 16. Recipes and usage patterns

**One session per project (with the sessionizer):**
`$mod+Shift+Return` → choose the project → you work → `C-Space d`. You come back with
`tmux attach` or `ts`.

**Launch a session in the background and enter it later:**

```bash
tmux new -d -s build -c ~/repos/app 'cargo build 2>&1 | tee build.log'
# ... later:
tmux attach -t build
```

**Run something in an existing session without entering it:**

```bash
tmux send-keys -t build 'ls -la' Enter
```

**Long-lived session on a server (SSH):**

```bash
ssh host
tmux new -As work
# you launch processes, C-Space d, and you can close SSH
# again: ssh host && tmux attach -t work
```

**Switch project quickly:** inside tmux, `C-Space f` (sessionizer) or
`C-Space s` (tree).

**Restart the config from scratch (emergency):**

```bash
tmux kill-server      # kills everything
tmux                  # starts clean, reading the config
```

---

## 17. Session persistence

Sessions survive restarts and shutdowns with
**tmux-resurrect** + **tmux-continuum** (in
`~/.config/tmux/plugins/`, loaded at the end of `tmux.conf`):

- **Saving:** automatic every 10 min, or manual with `C-Space C-s`.
- **Restoring:** automatic when the tmux server starts; `C-Space C-r`
  forces it by hand.
- Sessions, windows, panes, working directories and pane
  contents are saved in `~/.local/share/tmux/resurrect/`.

How it works, step by step:

1. continuum (or `C-Space C-s`) runs `resurrect/scripts/save.sh`:
   it dumps the server state to a timestamped file.
2. When the **server starts**, continuum detects that it was just
   started and runs `resurrect/scripts/restore.sh` in the background:
   it recreates sessions, windows and panes with their directories.
3. If a saved directory no longer exists, the pane starts in `$HOME`.

Notes:

- The save is a **snapshot of the whole server**: kill the sessions
  you don't want to recover before the next save (`C-Space X`).
- To update the plugins: `git -C ~/.config/tmux/plugins/tmux-resurrect pull`
  (and the same for `tmux-continuum`).

---

## 18. Reference

- **Getting Started (official wiki):** <https://github.com/tmux/tmux/wiki/Getting-Started>
- **Manual:** `man 1 tmux` · <https://man.openbsd.org/tmux>
- **FAQ (configuration problems):** <https://github.com/tmux/tmux/wiki/FAQ>
- **kitty — extended keyboard:** <https://sw.kovidgoyal.net/kitty/keyboard-protocol/>
- **kitty — FAQ (opinion on multiplexers):** <https://sw.kovidgoyal.net/kitty/faq/>
- **Repo README:** [`tmux/README.md`](README.md) (installation and integration)
- **Config:** [`tmux/tmux.conf`](tmux.conf) · **Sessionizer:** [`tmux/scripts/tmux-sessionizer`](scripts/tmux-sessionizer)

> Tested with **tmux 3.5a** (Debian 13). Features from later versions
> (e.g. *floating panes*, tmux 3.8) are not available and are not used.

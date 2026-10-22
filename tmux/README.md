# TMUX Guide — Sessions and windows

[tmux](https://github.com/tmux/tmux) configuration for the
**Debian 13 + kitty + sway + nvim** stack, focused on **sessions** and on the
utilities they bring (persistence, detach/attach, windows, copy-mode). **Panes**
(splits) keep their default behavior and are not used.

> Based on the official wiki: <https://github.com/tmux/tmux/wiki/Getting-Started>
> and `man tmux`. **Gruvbox Material Dark** palette, the same one as
> `sway/config.d/00-variables`.
>
> 📖 **Want to learn tmux in depth?** The extensive guide (mental model,
> line-by-line anatomy of `tmux.conf`, command reference and recipes) is in
> **[`GUIDE.md`](GUIDE.md)**. This README is the quick start.

---

## 1. What tmux is (concepts)

tmux is a **terminal multiplexer**: it runs several programs inside a single
terminal and lets you **disconnect** (detach) leaving them running, so you can
**connect again** (attach) later — from the same terminal, another one, or over
SSH.

Key terms from the wiki:

| Term | What it is |
|---|---|
| **Server** | Background process that runs everything. It starts on its own and dies when nothing is left inside. |
| **Client** | Each terminal connected to a session (your kitty window). |
| **Session** | Groups windows. It has a unique name. It is the unit of persistence. |
| **Window** | Fills the whole terminal; it groups one or more panes. |
| **Pane** | Terminal inside a window (the splits). |
| **Prefix** | Key that precedes tmux commands. Here it is **`C-Space`**. |

The hierarchy is: **session → windows → panes**. Since you don't use panes, in
practice each window is one terminal.

> **Why tmux and not kitty tabs?** kitty already knows how to split windows and
> tabs, and even its FAQ advises against multiplexers. tmux's real difference is
> **persistence**: `detach` leaves the programs alive, you can reconnect after
> closing kitty, restarting sway or reconnecting over SSH. We use tmux for that,
> not for the splits.

---

## 2. Installation

```bash
sudo apt install tmux
tmux -V   # needs >= 3.2 for this repo's config (Debian 13 ships 3.5a)
```

The config uses `extended-keys`, `display-popup`, `copy-command` and `prefix2`, all
available since tmux 3.2.

---

## 3. Installing this configuration

```bash
mkdir -p ~/.config/tmux
cp ~/repos/dotfiles/tmux/tmux.conf ~/.config/tmux/tmux.conf

mkdir -p ~/.local/bin
ln -sf ~/repos/dotfiles/tmux/scripts/tmux-sessionizer ~/.local/bin/tmux-sessionizer

# Session persistence (see §9)
mkdir -p ~/.config/tmux/plugins
git clone --depth 1 https://github.com/tmux-plugins/tmux-resurrect \
  ~/.config/tmux/plugins/tmux-resurrect
git clone --depth 1 https://github.com/tmux-plugins/tmux-continuum \
  ~/.config/tmux/plugins/tmux-continuum
```

tmux reads `~/.config/tmux/tmux.conf` automatically (XDG support since tmux 3.1),
so there is no need to touch `~/.tmux.conf`. The sessionizer symlink in
`~/.local/bin` is the same pattern you use for `zen`. The persistence plugins
live outside the repo (they are third-party); to update them,
`git -C <folder> pull`.

Check that there are no syntax errors:

```bash
tmux -L test -f ~/.config/tmux/tmux.conf new-session -d -s ok && tmux -L test kill-server
```

---

## 4. kitty integration

The config already brings what is needed; this is to understand why:

- **24-bit color** — kitty identifies itself as `TERM=xterm-kitty`. The line
  `set -as terminal-features ',xterm-kitty*:RGB:extkeys'` tells tmux that this
  terminal supports **RGB** (true color), so the nvim theme looks the same as
  in kitty (no washed-out colors).
- **Extended CSI-u keyboard** — tmux does **not** implement kitty's full keyboard
  protocol, but it does forward `CSI-u` sequences:
  ```
  set -g extended-keys always
  set -g extended-keys-format csi-u
  set -as terminal-features ',xterm-kitty*:RGB:extkeys'
  ```
  With this, keys like `Shift+Enter` work in nvim and in CLIs that use it.
- **`escape-time 0`** — without this, `Esc` feels slow in nvim inside tmux.
- **`allow-passthrough on`** — lets OSC sequences through (e.g. `kitten icat`)
  across tmux.

> **Scrollback:** the `scrollback_pager nvim` from `kitty/kitty.conf` applies to
> **kitty's** scrollback (outside tmux). Inside tmux the scrollback is tmux's and
> you navigate it with **copy-mode** (see §7).

---

## 5. sway integration

Added to `sway/config.d/`:

```
# 00-variables
set $sessionizer ~/.local/bin/tmux-sessionizer

# 04-bindings
bindsym $mod+Shift+Return exec $term -e $sessionizer
```

- **`$mod+Shift+Return`** opens kitty and launches the **sessionizer** (session
  picker with fzf). `$mod+Return` still opens a normal terminal.
- tmux sessions live in the tmux **server**, which is independent of sway: you
  can **reload or restart sway** (`$mod+Shift+c` / relogin) and the sessions stay
  alive. You come back with `prefix + s` or `tmux attach`.

---

## 6. nvim integration

No plugin or change in nvim is needed: nvim runs inside a tmux window as in any
terminal. Two details are already handled:

- **`focus-events on`** — nvim receives `FocusGained`/`FocusLost`, useful for
  `autoread`, autosave on losing focus, etc.
- **`escape-time 0`** + **CSI-u** — no delay on `Esc` and `Shift+Enter` works.

> If you ever start using panes and want to move between nvim and tmux with the
> same keys, that is the case for `vim-tmux-navigator`. Since you don't use panes,
> it is not installed.

---

## 7. Usage: sessions (the essentials)

### From the shell

| Command | What it does |
|---|---|
| `tmux` / `tmux new` | New session (the first one starts the server) |
| `tmux new -As work` | Creates the `work` session or connects if it already exists |
| `tmux ls` | Lists sessions |
| `tmux attach` | Connects to the last used session |
| `tmux attach -t work` | Connects to `work` |
| `tmux kill-session -t work` | Kills the `work` session |
| `tmux kill-server` | Kills all of tmux |

### With the prefix (`C-Space`, or `C-b` as secondary)

| Shortcut | Action |
|---|---|
| `C-Space d` | **Detach**: closes the client, the session stays alive |
| `C-Space s` | **Tree mode**: view/choose sessions (and windows) |
| `C-Space w` | Tree mode with windows expanded |
| `C-Space $` | Rename session |
| `C-Space X` | Kill the current session (with confirmation) |
| `C-Space (` / `)` | Previous / next session |
| `C-Space C-p` / `C-n` | Same, but **repeatable** without pressing the prefix again |
| `C-Space D` | Detach other clients connected to the same session |

The typical flow: you open one session per project, work, `C-Space d` and leave
it running. When you come back, `tmux attach` (or the sessionizer) and you carry
on where you were.

### Windows (inside a session)

| Shortcut | Action |
|---|---|
| `C-Space c` | New window |
| `C-Space n` / `p` | Next / previous |
| `C-Space 1` … `9` | Go to window N (numbered from 1) |
| `C-Space l` | Last window |
| `C-Space ,` | Rename window |
| `C-Space &` | Close window |

### Copy/paste and scrollback

The mouse wheel enters copy-mode automatically (`mouse on`). Also
`Alt+↑` / `Alt+↓` to page.

| Shortcut | Action |
|---|---|
| `C-Space [` | Enter copy-mode (vi keys) |
| `Alt+↑` / `Alt+↓` | Page up / down (enters copy-mode) |
| `v` … `y` | In copy-mode: select (`v`) and **copy to the clipboard** (`y` → `wl-copy`) |
| `C-Space ]` | Paste the last buffer |
| `C-Space =` | Choose buffer (copy history) |

`y` sends the selection to `wl-copy` (the Wayland clipboard), so what you paste
is available across all of sway, not only inside tmux.

### Utilities

| Shortcut | Action |
|---|---|
| `C-Space ?` | List of all shortcuts with their description |
| `C-Space :` | tmux command prompt (e.g. `:kill-server`) |
| `C-Space r` | **Reload `tmux.conf`** |
| `C-Space f` | Open the **sessionizer** in a popup (fzf) |
| `C-Space t` | Clock in the window |

---

## 8. Sessionizer (fzf)

`tmux/scripts/tmux-sessionizer` opens an **fzf** menu with three
modes and creates/enters one **tmux session per project** (the
name is the directory's):

- **`ctrl-s`: existing tmux sessions** (default; it shows
  name and path). Choosing one **switches to it**.
- **`ctrl-t`: projects** — first level of `~/repos`,
  `~/Downloads` and the paths in
  `~/.config/tmux/sessionizer.dirs`.
- **`ctrl-a`: all of `$HOME`** (up to 5 levels deep).

Choosing a folder creates the session if it doesn't exist; if it already
exists, it only switches to it (nothing is restarted).

- From **sway**: `$mod+Shift+Return`.
- From **inside tmux**: `C-Space f` (popup).
- From the **shell**: `ts` alias.

For folders that are **not** in `~/repos` or `~/Downloads` to show up, add their
path (one per line) to `~/.config/tmux/sessionizer.dirs`:

```bash
echo '~/my-projects' >> ~/.config/tmux/sessionizer.dirs
```

`~`, `#` comments and blank lines are accepted. (Equivalent: edit
`search_dirs` at the top of the script.)

---

## 9. Session persistence (resurrect + continuum)

Sessions **survive restarts and shutdowns** with
[tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect) and
[tmux-continuum](https://github.com/tmux-plugins/tmux-continuum)
(cloned into `~/.config/tmux/plugins/` and loaded at the end of
`tmux.conf`):

- **Saving:** automatic every 10 min (continuum) or manual with
  `C-Space C-s`.
- **Restoring:** automatic when the tmux server starts; `C-Space C-r`
  forces it by hand.
- Sessions, windows, panes, **working directories** and **pane contents**
  are saved in `~/.local/share/tmux/resurrect/`.

Notes:

- Automatic restore happens when **the server starts**
  (when creating/attaching the first session after boot).
- The save is a **snapshot of the whole server**: kill the sessions you
  don't want to recover before the next save
  (`C-Space X`).
- If a saved directory no longer exists (e.g. an unmounted disk),
  the pane starts in `$HOME`.

---

## 10. zsh aliases

Added to `.zshrc`:

| Alias | Equivalent to |
|---|---|
| `ta <session>` | `tmux attach -t <session>` |
| `tn <session>` | `tmux new -As <session>` (create or attach) |
| `tls` | `tmux ls` |
| `tk <session>` | `tmux kill-session -t <session>` |
| `ts` | `tmux-sessionizer` |

After copying `.zshrc`, apply it with `source ~/.zshrc` or open a new shell.

---

## 11. File structure

```
~/repos/dotfiles/tmux/
├── tmux.conf                   # installed to ~/.config/tmux/tmux.conf
├── README.md                   # quick start (this file)
├── GUIDE.md                    # extensive tmux guide
└── scripts/
    └── tmux-sessionizer        # symlinked in ~/.local/bin/
```

---

## 12. Config decisions (reference)

- **Prefix `C-Space`** (previously `C-b`), with `C-b` kept as `prefix2` for
  compatibility. `C-Space` doesn't clash with readline's `C-b`/`C-a` or with kitty.
- **`base-index 1`** — windows from 1 (like your sway workspaces).
- **`renumber-windows on`** — no gaps when closing windows.
- **`detach-on-destroy off`** — when killing a session it jumps to another one
  instead of closing everything.
- **`mode-keys vi` / `status-keys vi`** — consistent with nvim.
- **`set-clipboard on` + `copy-command wl-copy`** — Wayland clipboard
  integration.
- **No split shortcuts** — panes are not used; `%` and `"` still exist in case
  they are needed some day, but they are not promoted.

---

## 13. First steps

```bash
# 1. Install the config (see §3) and open a test session
tmux new -As test

# 2. Try: C-Space c (new window), C-Space 1/2, C-Space , (rename)
# 3. Detach and reattach
#    C-Space d   (you return to the shell, tmux keeps running)
tmux ls         # the 'test' session is still listed
tmux attach -t test

# 4. Sessionizer
#    C-Space f  or  ts  or  $mod+Shift+Return in sway

# 5. Cleanup
tmux kill-session -t test
```

---

## 14. Reference

- Getting Started (official wiki): <https://github.com/tmux/tmux/wiki/Getting-Started>
- Manual: `man 1 tmux` · <https://man.openbsd.org/tmux>
- FAQ (config problems): <https://github.com/tmux/tmux/wiki/FAQ>
- kitty + extended keyboard: <https://sw.kovidgoyal.net/kitty/keyboard-protocol/>
- kitty FAQ (opinion on multiplexers): <https://sw.kovidgoyal.net/kitty/faq/>

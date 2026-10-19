# ==============================================================================
# .zshrc — Shell interactivo ultrarrápido (Zsh nativo + Starship Prompt)
# ==============================================================================

# --- MODO ALTERNATIVO: OH MY ZSH + POWERLEVEL10K ------------------------------
# Si prefieres usar Oh My Zsh en lugar de Zsh nativo + Starship,
# define 'export USE_OH_MY_ZSH=true' en tu archivo ~/.zshrc.local
if [[ "${USE_OH_MY_ZSH:-false}" == "true" && -d "$HOME/.oh-my-zsh" ]]; then
  if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
  fi
  export ZSH="$HOME/.oh-my-zsh"
  ZSH_THEME="powerlevel10k/powerlevel10k"
  plugins=(git web-search copyfile dirhistory jsontools copypath)
  source "$ZSH/oh-my-zsh.sh"
  [[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
fi

# --- HISTORIAL NATIVO Y EFICIENTE ---------------------------------------------
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt EXTENDED_HISTORY          # Guarda marca de tiempo y duración
setopt INC_APPEND_HISTORY        # Escribe al archivo inmediatamente
setopt SHARE_HISTORY             # Comparte historial entre terminales abiertas
setopt HIST_IGNORE_DUPS          # Ignora comandos duplicados consecutivos
setopt HIST_IGNORE_ALL_DUPS      # Elimina entradas antiguas duplicadas
setopt HIST_IGNORE_SPACE         # No guarda comandos que empiecen con espacio
setopt HIST_REDUCE_BLANKS        # Elimina espacios superfluos

# --- AUTOCOMPLETADO NATIVO (< 5 ms con caché) ---------------------------------
autoload -Uz compinit colors
colors
# Regenera zcompdump solo una vez por día para acelerar el inicio
typeset -i updated_at=$(date +'%j' -r ~/.zcompdump 2>/dev/null || stat -f '%Sm' -t '%j' ~/.zcompdump 2>/dev/null || echo 0)
if [ $(date +'%j') != $updated_at ]; then
  compinit -i
else
  compinit -C -i
fi
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' # Case-insensitive
zstyle ':completion:*' menu select                       # Menú navegable con flechas
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# --- ATAJOS DE TECLADO Y MODO DE EDICIÓN --------------------------------------
bindkey -e # Modo emacs por defecto
bindkey '^[[A' up-line-or-search
bindkey '^[[B' down-line-or-search
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[3~' delete-char

# Shift+Enter: no mostrar secuencias CSI-u crudas en el shell
bindkey '\e[13;2u' accept-line
bindkey '\e[27;2;13~' accept-line

# --- PLUGINS NATIVOS (Autosuggestions & Syntax Highlighting) ------------------
for f in \
  "$HOME/.local/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" \
  /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
  "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"; do
  if [[ -f "$f" ]]; then
    source "$f"
    break
  fi
done

for f in \
  "$HOME/.local/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" \
  /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
  "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"; do
  if [[ -f "$f" ]]; then
    source "$f"
    break
  fi
done

# --- PROMPT: STARSHIP (Rust, ultrarrápido y universal) ------------------------
if [[ "${USE_OH_MY_ZSH:-false}" != "true" ]]; then
  if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
  fi
fi

# --- EDITOR POR DEFECTO -------------------------------------------------------
if command -v nvim >/dev/null 2>&1; then
  export EDITOR='nvim'
  export VISUAL='nvim'
else
  export EDITOR='vim'
  export VISUAL='vim'
fi

# --- NODE & NVM ---------------------------------------------------------------
export NVM_DIR="$HOME/.nvm"
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
  \. "$NVM_DIR/nvm.sh"
fi
if [[ -s "$NVM_DIR/bash_completion" ]]; then
  \. "$NVM_DIR/bash_completion"
fi

# --- PATH UNIFICADO Y PORTABLE ------------------------------------------------
typeset -U path PATH
path=(
  "$HOME/.local/bin"
  "$HOME/repos/dotfiles/bin"
  "$HOME/.opencode/bin"
  $path
)
export PATH

# Android SDK & Java (solo si existen en el sistema)
if [[ -d "$HOME/android-sdk" ]]; then
  export ANDROID_HOME="$HOME/android-sdk"
  path=(
    "$ANDROID_HOME/cmdline-tools/latest/bin"
    "$ANDROID_HOME/platform-tools"
    "$ANDROID_HOME/build-tools/36.0.0"
    $path
  )
fi

if [[ -d "/usr/lib/jvm/java-21-openjdk-amd64" ]]; then
  export JAVA_HOME="/usr/lib/jvm/java-21-openjdk-amd64"
fi

# --- HERRAMIENTAS MODERNAS DE CLI ---------------------------------------------
# zoxide (reemplazo inteligente de cd)
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# eza (reemplazo de ls)
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --icons'
  alias ll='eza -la --icons --git'
  alias la='eza -a --icons'
  alias lt='eza --tree --level=2 --icons'
else
  alias ll='ls -la'
  alias la='ls -A'
fi

# bat / batcat (reemplazo de cat con resaltado)
if command -v bat >/dev/null 2>&1; then
  alias cat='bat --paging=never'
elif command -v batcat >/dev/null 2>&1; then
  alias cat='batcat --paging=never'
fi

# --- ALIAS DE GIT MÁS USADOS (compatibles con OMZ) -----------------------------
alias g='git'
alias gst='git status'
alias gco='git checkout'
alias gcb='git checkout -b'
alias ga='git add'
alias gaa='git add --all'
alias gcmsg='git commit -m'
alias gca='git commit --amend'
alias gp='git push'
alias gpf='git push --force-with-lease'
alias gl='git pull'
alias gd='git diff'
alias glog='git log --oneline --decorate --graph'

# --- SINCRONIZADOR DE DOTFILES ------------------------------------------------
alias dots='dot-sync'

# --- TMUX (ver tmux/README.md) ------------------------------------------------
alias ta='tmux attach -t'        # ta <sesión>: attach
alias tn='tmux new -As'          # tn <sesión>: crear o adjuntar
alias tls='tmux ls'              # listar sesiones
alias tk='tmux kill-session -t'  # tk <sesión>: matar sesión
ts() { tmux-sessionizer; }       # ts: selector fzf de sesiones por proyecto

# Abrir vault de notas con Neovim
notes() {
  cd ~/repos/notas || return
  if [[ "$1" == "-n" ]]; then
    shift
    nvim +"Obsidian new $*"
  else
    nvim "$@"
  fi
}

# --- CARGAR CONFIGURACIÓN LOCAL / PRIVADA SI EXISTE (no en git) ----------------
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"

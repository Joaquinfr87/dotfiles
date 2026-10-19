# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load
ZSH_THEME="powerlevel10k/powerlevel10k"

# Which plugins would you like to load?
plugins=(git web-search copyfile dirhistory jsontools copypath)

# Load Oh My Zsh if installed
if [[ -f "$ZSH/oh-my-zsh.sh" ]]; then
  source "$ZSH/oh-my-zsh.sh"
fi

# --- Autosuggestions & Syntax Highlighting (Portable detection) ---
for f in \
  /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
  "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" \
  /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh; do
  if [[ -f "$f" ]]; then
    source "$f"
    break
  fi
done

for f in \
  /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
  "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" \
  /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh; do
  if [[ -f "$f" ]]; then
    source "$f"
    break
  fi
done

# --- Editor por defecto ---
if command -v nvim >/dev/null 2>&1; then
  export EDITOR='nvim'
  export VISUAL='nvim'
else
  export EDITOR='vim'
  export VISUAL='vim'
fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# --- Node / NVM (Lazy-load o comprobación rápida) ---
export NVM_DIR="$HOME/.nvm"
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
  \. "$NVM_DIR/nvm.sh"
fi
if [[ -s "$NVM_DIR/bash_completion" ]]; then
  \. "$NVM_DIR/bash_completion"
fi

# --- PATH unificado y portable ---
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

# --- Herramientas modernas de CLI ---
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

# --- Sincronizador de dotfiles ---
alias dots='dot-sync'

# --- tmux (ver tmux/README.md) ---
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

# --- Shift+Enter: no mostrar secuencias CSI-u crudas en el shell ---
bindkey '\e[13;2u' accept-line
bindkey '\e[27;2;13~' accept-line

# --- Cargar configuración local / privada si existe (no en git) ---
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"

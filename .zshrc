# ==============================================================================
# .zshrc — Ultra-fast interactive shell (native Zsh + Starship prompt)
# ==============================================================================

# --- ALTERNATIVE MODE: OH MY ZSH + POWERLEVEL10K ------------------------------
# If you prefer Oh My Zsh instead of native Zsh + Starship,
# set 'export USE_OH_MY_ZSH=true' in your ~/.zshrc.local file
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

# --- NATIVE, EFFICIENT HISTORY ------------------------------------------------
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt EXTENDED_HISTORY          # Store timestamps and duration
setopt INC_APPEND_HISTORY        # Write to the file immediately
setopt SHARE_HISTORY             # Share history between open terminals
setopt HIST_IGNORE_DUPS          # Ignore consecutive duplicate commands
setopt HIST_IGNORE_ALL_DUPS      # Remove older duplicate entries
setopt HIST_IGNORE_SPACE         # Do not store commands starting with a space
setopt HIST_REDUCE_BLANKS        # Remove superfluous whitespace

# --- NATIVE COMPLETION (< 5 ms with cache) ------------------------------------
autoload -Uz compinit colors
colors
# Regenerate zcompdump only once per day to speed up startup
typeset -i updated_at=$(date +'%j' -r ~/.zcompdump 2>/dev/null || stat -f '%Sm' -t '%j' ~/.zcompdump 2>/dev/null || echo 0)
if [ $(date +'%j') != $updated_at ]; then
  compinit -i
else
  compinit -C -i
fi
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' # Case-insensitive
zstyle ':completion:*' menu select                       # Arrow-key navigable menu
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# --- KEYBOARD SHORTCUTS AND EDITING MODE --------------------------------------
bindkey -e # Emacs mode by default
bindkey '^[[A' up-line-or-search
bindkey '^[[B' down-line-or-search
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[3~' delete-char

# Shift+Tab: go to the previous match in the completion menu
#   ^[[Z     legacy sequence (kitty without extended keys)
#   \e[9;2u  CSI-u sequence (kitty keyboard protocol / tmux extended-keys)
bindkey '^[[Z' reverse-menu-complete
bindkey '\e[9;2u' reverse-menu-complete

# Shift+Enter: do not show raw CSI-u sequences in the shell
bindkey '\e[13;2u' accept-line
bindkey '\e[27;2;13~' accept-line

# --- NATIVE PLUGINS (Autosuggestions & Syntax Highlighting) ------------------
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

# --- PROMPT: STARSHIP (Rust, ultra-fast and universal) ------------------------
if [[ "${USE_OH_MY_ZSH:-false}" != "true" ]]; then
  if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
  fi
fi

# --- DEFAULT EDITOR -----------------------------------------------------------
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

# --- UNIFIED, PORTABLE PATH ---------------------------------------------------
typeset -U path PATH
path=(
  "$HOME/.local/bin"
  "$HOME/repos/dotfiles/bin"
  "$HOME/.opencode/bin"
  $path
)
export PATH

# Android SDK & Java (only if they exist on the system)
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

# --- MODERN CLI TOOLS ---------------------------------------------------------
# zoxide (smart cd replacement)
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# eza (ls replacement)
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --icons'
  alias ll='eza -la --icons --git'
  alias la='eza -a --icons'
  alias lt='eza --tree --level=2 --icons'
else
  alias ll='ls -la'
  alias la='ls -A'
fi

# bat / batcat (cat replacement with syntax highlighting)
if command -v bat >/dev/null 2>&1; then
  alias cat='bat --paging=never'
elif command -v batcat >/dev/null 2>&1; then
  alias cat='batcat --paging=never'
fi

# direnv (automatic per-directory environment loading)
if command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook zsh)"
fi

# bluetuith (terminal Bluetooth manager)
alias blue='bluetuith'

# --- MOST USED GIT ALIASES (OMZ compatible) ------------------------------------
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

# --- DOTFILES SYNCHRONIZER ----------------------------------------------------
alias dots='dot-sync'

# --- TMUX (see tmux/README.md) ------------------------------------------------
alias ta='tmux attach -t'        # ta <session>: attach
alias tn='tmux new -As'          # tn <session>: create or attach
alias tls='tmux ls'              # list sessions
alias tk='tmux kill-session -t'  # tk <session>: kill session
ts() { tmux-sessionizer; }       # ts: fzf project/session picker

# Open the notes vault with Neovim
notes() {
  cd ~/repos/notas || return
  if [[ "$1" == "-n" ]]; then
    shift
    nvim +"Obsidian new $*"
  else
    nvim "$@"
  fi
}

# --- LOAD LOCAL / PRIVATE CONFIGURATION IF PRESENT (not in git) ----------------
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"

fastfetch

export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

alias clear='clear && fastfetch'

# --- Powerlevel10k Instant Prompt ---
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# --- Zinit Manager Setup ---
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [[ ! -f "$ZINIT_HOME/zinit.zsh" ]]; then
    print -P "%F{33}▓▒░ Installing Zinit...%f"
    command mkdir -p "$(dirname "$ZINIT_HOME")"
    command git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
source "$ZINIT_HOME/zinit.zsh"

# --- Plugins (Silent & Asynchronous) ---
# 'lucid' silences the "Loaded..." messages
# 'wait"0"' loads them after the prompt to keep it fast
zinit ice depth=1 lucid; zinit light romkatv/powerlevel10k
zinit ice wait"0" lucid; zinit light zsh-users/zsh-autosuggestions
zinit ice wait"0" lucid; zinit light zsh-users/zsh-syntax-highlighting
zinit ice wait"0" lucid; zinit light zsh-users/zsh-completions

# --- History & Options ---
HISTSIZE=5000
SAVEHIST=5000
HISTFILE=~/.zsh_history
setopt HIST_IGNORE_ALL_DUPS
setopt SHARE_HISTORY
setopt AUTO_CD             # Type directory name to cd into it
setopt NOMATCH             # Better globbing handling

# --- Modern Aliases (Requires: eza, bat, fzf) ---
alias ls='eza --icons --group-directories-first'
alias ll='eza -l --icons --git'
alias cat='bat --style=plain'
alias ..='cd ..'
alias grep='grep --color=auto'
alias update='sudo pacman -Syu'

# --- Paths ---
export PATH="$HOME/.local/bin:$PATH"

# --- GPU / Mesa Optimizations ---
export RADV_PERFTEST=aco,ngg
export AMD_VULKAN_ICD=RADV
export mesa_glthread=true
export MESA_GL_VERSION_OVERRIDE=4.6

# --- Theme Configuration ---
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

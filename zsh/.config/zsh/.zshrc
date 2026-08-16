# .zshrc - zsh configuration entry point (interactive shells).

mkdir -p "$XDG_CACHE_HOME/zsh"
mkdir -p "$XDG_STATE_HOME/zsh"

# --- History ---
HISTSIZE=100000
SAVEHIST=100000
HISTFILE="$XDG_STATE_HOME/zsh/history"
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_dups
setopt hist_reduce_blanks

# --- Options ---
setopt auto_cd
setopt extended_glob
setopt no_beep

# --- Plugins (zinit) ---
source "$ZDOTDIR/plugins.zsh"

# --- Completion (after plugins so compdefs register) ---
autoload -Uz compinit
compinit -d "$XDG_CACHE_HOME/zsh/zcompdump"
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' menu select

# --- Integrations ---
eval "$(zoxide init zsh)"
eval "$(fnm env --use-on-cd --shell zsh)"
if command -v pay-respects >/dev/null 2>&1; then
  eval "$(pay-respects zsh --alias)"
fi

# --- Config modules ---
source "$ZDOTDIR/aliases.zsh"
source "$ZDOTDIR/bindings.zsh"
source "$ZDOTDIR/prompt.zsh"

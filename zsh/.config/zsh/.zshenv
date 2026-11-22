# .zshenv - environment for every zsh instance (interactive or not).

: "${XDG_CACHE_HOME:=$HOME/.cache}"
: "${XDG_STATE_HOME:=$HOME/.local/state}"

export PATH="$HOME/.npm-global/bin:$HOME/.opencode/bin:$HOME/.local/bin:$PATH"

export EDITOR="nvim"
export VISUAL="nvim"

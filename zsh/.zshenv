# .zshenv - bootstrap: point zsh at the config dir, then load its env.

export ZDOTDIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
[[ -f "$ZDOTDIR/.zshenv" ]] && . "$ZDOTDIR/.zshenv"

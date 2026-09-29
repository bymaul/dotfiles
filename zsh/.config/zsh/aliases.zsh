# aliases.zsh - aliases and helper functions.

alias cat=bat
alias vim=nvim
alias lg=lazygit
alias oc=opencode
alias rf=rainfrog
alias ls="eza -a -l --header --icons --hyperlink --time-style relative"
alias tree="eza --tree --icons -I 'node_modules'"
alias nah="git reset --hard;git clean -df"

mkcd() { mkdir -p -- "$1" && cd -- "$1"; }

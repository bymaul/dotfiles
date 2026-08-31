# aliases.zsh - aliases and helper functions.

alias cat=bat
alias vim=nvim
alias lg=lazygit
alias oc=opencode
alias ls="eza -a -l --header --icons --hyperlink --time-style relative"
alias nah="git reset --hard;git clean -df"

mkcd() { mkdir -p -- "$1" && cd -- "$1"; }

zsh_stats() { fc -l 1 | awk '{cmd[$2]++; n++} END {for (c in cmd) print cmd[c], c}' | sort -rn | head -20; }

# aliases.zsh - aliases and helper functions.

alias cat=bat
alias vim=nvim
alias lg=lazygit
alias oc=opencode
alias ls="eza -a -l --header --icons --hyperlink --time-style relative"
alias nah="git reset --hard;git clean -df"

mkcd() { mkdir -p -- "$1" && cd -- "$1"; }

extract() {
  if [ -z "$1" ]; then
    echo "usage: extract <archive>"
    return 1
  fi
  case "$1" in
    *.tar.gz|*.tgz)   tar xzf "$1" ;;
    *.tar)            tar xf "$1" ;;
    *.zip)            unzip "$1" ;;
    *.7z)             7z x "$1" ;;
    *.rar)            unrar x "$1" ;;
    *)                echo "extract: unknown archive type: $1" ;;
  esac
}

zsh_stats() { fc -l 1 | awk '{cmd[$2]++; n++} END {for (c in cmd) print cmd[c], c}' | sort -rn | head -20; }

path() { echo -e "${PATH//:/\\n}"; }

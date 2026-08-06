ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

if [ ! -d "$ZINIT_HOME" ]; then
	mkdir -p "$(dirname $ZINIT_HOME)"
	git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

source "${ZINIT_HOME}/zinit.zsh"

# Setup Prompt
zinit ice from"gh-r" as"command" atload'eval "$(starship init zsh)"'
zinit load starship/starship

# Zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions

# Load completions
autoload -U compinit && compinit

# History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_dups
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_find_no_dups
setopt hist_reduce_blanks
setopt hist_verify
setopt hist_no_store

# Completion Styles
zstyle 'completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# Aliases
alias cat=bat
alias vim=nvim
alias lg=lazygit
alias oc=opencode
alias ls="eza -a -l --header --icons --hyperlink --time-style relative $1"
alias nah="git reset --hard;git clean -df"

# User scripts
export PATH="$HOME/.local/bin:$PATH"

# fnm
FNM_PATH="/home/maul/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="/home/maul/.local/share/fnm:$PATH"
  eval "`fnm env`"
fi

# Shell Integrations
eval "$(fnm env --use-on-cd --shell zsh)"
eval "$(zoxide init zsh)"

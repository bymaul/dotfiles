# plugins.zsh - plugin manager bootstrap and plugin loading.

ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
ZINIT_REF="${ZINIT_REF:-v3.17.0}"

if [ ! -d "$ZINIT_HOME" ]; then
  mkdir -p "$(dirname "$ZINIT_HOME")"
  git clone --depth 1 --branch "$ZINIT_REF" https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

source "${ZINIT_HOME}/zinit.zsh"

# Update with: zinit self-update && zinit update
zinit light zsh-users/zsh-syntax-highlighting

zinit ice wait"0" lucid depth=1 pick"deja.plugin.zsh"
zinit light Giammarco-Ferranti/deja

zinit ice from"gh-r" as"command" atload'eval "$(starship init zsh)"'
zinit load starship/starship

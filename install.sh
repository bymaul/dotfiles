#!/usr/bin/env bash
# install.sh - link dotfiles into $HOME with GNU Stow. Idempotent: safe to re-run.
#
#   ./install.sh          install (stow packages, warn on missing deps)
#
# The repo is a stow directory: each app lives in its own flat package dir
# (e.g. waybar/ -> ~/.config/waybar, zsh/ -> ~/.zshrc). No .config/ nesting.
# Unmanaged dirs (dconf, mozilla, ...) are left alone.

set -euo pipefail

REPO="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"

log()  { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m==>\033[0m %s\n' "$*" >&2; }

# package -> target (relative to $HOME). Stow requires the target to exist.
PKGS=(
    "hypr .config/hypr"
    "waybar .config/waybar"
    "mako .config/mako"
    "rofi .config/rofi"
    "kitty .config/kitty"
    "bat .config/bat"
    "btop .config/btop"
    "gtk .config"
    "lazygit .config/lazygit"
    "nvim .config/nvim"
    "opencode .config/opencode"
    "starship .config"
    "wleave .config/wleave"
    "yazi .config/yazi"
    "zsh ."
    "tmux ."
    "bin .local/bin"
    "vague-theme .local/share/themes/Vague"
)

command -v stow >/dev/null 2>&1 || { echo "error: GNU stow is required (pacman -S stow)" >&2; exit 1; }

log "installing dotfiles from $REPO"

# migrate: remove symlinks from previous installers whose (resolved) target
# points into the repo. Handles absolute links from the old install.sh and
# relative stow links alike, including dangling ones.
migrated=0
while IFS= read -r link; do
    case "$(readlink -f "$link")" in
        "$REPO"/*) rm "$link"; migrated=1 ;;
    esac
done < <(find "$HOME" -maxdepth 6 -type l 2>/dev/null)
[ "$migrated" -eq 0 ] || log "removed legacy symlinks"

for entry in "${PKGS[@]}"; do
    pkg="${entry%% *}"
    target="${entry#* }"
    mkdir -p "$HOME/$target"
    stow --dir "$REPO" --target "$HOME/$target" -S "$pkg"
done
log "stowed ${#PKGS[@]} packages"

# register vendored bat theme
if command -v bat >/dev/null 2>&1; then
    bat cache --build >/dev/null 2>&1 && log "rebuilt bat cache"
fi

# reload Hyprland if it's running
if command -v hyprctl >/dev/null 2>&1 && [ -n "${WAYLAND_DISPLAY:-}" ]; then
    hyprctl reload >/dev/null 2>&1 && log "reloaded Hyprland"
fi

# requirements check (warn-only; full list in README)
log "checking requirements"
missing=0
for bin in hyprctl waybar mako rofi kitty nvim tmux zsh starship lazygit \
           yazi eza bat fd btop wl-copy wl-paste grim slurp cliphist jq \
           playerctl brightnessctl notify-send pipewire swaybg stow pay-respects; do
    if ! command -v "$bin" >/dev/null 2>&1; then
        printf '  \033[1;31m%s\033[0m missing\n' "$bin"
        missing=1
    fi
done
[ "$missing" -eq 0 ] || warn "some requirements are missing - see README.md"

cat <<EOF

done. next steps:
  exec zsh                 # restart the shell to pick up the new config
  chsh -s /usr/bin/zsh     # once: make zsh the default shell
  hyprctl reload           # after starting Hyprland, if not reloaded above
EOF

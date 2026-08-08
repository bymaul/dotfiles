#!/usr/bin/env bash
# install.sh — link dotfiles into $HOME. Idempotent: safe to re-run.
#
#   ./install.sh          install (link configs, warn on missing deps)
#
# The repo mirrors $HOME: .config/<app>, .local/bin, .local/share/themes,
# .tmux.conf, .zshrc. Unmanaged dirs (dconf, mozilla, ...) are left alone.

set -euo pipefail
shopt -s nullglob

REPO="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"

log()  { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m==>\033[0m %s\n' "$*" >&2; }

# link <repo-relative path> -> $HOME/<path>
link() {
    local rel="$1"
    local dest="$HOME/$rel"
    if [ -e "$dest" ] && [ ! -L "$dest" ]; then
        warn "skip $rel: $dest exists and is not a symlink"
        return 0
    fi
    mkdir -p "$(dirname "$dest")"
    ln -sfn "$REPO/$rel" "$dest"
    log "linked  $rel"
}

[ -d "$REPO/.config" ] || { echo "error: no .config/ in $REPO" >&2; exit 1; }

log "installing dotfiles from $REPO"

# whole-dir symlinks for .config apps
for entry in "$REPO"/.config/*; do
    name="$(basename "$entry")"
    [ "$name" = "lazygit" ] && continue   # lazygit: dir stays real, link file below
    link ".config/$name"
done
# lazygit keeps a real dir (the app creates it); link only config.yml
link ".config/lazygit/config.yml"

link ".local/bin"
link ".local/share/themes"
link ".tmux.conf"
link ".zshrc"

mkdir -p "$HOME/Pictures/Wallpapers"
log "prepared ~/Pictures/Wallpapers"

# register vendored bat theme (vague)
if command -v bat >/dev/null 2>&1; then
    bat cache --build >/dev/null 2>&1 && log "rebuilt bat cache (vague theme)"
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
           playerctl brightnessctl notify-send pipewire awww; do
    if ! command -v "$bin" >/dev/null 2>&1; then
        printf '  \033[1;31m%s\033[0m missing\n' "$bin"
        missing=1
    fi
done
[ "$missing" -eq 0 ] || warn "some requirements are missing — see README.md"

cat <<EOF

done. next steps:
  source ~/.zshrc            # apply zsh config to the current shell
  chsh -s /usr/bin/zsh       # once: make zsh the default shell
  hyprctl reload             # after starting Hyprland, if not reloaded above
EOF

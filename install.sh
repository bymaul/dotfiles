#!/usr/bin/env bash
# install.sh - link dotfiles into $HOME with plain symlinks. Idempotent: safe to re-run.
#
#   ./install.sh                   install (link packages, warn on missing deps)
#   ./install.sh --remove [pkg...] unlink packages (default: all of them)
#
# Each app lives in its own flat package dir (e.g. waybar/ -> ~/.config/waybar).
# Dedicated app dirs are folded into ONE symlink, so files added to the repo
# later show up automatically. Shared parents (~/.config root, $HOME,
# ~/.local/bin) get their entries linked individually. Unmanaged dirs
# (dconf, mozilla, ...) are left alone.

set -euo pipefail

REPO="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"

log()  { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m==>\033[0m %s\n' "$*" >&2; }

usage() {
    sed -n '2,5p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

# mode package -> target (relative to $HOME).
# "dir"  fold whole package into a single symlink
# "tree" link each entry into an existing shared target
PKGS=(
    "dir hypr .config/hypr"
    "dir waybar .config/waybar"
    "dir mako .config/mako"
    "dir rofi .config/rofi"
    "dir kitty .config/kitty"
    "dir bat .config/bat"
    "dir btop .config/btop"
    "dir fastfetch .config/fastfetch"
    "tree gtk .config"
    "dir lazygit .config/lazygit"
    "dir nvim .config/nvim"
    "dir opencode .config/opencode"
    "tree starship .config"
    "dir wleave .config/wleave"
    "dir yazi .config/yazi"
    "tree zsh ."
    "dir tmux .config/tmux"
    "tree bin .local/bin"
    "dir vague-theme .local/share/themes/Vague"
)

MODE=install
ONLY=()
while (($#)); do
    case "$1" in
        -R | --remove) MODE=remove ;;
        -h | --help) usage; exit 0 ;;
        -*) echo "error: unknown option: $1" >&2; exit 1 ;;
        *) ONLY+=("$1") ;;
    esac
    shift
done

wanted() {  # true when no package filter given, or $1 is in it
    local pkg=$1 p
    ((${#ONLY[@]})) || return 0
    for p in "${ONLY[@]}"; do
        [ "$p" = "$pkg" ] && return 0
    done
    return 1
}

if ((${#ONLY[@]})); then
    known=$(printf '%s\n' "${PKGS[@]}" | awk '{print $2}')
    for p in "${ONLY[@]}"; do
        grep -qx "$p" <<<"$known" || { echo "error: unknown package: $p" >&2; exit 1; }
    done
fi

if [ "$MODE" = remove ]; then
    log "unlinking packages managed from $REPO"
else
    log "installing dotfiles from $REPO"
fi

# migrate: remove legacy ABSOLUTE symlinks written by old installers.
# Relative links are left for the logic below to sort out.
migrated=0
while IFS= read -r link; do
    case "$(readlink "$link")" in
        "$REPO"/*) rm "$link"; migrated=1 ;;
    esac
done < <(find "$HOME" -maxdepth 6 -type l 2>/dev/null)
[ "$migrated" -eq 0 ] || log "removed legacy symlinks"

# migrate: tmux config moved to ~/.config/tmux
if [ -L "$HOME/.tmux.conf" ]; then
    case "$(readlink -f "$HOME/.tmux.conf")" in
        "$REPO"/*) rm "$HOME/.tmux.conf"; log "removed legacy ~/.tmux.conf" ;;
    esac
fi

# true when every direct entry of dir $1 is a symlink resolving into $REPO
managed_dir() {
    local dir=$1 entry
    [ -d "$dir" ] && [ ! -L "$dir" ] || return 1
    while IFS= read -r -d '' entry; do
        [ -L "$entry" ] || return 1
        case "$(readlink -f "$entry")" in
            "$REPO"/*) ;;
            *) return 1 ;;
        esac
    done < <(find "$dir" -mindepth 1 -maxdepth 1 -print0)
}

# replace fully-managed real dir $1 with a single symlink to $2.
collapse_to_link() {
    local dir=$1 src=$2
    managed_dir "$dir" || return 1
    find "$dir" -mindepth 1 -maxdepth 1 -delete
    rmdir "$dir"
    ln -s "$(realpath --relative-to="$(dirname "$dir")" "$src")" "$dir"
}

# fold pkg $1 into ONE symlink at target $2 (relative to $HOME).
fold_pkg() {
    local pkg=$1 rel=$2 dest="$HOME/$2"
    mkdir -p "$(dirname "$dest")"

    if [ -L "$dest" ]; then
        if [ "$(readlink -f "$dest")" != "$REPO/$pkg" ]; then
            warn "$rel is a symlink out of our control - skipping $pkg"
        fi
    elif [ -e "$dest" ]; then
        if collapse_to_link "$dest" "$REPO/$pkg"; then
            log "folding $rel"
        else
            warn "$rel holds unmanaged content - skipping $pkg (resolve manually)"
        fi
    else
        ln -s "$(realpath --relative-to="$(dirname "$dest")" "$REPO/$pkg")" "$dest"
    fi
}

# link every entry of src dir $1 into dst dir $2. Dir entries become a single
# symlink when the destination is missing, ours already, or a fully-managed
# real dir; otherwise we recurse into both sides (shared dirs like ~/.config).
link_tree() {
    local src=$1 dst=$2 entry name sub
    mkdir -p "$dst"
    while IFS= read -r -d '' entry; do
        name="$(basename "$entry")"
        sub="$dst/$name"
        if [ -d "$entry" ] && [ ! -L "$entry" ]; then
            if [ -L "$sub" ] || [ ! -e "$sub" ]; then
                ln -sfn "$(realpath --relative-to="$dst" "$entry")" "$sub"
            elif collapse_to_link "$sub" "$entry"; then
                log "folding ${sub#"$HOME"/}"
            elif [ -d "$sub" ]; then
                link_tree "$entry" "$sub"
            else
                warn "$sub exists and is not ours - skipping"
            fi
            continue
        fi
        if [ -e "$sub" ] && [ ! -L "$sub" ]; then
            warn "$sub exists and is not ours - skipping"
            continue
        fi
        ln -sfn "$(realpath --relative-to="$dst" "$entry")" "$sub"
    done < <(find "$src" -mindepth 1 -maxdepth 1 -print0 | sort -z)
}

# unlink a folded package: its single symlink, or a legacy per-entry layout
remove_fold() {
    local pkg=$1 rel=$2 dest="$HOME/$2"
    if [ -L "$dest" ]; then
        case "$(readlink -f "$dest")" in
            "$REPO"/*) rm "$dest"; log "removed $rel" ;;
            *) warn "$rel is a symlink out of our control - leaving it ($pkg)" ;;
        esac
    elif [ -d "$dest" ] && managed_dir "$dest"; then
        find "$dest" -mindepth 1 -maxdepth 1 -delete
        rmdir "$dest"
        log "removed $rel"
    elif [ -e "$dest" ]; then
        warn "$rel holds unmanaged content - leaving it ($pkg)"
    fi
}

# unlink every entry of src dir $1 from dst dir $2 (inverse of link_tree)
remove_tree() {
    local src=$1 dst=$2 entry name sub
    while IFS= read -r -d '' entry; do
        name="$(basename "$entry")"
        sub="$dst/$name"
        if [ -L "$sub" ]; then
            case "$(readlink -f "$sub")" in
                "$REPO"/*) rm "$sub" ;;
                *) warn "$sub is a symlink out of our control - leaving it" ;;
            esac
        elif [ -d "$sub" ] && [ -d "$entry" ] && [ ! -L "$entry" ]; then
            if managed_dir "$sub"; then
                find "$sub" -mindepth 1 -maxdepth 1 -delete
                rmdir "$sub"
            else
                remove_tree "$entry" "$sub"
            fi
        elif [ -e "$sub" ] || [ -L "$sub" ]; then
            warn "$sub is not ours - leaving it"
        fi
    done < <(find "$src" -mindepth 1 -maxdepth 1 -print0 | sort -z)
}

count=0
for entry in "${PKGS[@]}"; do
    read -r mode pkg target <<<"$entry"
    wanted "$pkg" || continue
    case "$mode" in
        dir)
            if [ "$MODE" = remove ]; then remove_fold "$pkg" "$target"; else fold_pkg "$pkg" "$target"; fi
            ;;
        tree)
            if [ "$MODE" = remove ]; then remove_tree "$REPO/$pkg" "$HOME/$target"; else link_tree "$REPO/$pkg" "$HOME/$target"; fi
            ;;
    esac
    count=$((count + 1))
done

if [ "$MODE" = remove ]; then
    log "unlinked ${count} package(s)"
    exit 0
fi

log "linked ${count} package(s)"

# register vendored bat theme
if command -v bat >/dev/null 2>&1; then
    bat cache --build >/dev/null 2>&1 && log "rebuilt bat cache"
fi

# tpm + tmux plugins: with the config folded at ~/.config/tmux, TPM keeps
# plugins there too. Clone anything declared as "@plugin 'owner/repo'".
plugins_dir="$HOME/.config/tmux/plugins"
if [ ! -d "$plugins_dir/tpm" ]; then
    git clone -q https://github.com/tmux-plugins/tpm "$plugins_dir/tpm" && log "installed tpm"
fi
conf="$HOME/.config/tmux/tmux.conf"
[ -f "$conf" ] && while IFS= read -r repo; do
    name="${repo##*/}"
    if [ ! -d "$plugins_dir/$name" ]; then
        git clone -q "https://github.com/$repo" "$plugins_dir/$name" && log "installed $name"
    fi
done < <(sed -n "s/^set -g @plugin '\([^']*\)'.*/\1/p" "$conf")

# reload Hyprland if it's running
if command -v hyprctl >/dev/null 2>&1 && [ -n "${WAYLAND_DISPLAY:-}" ]; then
    hyprctl reload >/dev/null 2>&1 && log "reloaded Hyprland"
fi

# requirements check (warn-only; full list in README)
log "checking requirements"
missing=0
for bin in hyprctl waybar mako rofi kitty nvim tmux zsh starship lazygit \
           yazi eza bat fd btop wl-copy wl-paste grim slurp cliphist jq \
           playerctl brightnessctl notify-send pipewire swaybg pay-respects fastfetch; do
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

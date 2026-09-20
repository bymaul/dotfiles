#!/usr/bin/env bash
# install.sh - link dotfiles into $HOME with plain symlinks. Idempotent: safe to re-run.
#
#   ./install.sh [--dry-run] [--verify] [--backup] [--no-plugins] [--category CAT]... [pkg...]
#   ./install.sh --remove [--category CAT]... [pkg...]

set -euo pipefail

REPO="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"

DRY_RUN=0
VERIFY=0
BACKUP=0
NO_PLUGINS=0
BACKUP_DIR="${DOT_BACKUP_DIR:-$HOME/.local/share/dotfiles-backup/$(date +%Y%m%d-%H%M%S)}"

log()  { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m==>\033[0m %s\n' "$*" >&2; }
dry()  { printf '  \033[1;33mdry-run\033[0m %s\n' "$*"; }

usage() {
    sed -n '2,5p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
    printf 'options:\n'
    printf '  -n, --dry-run    print actions without changing anything\n'
    printf '  --verify         check links only, exit non-zero on mismatch\n'
    printf '  --backup         move unmanaged files to $HOME/.local/share/dotfiles-backup/<date>/ instead of skipping\n'
    printf '  --no-plugins     skip tpm clone, bat cache rebuild and hypr reload\n'
    printf 'categories:\n'
    for c in desktop shell tools; do printf '  %s: %s\n' "$c" "${CATS[$c]}"; done
}

PKGS=(
    "dir hypr .config/hypr"
    "dir quickshell .config/quickshell"
    "dir kitty .config/kitty"
    "dir bat .config/bat"
    "dir btop .config/btop"
    "dir fastfetch .config/fastfetch"
    "tree gtk .config"
    "dir lazygit .config/lazygit"
    "dir nvim .config/nvim"
    "dir opencode .config/opencode"
    "tree starship .config"
    "dir mise .config/mise"
    "dir yazi .config/yazi"
    "tree zsh ."
    "dir tmux .config/tmux"
    "tree bin .local/bin"
    "dir vague-theme .local/share/themes/Vague"
)

declare -A CATS=(
    [desktop]="hypr quickshell gtk vague-theme"
    [shell]="zsh starship tmux mise"
    [tools]="kitty bat btop fastfetch lazygit nvim opencode yazi bin"
)

MODE=install
ONLY=()
while (($#)); do
    case "$1" in
        -R | --remove) MODE=remove ;;
        -n | --dry-run) DRY_RUN=1 ;;
        --verify) VERIFY=1; DRY_RUN=1 ;;
        --backup) BACKUP=1 ;;
        --no-plugins) NO_PLUGINS=1 ;;
        -C | --category | --only)
            [ $# -ge 2 ] || { echo "error: $1 needs a category name" >&2; exit 1; }
            [[ -v CATS[$2] ]] || { echo "error: unknown category: $2" >&2; exit 1; }
            read -r -a _expand <<<"${CATS[$2]}"
            ONLY+=("${_expand[@]}")
            shift
            ;;
        -h | --help) usage; exit 0 ;;
        -*) echo "error: unknown option: $1" >&2; exit 1 ;;
        *) ONLY+=("$1") ;;
    esac
    shift
done

wanted() {
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

VERIFY_FAIL=0
verify_fail() { printf '  \033[1;31mmismatch\033[0m %s\n' "$*" >&2; VERIFY_FAIL=$((VERIFY_FAIL + 1)); }

backup_unmanaged() {
    local dest=$1 rel=${1#"$HOME"/}
    local target="$BACKUP_DIR/$rel"
    if [ "$DRY_RUN" -eq 1 ]; then
        dry "would back up $rel to ${target}"
        return 0
    fi
    mkdir -p "$(dirname "$target")"
    mv "$dest" "$target"
    log "backed up $rel to ${target}"
}

make_link() {
    local src=$1 dest=$2 rel=${2#"$HOME"/}
    if [ "$DRY_RUN" -eq 1 ]; then
        dry "would link $rel -> $src"
        return 0
    fi
    ln -sfn "$(realpath --relative-to="$(dirname "$dest")" "$src")" "$dest"
}

if [ "$VERIFY" -eq 0 ] && [ "$MODE" = install ]; then
    migrated=0
    for root in "$HOME/.config" "$HOME/.local/bin" "$HOME/.local/share/themes" "$HOME/.zshenv" "$HOME/.tmux.conf"; do
        [ -e "$root" ] || [ -L "$root" ] || continue
        roots=()
        if [ -L "$root" ]; then
            roots=("$root")
        else
            while IFS= read -r -d '' l; do roots+=("$l"); done < <(find "$root" -maxdepth 4 -type l -print0 2>/dev/null)
        fi
        for link in "${roots[@]}"; do
            case "$(readlink "$link")" in
                "$REPO"/*)
                    if [ "$DRY_RUN" -eq 1 ]; then dry "would remove legacy symlink $link"; else rm "$link"; fi
                    migrated=1
                    ;;
            esac
        done
    done
    [ "$migrated" -eq 0 ] || log "removed legacy symlinks"
fi

if [ -L "$HOME/.tmux.conf" ]; then
    case "$(readlink -f "$HOME/.tmux.conf")" in
        "$REPO"/*)
            if [ "$DRY_RUN" -eq 1 ]; then dry "would remove legacy ~/.tmux.conf"; else rm "$HOME/.tmux.conf"; log "removed legacy ~/.tmux.conf"; fi
            ;;
    esac
fi

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

is_shared_root() {
    local d=${1//\/.\//\/}
    d=${d%/.}
    case "$d" in
        "$HOME" | "$HOME/.config" | "$HOME/.local" | "$HOME/.local/bin" | "$HOME/.local/share" | "$HOME/.local/share/themes") return 0 ;;
    esac
    return 1
}

collapse_to_link() {
    local dir=$1 src=$2
    is_shared_root "$dir" && return 1
    managed_dir "$dir" || return 1
    if [ "$DRY_RUN" -eq 1 ]; then
        dry "would fold ${dir#"$HOME"/} -> $src"
        return 0
    fi
    find "$dir" -mindepth 1 -maxdepth 1 -delete
    rmdir "$dir"
    ln -s "$(realpath --relative-to="$(dirname "$dir")" "$src")" "$dir"
}

fold_pkg() {
    local pkg=$1 rel=$2 dest="$HOME/$2"
    if [ "$VERIFY" -eq 1 ]; then
        if [ -L "$dest" ] && [ "$(readlink -f "$dest")" = "$REPO/$pkg" ]; then return 0; fi
        verify_fail "$rel should link to $REPO/$pkg"
        return 0
    fi
    [ "$DRY_RUN" -eq 0 ] && mkdir -p "$(dirname "$dest")"

    if [ -L "$dest" ]; then
        if [ "$(readlink -f "$dest")" != "$REPO/$pkg" ]; then
            warn "$rel is a symlink out of our control - skipping $pkg"
        fi
    elif [ -e "$dest" ]; then
        if collapse_to_link "$dest" "$REPO/$pkg"; then
            [ "$DRY_RUN" -eq 0 ] && log "folding $rel"
        elif [ "$BACKUP" -eq 1 ]; then
            backup_unmanaged "$dest"
            make_link "$REPO/$pkg" "$dest"
        else
            warn "$rel holds unmanaged content - skipping $pkg (resolve manually or re-run with --backup)"
        fi
    else
        make_link "$REPO/$pkg" "$dest"
    fi
}

link_tree() {
    local src=$1 dst=$2 entry name sub
    if [ "$VERIFY" -eq 0 ] && [ "$DRY_RUN" -eq 0 ]; then mkdir -p "$dst"; fi
    while IFS= read -r -d '' entry; do
        name="$(basename "$entry")"
        sub="$dst/$name"
        if [ -d "$entry" ] && [ ! -L "$entry" ]; then
            if [ "$VERIFY" -eq 1 ]; then
                if [ -L "$sub" ] && [ "$(readlink -f "$sub")" = "$entry" ]; then continue; fi
                if [ -d "$sub" ] && [ ! -L "$sub" ] && { is_shared_root "$sub" || ! managed_dir "$sub"; }; then
                    verify_tree "$entry" "$sub"
                    continue
                fi
                verify_fail "${sub#"$HOME"/} should link to $entry"
                continue
            fi
            if [ -L "$sub" ] || [ ! -e "$sub" ]; then
                if [ -L "$sub" ] && [ "$(readlink -f "$sub")" = "$entry" ]; then continue; fi
                if [ "$DRY_RUN" -eq 1 ]; then dry "would link ${sub#"$HOME"/} -> $entry"; else ln -sfn "$(realpath --relative-to="$dst" "$entry")" "$sub"; fi
            elif collapse_to_link "$sub" "$entry"; then
                [ "$DRY_RUN" -eq 0 ] && log "folding ${sub#"$HOME"/}"
            elif [ -d "$sub" ]; then
                link_tree "$entry" "$sub"
            elif [ "$BACKUP" -eq 1 ]; then
                backup_unmanaged "$sub"
                make_link "$entry" "$sub"
            else
                warn "$sub exists and is not ours - skipping (re-run with --backup to move it aside)"
            fi
            continue
        fi
        if [ "$VERIFY" -eq 1 ]; then
            if [ -L "$sub" ] && [ "$(readlink -f "$sub")" = "$entry" ]; then continue; fi
            verify_fail "${sub#"$HOME"/} should link to $entry"
            continue
        fi
        if [ -e "$sub" ] && [ ! -L "$sub" ]; then
            if [ "$BACKUP" -eq 1 ]; then
                backup_unmanaged "$sub"
                make_link "$entry" "$sub"
            else
                warn "$sub exists and is not ours - skipping (re-run with --backup to move it aside)"
            fi
            continue
        fi
        if [ "$DRY_RUN" -eq 1 ]; then
            if [ ! -L "$sub" ] || [ "$(readlink -f "$sub")" != "$entry" ]; then dry "would link ${sub#"$HOME"/} -> $entry"; fi
        else
            ln -sfn "$(realpath --relative-to="$dst" "$entry")" "$sub"
        fi
    done < <(find "$src" -mindepth 1 -maxdepth 1 -print0 | sort -z)
}

verify_tree() {
    local src=$1 dst=$2 entry name sub
    while IFS= read -r -d '' entry; do
        name="$(basename "$entry")"
        sub="$dst/$name"
        if [ -d "$entry" ] && [ ! -L "$entry" ] && [ -d "$sub" ] && [ ! -L "$sub" ] && { is_shared_root "$sub" || ! managed_dir "$sub"; }; then
            verify_tree "$entry" "$sub"
        elif [ -L "$sub" ] && [ "$(readlink -f "$sub")" = "$entry" ]; then
            continue
        else
            verify_fail "${sub#"$HOME"/} should link to $entry"
        fi
    done < <(find "$src" -mindepth 1 -maxdepth 1 -print0 | sort -z)
}

remove_fold() {
    local pkg=$1 rel=$2 dest="$HOME/$2"
    if [ -L "$dest" ]; then
        case "$(readlink -f "$dest")" in
            "$REPO"/*)
                if [ "$DRY_RUN" -eq 1 ]; then dry "would remove $rel"; else rm "$dest"; log "removed $rel"; fi
                ;;
            *) warn "$rel is a symlink out of our control - leaving it ($pkg)" ;;
        esac
    elif [ -d "$dest" ] && managed_dir "$dest"; then
        if [ "$DRY_RUN" -eq 1 ]; then dry "would remove $rel"; else find "$dest" -mindepth 1 -maxdepth 1 -delete; rmdir "$dest"; log "removed $rel"; fi
    elif [ -e "$dest" ]; then
        warn "$rel holds unmanaged content - leaving it ($pkg)"
    fi
}

remove_tree() {
    local src=$1 dst=$2 entry name sub
    while IFS= read -r -d '' entry; do
        name="$(basename "$entry")"
        sub="$dst/$name"
        if [ -L "$sub" ]; then
            case "$(readlink -f "$sub")" in
                "$REPO"/*) if [ "$DRY_RUN" -eq 1 ]; then dry "would remove ${sub#"$HOME"/}"; else rm "$sub"; fi ;;
                *) warn "$sub is a symlink out of our control - leaving it" ;;
            esac
        elif [ -d "$sub" ] && [ -d "$entry" ] && [ ! -L "$entry" ]; then
            if managed_dir "$sub"; then
                if [ "$DRY_RUN" -eq 1 ]; then dry "would remove ${sub#"$HOME"/}"; else find "$sub" -mindepth 1 -maxdepth 1 -delete; rmdir "$sub"; fi
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

if [ "$VERIFY" -eq 1 ]; then
    if [ "$VERIFY_FAIL" -eq 0 ]; then log "verified ${count} package(s)"; else warn "verified ${count} package(s) with $VERIFY_FAIL mismatch(s)"; fi
    exit "$([ "$VERIFY_FAIL" -eq 0 ] && echo 0 || echo 1)"
fi

if [ "$MODE" = remove ]; then
    log "unlinked ${count} package(s)"
    exit 0
fi

if [ "$DRY_RUN" -eq 1 ]; then
    log "dry-run: ${count} package(s), nothing changed"
    exit 0
fi

log "linked ${count} package(s)"

if [ "$NO_PLUGINS" -eq 0 ]; then
    if command -v bat >/dev/null 2>&1; then
        bat cache --build >/dev/null 2>&1 && log "rebuilt bat cache"
    fi

    # tpm bootstrap lives here; tmux.conf only sources it at runtime.
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

    if command -v hyprctl >/dev/null 2>&1 && [ -n "${WAYLAND_DISPLAY:-}" ]; then
        hyprctl reload >/dev/null 2>&1 && log "reloaded Hyprland"
    fi
fi

log "checking requirements (details: dot-doctor)"
missing=0
for bin in hyprctl quickshell kitty nvim tmux zsh starship lazygit \
           yazi eza bat fd btop wl-copy wl-paste cliphist jq mise \
           brightnessctl notify-send pipewire fastfetch upower loginctl; do
    if ! command -v "$bin" >/dev/null 2>&1; then
        printf '  \033[1;31m%s\033[0m missing\n' "$bin"
        missing=1
    fi
done
[ "$missing" -eq 0 ] || warn "some requirements are missing - see README.md (pkglist.txt) or run dot-doctor"

cat <<EOF

done. next steps:
  exec zsh
  chsh -s /usr/bin/zsh
  hyprctl reload
EOF

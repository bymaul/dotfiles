# dotfiles

Minimal Hyprland desktop config, managed with GNU Stow.

![screenshot](screenshot.png)

## Setup

```sh
git clone https://github.com/bymaul/dotfiles ~/dotfiles
# install requirements (below), then:
~/dotfiles/install.sh
```

Or without the script (same thing, manual):

```sh
cd ~/dotfiles
stow -t ~/.config/hypr hypr
stow -t ~/.config/waybar waybar
stow -t ~ zsh tmux
stow -t ~/.local/bin bin
# ... full package -> target list lives in install.sh
```

The repo is a stow directory: each app is a flat package dir whose contents
mirror its real location in `$HOME` (e.g. `waybar/config.jsonc` ->
`~/.config/waybar/config.jsonc`, `zsh/.config/zsh/.zshrc` ->
`~/.config/zsh/.zshrc`, `zsh/.zshenv` -> `~/.zshenv`). `install.sh`
stows every package into place without touching anything else (unmanaged dirs
like `dconf`/`mozilla` stay as-is). Uninstall a package with
`stow -t <target> -D <pkg>`.

## Requirements

- **stow** (symlink management)
- **Hyprland** >= 0.56 (Lua config), **waybar**, **mako**, **rofi**, **kitty**, **nemo**
- **wleave** (build from source), **swaybg** (wallpaper, `pacman -S swaybg`)
- **nvim**, **tmux**, **zsh**, **starship**, **lazygit**, **yazi**, **eza**, **bat**, **fd**, **btop**
- **pay-respects** (fixes typos: press F or type `f`; AUR `pay-respects`)
- **pipewire**, **brightnessctl**, **libnotify**, **wl-clipboard**, **grim**, **slurp**, **cliphist**, **playerctl**, **jq**, **polkit-kde-agent**
- **Nerd Font**

## Two-repo sync

Shared configs (`nvim`, `starship`, `bat`, `lazygit`, `opencode`, `zsh`, `tmux`)
are mirrored into [`bymaul/winfiles`](https://github.com/bymaul/winfiles)
(Windows + WSL) via `.github/workflows/sync.yml`. A push touching a shared
package opens a sync PR in the other repo (auto-merged if clean, manual if
conflicted). Set a PAT (`repo` scope) as the `GH_TOKEN` secret in both repos.

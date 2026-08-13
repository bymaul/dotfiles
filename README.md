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
stow -t ~ .tmux.conf .zshrc .local
stow -t ~ .config/*
hyprctl reload
source ~/.zshrc
```

The repo mirrors `$HOME` directly: `.config/…`, `.local/…`, `.tmux.conf`, `.zshrc`. Stow symlinks each app dir into place without touching anything else (unmanaged dirs like `dconf`/`mozilla` stay as-is).

## Requirements

- **Hyprland** >= 0.56 (Lua config), **waybar**, **mako**, **rofi**, **kitty**, **nemo**
- **wleave** (build from source), **swaybg** (wallpaper, `pacman -S swaybg`)
- **nvim**, **tmux**, **zsh**, **starship**, **lazygit**, **yazi**, **eza**, **bat**, **fd**, **btop**
- **pipewire**, **brightnessctl**, **libnotify**, **wl-clipboard**, **grim**, **slurp**, **cliphist**, **playerctl**, **jq**, **polkit-kde-agent**
- **Nerd Font**

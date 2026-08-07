# dotfiles

Minimal Hyprland desktop config, managed with GNU Stow.

Vague, everywhere.

## Setup

```sh
git clone https://github.com/bymaul/dotfiles ~/dotfiles
cd ~/dotfiles
# install requirements (below)
stow -d ~/dotfiles -t ~ bat bin btop gtk hypr kitty lazygit mako nvim opencode rofi starship tmux waybar wleave zsh
mkdir -p ~/Pictures/Wallpapers
hyprctl reload
source ~/.zshrc
```

## Requirements

- **Hyprland** >= 0.56 (Lua config), **waybar**, **mako**, **rofi**, **kitty**, **nemo**
- **wleave** (build from source), **awww** (wallpaper daemon, `pacman -S awww`)
- **nvim**, **tmux**, **zsh**, **starship**, **lazygit**, **eza**, **bat**, **fd**, **btop**
- **pipewire**, **brightnessctl**, **libnotify**, **wl-clipboard**, **grim**, **slurp**, **cliphist**, **playerctl**, **jq**, **polkit-kde-agent**
- **JetBrainsMono Nerd Font**

## Notes

- `bin` installs to `~/.local/bin` and provides `osd-volume`, `osd-brightness`, `ws-cycle`, `wallpaper`.
- `bat` ships a vendored `vague.tmTheme`; run `bat cache --build` after stowing to register the `vague` theme.
- `awww-daemon` autostarts on login (3s delay to dodge a startup page-flip race) and restores the last wallpaper. `SUPER+W` cycles `~/Pictures/Wallpapers` — drop your own images there.
- `SUPER+Tab` cycles only used workspaces (via `ws-cycle`).
- `hyprctl dispatch` uses Lua expressions (`hl.dsp.*`) — the legacy `dispatch workspace N` syntax is gone.

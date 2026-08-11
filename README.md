# dotfiles

Minimal Hyprland desktop config, managed with GNU Stow.

Vague, everywhere.

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
- **JetBrainsMono Nerd Font**

## Notes

- All configs use the **vague** palette — keep new colors on-theme: bg `#141415`, fg `#cdcdcd`, dim `#606079`, accent `#7e98e8`, light accent `#aeaed1`, warning `#f3be7c`, error/critical `#d8647e`. (Rendered reds in gtk-dark.css are Adwaita base, not vague — trust `vague.tmTheme`.)
- `.local/bin` installs to `~/.local/bin` and provides `osd-volume`, `osd-brightness`, `ws-cycle`, `caffeine-toggle`, `caffeine-status`, `dnd-toggle`, `dnd-status`, `screenshot`, `clipboard-pick`.
- `SUPER+V` opens the cliphist/rofi picker and pastes the selection into the previously focused window; `SUPER+SHIFT+V` deletes an entry, `SUPER+SHIFT+BackSpace` clears the history.
- `bat` ships a vendored `vague.tmTheme`; run `bat cache --build` after stowing to register the `vague` theme.
- `yazi` ships a vendored `vague.yazi` flavor; `theme.toml` sets `[flavor] dark = "vague"`.
- `swaybg` sets the wallpaper from `wallpaper.jpg` at the repo root on login — swap that file to change it. `SUPER+SHIFT+C` toggles caffeine mode, which blocks idle blanking/suspend via `systemd-inhibit`. `SUPER+SHIFT+D` toggles mako do-not-disturb mode (`[mode=dnd] invisible=1`, the toggle's own confirmation still shows); both toggles signal waybar for an instant indicator update. The two indicators live in a `group/modes` block before the power button: coffee glyph (caffeine on), bell-slash (DnD on).
- `Print` / `SUPER+Print` screenshot a region / full screen: saved to `~/Pictures/Screenshots`, copied to the clipboard, and confirmed with a notification — the popup is clickable (accent border = has actions): left-click opens the file, middle-click shows an Open / Copy path menu.
- mako: `on-button-left` dismisses; actionable notifications invoke their default action instead; middle-click runs `makoctl menu` via rofi to pick any action.
- `SUPER+Tab` cycles only used workspaces (via `ws-cycle`).
- `hyprctl dispatch` uses Lua expressions (`hl.dsp.*`) — the legacy `dispatch workspace N` syntax is gone.

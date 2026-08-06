# dotfiles

Monochrome, minimal Hyprland desktop config, managed with GNU Stow.

Dark, unrounded UI with a slightly transparent, blurred glass look: mako OSD for volume/brightness, wleave logout, Adwaita-dark GTK theme, Windows-style used-workspace cycling. Desktop overlays are pure black/white; terminal apps (nvim, tmux, kitty, starship, btop, lazygit) share the gray-black **oxocarbon** palette.

## Packages

| Package    | Contents                                                        |
|------------|-----------------------------------------------------------------|
| `bin`      | `osd-volume`, `osd-brightness`, `ws-cycle`, `wallpaper` scripts (`~/.local/bin`) |
| `btop`     | Resource monitor (oxocarbon theme, no rounded corners)          |
| `gtk`      | GTK3/GTK4 dark theme + font settings                            |
| `htop`     | Process viewer (monochrome default scheme)                      |
| `hypr`     | Hyprland config (`hyprland.lua`, Lua-based, Hyprland 0.56+), `hypridle.conf`, `hyprlock.conf` |
| `kitty`    | Terminal config (oxocarbon palette)                             |
| `lazygit`  | Git TUI theme (oxocarbon)                                       |
| `mako`     | Notification daemon (incl. OSD rules for volume/brightness)     |
| `nvim`     | Neovim config (`vim.pack` plugins, oxocarbon colorscheme)       |
| `opencode` | opencode agent config (runtime files are gitignored)            |
| `rofi`     | App launcher config + themes                                    |
| `starship` | Shell prompt (minimal, oxocarbon)                               |
| `tmux`     | tmux config (prefix `C-s`, hand-rolled oxocarbon statusbar)     |
| `waybar`   | Waybar bar config + style                                       |
| `wleave`   | Wayland logout overlay (built from source)                      |
| `zsh`      | Zsh config (zinit + starship + syntax highlighting, aliases)    |

## Requirements

Distro-agnostic names; Arch/Pacman examples shown.

### Core

- **Hyprland** >= 0.56 with Lua config support
- **waybar**, **mako**, **rofi** (or `rofi-wayland`), **kitty**, **nemo**
- **wleave** — build from source:
  - `git clone https://github.com/atkrad/wleave` + deps
  - deps: `gtk4`, `libadwaita`, `gtk-layer-shell`, `cargo`, `meson`, `ninja`
- **pipewire** + **wireplumber** (provides `wpctl`)
- **brightnessctl**, **libnotify** (`notify-send`), **wl-clipboard**
- **grim**, **slurp**, **cliphist** (screenshot bind), **playerctl** (media keys)
- **awww** — wallpaper daemon (AUR `awww`; ships both `awww` + `awww-daemon`, or build from Codeberg `LGFae/awww`)
- **jq** (used by `ws-cycle`)
- **polkit-kde-agent** (GUI auth; autostarted from `hyprland.lua`)
- **stow**, **git**

### Shell

- **zsh** + **zinit** (installs itself on first `zsh` run)
- **starship**, **eza**, **bat**, **fd** (aliases in `.zshrc`)
- **tmux**, **neovim**, **btop**, **htop**, **lazygit**

### Services / waybar modules

- **upower** (battery), **NetworkManager** (network), **pipewire-pulse** (pulseaudio), **bluez** (bluetooth)

### Fonts

- **JetBrainsMono Nerd Font** (terminal, waybar, rofi, GTK)
- Nerd Font symbols for waybar/rofi icons

## Installation

```sh
# 1. Clone
git clone <your-dotfiles-repo> ~/dotfiles
cd ~/dotfiles

# 2. Install requirements (see above)

# 3. Stow everything
stow -d ~/dotfiles -t ~ bin btop gtk htop hypr kitty lazygit mako nvim opencode rofi starship tmux waybar wleave zsh

# 4. Apply
hyprctl reload        # Hyprland config (full re-login for hyprland.start hooks)
source ~/.zshrc       # shell
# restart GTK apps (or log out / back in) for the dark theme
```

## Notes

- `bin` installs to `~/.local/bin` (added to `PATH` in `.zshrc`). Hyprland binds use absolute paths — Hyprland's `PATH` and the Lua autostart do not include `~/.local/bin`.
- `ws-cycle` drives `SUPER+Tab` / `SUPER+SHIFT+Tab` — cycles only *used* workspaces, Windows-style. (No built-in Hyprland dispatcher does this; script uses `hyprctl workspaces -j`.)
- Wallpapers: `awww-daemon` is autostarted from `hyprland.lua` and restores the last wallpaper from its cache; `SUPER+W` cycles `~/Pictures/Wallpapers` via the `wallpaper` script.
- Terminal apps share the **oxocarbon** dark palette (`#161616` background). kitty defines the ANSI `color0`–`color15` from oxocarbon, so TUIs (htop, btop, lazygit) stay consistent.
- `hyprctl dispatch` uses Lua expressions (`hl.dsp.*`) under Lua config — the legacy `dispatch workspace N` syntax is gone.
- `opencode` package ships config only; opencode generates its runtime (`node_modules/`, `package*.json`) on first launch — gitignored.
- Dark mode comes from the `gtk` package + `gsettings` (`color-scheme=prefer-dark`).
- Volume/brightness keys route through `osd-*` scripts → mako OSD with progress bar. Text sits on the progress strip, so the strip is dimmed (`over #ffffff33`).
- wleave blur is set via Hyprland layer rule + `wleave/style.css` (`rgba(0,0,0,0.85)`).

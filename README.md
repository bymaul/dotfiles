# dotfiles

Minimal Hyprland desktop config, managed with plain symlinks.

![screenshot](screenshot.png)

## Setup

```sh
git clone https://github.com/bymaul/dotfiles ~/dotfiles
~/dotfiles/install.sh
```

The script is idempotent - safe to re-run at any time. Each app is a flat
package dir whose contents mirror its real location in `$HOME`
(e.g. `kitty/` -> `~/.config/kitty`, `zsh/.zshenv` -> `~/.zshenv`).
Dedicated app dirs are folded into a single symlink
(`~/.config/nvim -> ~/dotfiles/nvim`), so new files show up automatically.
Shared targets (`~`, `~/.config` root, `~/.local/bin`) get their entries
linked individually; re-run `./install.sh` after adding new top-level files
to those packages. Unmanaged dirs like `dconf`/`mozilla` are left alone.

Unlink again with `./install.sh --remove`, optionally limited to specific
packages (e.g. `./install.sh --remove nvim bin`). Anything not managed by
the repo is never touched.

## Requirements

- **Hyprland** >= 0.56 (Lua config), **hypridle**, **hyprpolkitagent**, **quickshell**
- **kitty**, **nemo**, **nvim**, **tmux**, **zsh**, **starship**, **lazygit**
- **yazi**, **eza**, **bat**, **fd**, **btop**, **fastfetch**, **mise**
- **pipewire**, **brightnessctl**, **upower**, **libnotify**, **wl-clipboard**, **cliphist**, **jq**
- **systemd** (provides `loginctl` for lid/power handling, `systemd-inhibit` for caffeine)
- **power-profiles-daemon** (optional: power-profile switching in the power menu)
- **Nerd Font**

## Power management

Idle dim/lock/DPMS/suspend is owned by quickshell (Settings popup, System
tab writes `hypridle.conf`). Battery warnings, critical-battery action and
power profiles live in `quickshell/services/Power.qml` (status + profiles in
the power menu). Lid close / power button actions are honored by
systemd-logind:

```sh
qs-power-logind --apply
```

Reboot afterwards - logind only reads the drop-in at startup.

Do not run `xfce4-power-manager` alongside this setup - it takes a logind
block inhibitor for lid/power keys. Uninstall it:

```sh
sudo pacman -Rns xfce4-power-manager && pkill xfce4-power-manager
```

## Two-repo sync

Shared configs (`nvim`, `starship`, `bat`, `lazygit`, `opencode`, `zsh`, `tmux`,
`fastfetch`)
are mirrored into [`bymaul/winfiles`](https://github.com/bymaul/winfiles)
(Windows + WSL) via `.github/workflows/sync.yml`. A push touching a shared
package opens a sync PR in the other repo (auto-merged if clean, manual if
conflicted). Set a PAT (`repo` scope) as the `GH_TOKEN` secret in both repos.

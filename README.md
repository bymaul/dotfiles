# dotfiles

Minimal Hyprland desktop config, managed with plain symlinks.

![screenshot](screenshot.png)

## Setup

```sh
git clone https://github.com/bymaul/dotfiles ~/dotfiles
cd ~/dotfiles
sudo pacman -S --needed - < pkglist.txt
./install.sh
```

- Each app dir mirrors its location in `$HOME` and is linked in (`~/.config/nvim -> ~/dotfiles/nvim`); new files inside show up automatically.
- Shared targets (`~`, `~/.config`, `~/.local/bin`) link per-file - re-run `./install.sh` after adding top-level files there.
- Idempotent and safe to re-run; `./install.sh --remove [packages...]` unlinks again. Anything unmanaged is never touched unless you pass `--backup` (moves it to `~/.local/share/dotfiles-backup/<date>/`). Preview with `./install.sh --dry-run`, check with `./install.sh --verify`.
- After cloning: `mise trust && mise install`.

## Requirements

See `pkglist.txt` (official repos, including `quickshell`).

Plus a **Nerd Font**, and **starship** (installed via `zinit` from GitHub releases on first `zsh` run). power-profiles-daemon is optional - only for power-profile switching.

## Power management

Idle dim/lock/DPMS/suspend is owned by quickshell (Settings popup, System tab writes `hypridle.conf`). The power button is handled live by quickshell per the System tab setting. Lid close goes through systemd-logind:

```sh
qs-power-logind --apply
```

Reboot afterwards - logind only reads the drop-in at startup.

## Two-repo sync

Shared configs (`nvim`, `starship`, `bat`, `lazygit`, `opencode`, `zsh`, `tmux`, `fastfetch`, `git`) mirror into [`bymaul/winfiles`](https://github.com/bymaul/winfiles) via a sync workflow; pushes touching them open an auto-merged PR there. Needs a `repo`-scoped PAT as `GH_TOKEN` in both repos.

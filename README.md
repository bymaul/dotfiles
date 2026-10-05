# dotfiles

Minimal Hyprland desktop.

![screenshot](screenshot.png)

## Setup

```sh
git clone https://github.com/bymaul/dotfiles ~/dotfiles
cd ~/dotfiles
sudo pacman -S --needed - < pkglist.txt
./install.sh
```

- Desktop, shell, and terminal configs live here; `install.sh` symlinks them into `$HOME`.
- Safe to re-run. Useful flags: `--dry-run`, `--verify`, `--backup`, `--remove`, `--category desktop|shell|tools`.

## Notes

- Needs a Nerd Font. `starship` installs itself on first `zsh` run.
- Power, display scale, and theming live in the Settings popup. Lid-close handling needs `qs-power-logind --apply` + reboot.
- Tweak Hyprland directly in `hypr/hyprland.lua`.
- ASUS laptops only: `sudo pacman -S asusctl` unlocks Quiet / Balanced / Performance + charge limit.

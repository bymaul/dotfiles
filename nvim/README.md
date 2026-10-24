# nvim

A lean Neovim 0.12+ config built on native `vim.pack` (no plugin manager).

Part of [dotfiles](https://github.com/bymaul/dotfiles) — installed as the `nvim`
extra via `./install.sh --category extras` or `./install.sh nvim`.

## Requirements

- Neovim 0.12 or newer
- `git`, `make`, `unzip`, and a C compiler
- `ripgrep`, `fd`

## Installation

Via dotfiles:

```sh
git clone https://github.com/bymaul/dotfiles ~/dotfiles
cd ~/dotfiles
./install.sh --category extras   # or: ./install.sh nvim
```

This links `nvim/` to `~/.config/nvim`. Plugins are installed on first launch.
LSP servers and formatters are auto-installed via mason on startup.

Want just the editor config? Link it manually:

```sh
# Linux / macOS
ln -s "$(pwd)/nvim" "${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
```

```powershell
# Windows (pwsh)
New-Item -ItemType Junction -Path "$env:LOCALAPPDATA\nvim" -Target "$PWD\nvim"
```

## Structure

```
init.lua                    entry point
lua/core/                   core setup: options, autocmds, keymaps, package manager
lua/plugins/                per-plugin config, auto-discovered
lsp/                        per-server LSP config, discovered from runtimepath
```

## Credits

- [Advent of Neovim](https://www.youtube.com/watch?v=TQn2hJeHQbM&list=PLep05UYkc6wTyBe7kPjQFWVXTlhKeQejM)
- [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim)

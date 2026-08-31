# nvim

A lean Neovim 0.12+ config built on native `vim.pack` (no plugin manager).

## Requirements

- Neovim 0.12 or newer
- `git`, `make`, `unzip`, and a C compiler
- `ripgrep`, `fd`

## Installation

This config lives inside [winfiles](https://github.com/bymaul/winfiles) and is
linked into place by its installers:

- Windows: `.\install.ps1` (junctions `%LOCALAPPDATA%\nvim`)
- WSL / Linux / macOS: `winfiles/install-wsl.sh` (links `~/.config/nvim`)

Want just the editor config? Link the `nvim/` directory manually:

```sh
# Linux / macOS
git clone https://github.com/bymaul/winfiles.git
ln -s "$(pwd)/winfiles/nvim" "${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
```

```powershell
# Windows (pwsh)
git clone https://github.com/bymaul/winfiles.git
New-Item -ItemType Junction -Path "$env:LOCALAPPDATA\nvim" -Target "$PWD\winfiles\nvim"
```

Plugins are installed on first launch. LSP servers and formatters are
auto-installed via mason on startup.

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

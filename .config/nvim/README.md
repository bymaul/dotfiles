# config.nvim

## Required

- `git`, `make`, `unzip`, and a C compiler
- `ripgrep`, `fd`
- `tree-sitter` CLI (>= 0.25) — nvim-treesitter builds parsers on install

<details>
<summary>Windows treesitter toolchain</summary>

Parsers are compiled at startup, so Windows needs a C compiler the `tree-sitter` CLI can drive.

1. Install Zig: `choco install zig`
2. Point the compiler at a `zig cc` shim and relocate zig's cache (takes effect in new terminals):

   ```
   setx CC C:\zig-shim\zigcc.exe
   setx ZIG_LOCAL_CACHE_DIR C:\zig-cache
   setx ZIG_GLOBAL_CACHE_DIR C:\zig-cache
   ```

3. Exclude the cache dir from Defender (zig's Windows cache can corrupt, causing `CacheCheckFailed`):
   `Add-MpPreference -ExclusionPath C:\zig-cache` (admin PowerShell)

The shim exists because the `tree-sitter` CLI passes `--target=x86_64-pc-windows-msvc`, which zig can't parse; the shim forwards every arg to `zig cc` and rewrites that target to `x86_64-windows-gnu`. Create `C:\zig-shim\shim.c` with the source below, then build it:

```
zig cc shim.c -o zigcc.exe
```

```c
#include <errno.h>
#include <process.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char **argv)
{
    char **args = calloc((size_t)argc + 2, sizeof *args);
    if (args == NULL) return 2;
    args[0] = "zig";
    args[1] = "cc";
    int n = 2;
    for (int i = 1; i < argc; i++) {
        const char *a = argv[i];
        if (strncmp(a, "--target=", 9) == 0 && strstr(a, "windows") != NULL) {
            a = "--target=x86_64-windows-gnu";
        }
        args[n++] = (char *)a;
    }
    args[n] = NULL;
    intptr_t status = _spawnvp(_P_WAIT, "zig", args);
    free(args);
    if (status == -1) {
        fprintf(stderr, "zigcc shim: cannot spawn zig: %s\n", strerror(errno));
        return 127;
    }
    return (int)(status & 0xff);
}
```
</details>

## Installation

Linux and Mac

```sh
git clone https://github.com/bymaul/config.nvim.git "${XDG_CONFIG_HOME:-$HOME/.config}"/nvim
```

Windows

`cmd.exe`:

```
git clone https://github.com/bymaul/config.nvim.git "%localappdata%\nvim"
```

`pwsh.exe`

```
git clone https://github.com/bymaul/config.nvim.git "${env:LOCALAPPDATA}\nvim"
```

## Structure

```
init.lua                    entry point
lua/core/                   core setup: options, autocmds, keymaps, package manager
lua/plugins/                per-plugin config, installed via vim.pack.add
```

The config uses Neovim 0.11's built-in `vim.pack.add` package manager instead of
lazy.nvim. Each plugin has its own file under `lua/plugins/`; everything is lazy-loaded
by loading on the relevant event, keymap, or autocmd.

## Credits to

- [Advent of Neovim](https://www.youtube.com/watch?v=TQn2hJeHQbM&list=PLep05UYkc6wTyBe7kPjQFWVXTlhKeQejM)
- [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim)

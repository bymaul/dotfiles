require("vim._core.ui2").enable {}

local o = vim.opt

-- Line numbers
o.number = true
o.relativenumber = true

-- Indentation
o.expandtab = true
o.shiftwidth = 2
o.smartindent = true
o.tabstop = 2

-- Scrolling & cursor
o.scrolloff = 10
o.cursorline = true
o.cursorlineopt = "number"
o.updatetime = 250

-- UI
o.mouse = "a"
o.showmode = false
o.signcolumn = "yes"
o.timeoutlen = 300
o.wrap = false

-- Folding
o.foldmethod = "expr"
o.foldexpr = "v:lua.vim.treesitter.foldexpr()"
o.foldlevel = 99
o.foldlevelstart = 99
o.foldminlines = 2
o.foldnestmax = 8

-- Searching
o.ignorecase = true
o.smartcase = true
o.inccommand = "split"

-- Splits
o.splitbelow = true
o.splitright = true

-- Editing
o.undofile = true
o.confirm = true
o.autoread = true

-- Invisible characters
o.list = true
o.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- Clipboard
vim.schedule(function()
  o.clipboard = "unnamedplus"
end)

-- UI
o.winborder = "rounded"

-- Shell
o.shell = vim.uv.os_uname().sysname:find "Windows" and "pwsh" or "zsh"

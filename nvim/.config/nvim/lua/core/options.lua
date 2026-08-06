local o = vim.opt

-- Line numbers & scrolling
o.number = true
o.relativenumber = true
o.scrolloff = 10

-- UI settings
o.cursorline = true
o.cursorlineopt = "number"
o.wrap = false
o.showmode = false
o.mouse = "a"
o.signcolumn = "yes"
o.timeoutlen = 300
o.updatetime = 250

-- Folding (treesitter)
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
o.splitright = true
o.splitbelow = true

-- Persistent undo
o.undofile = true

-- List characters
o.list = true
o.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- Clipboard
vim.schedule(function()
  o.clipboard = "unnamedplus"
end)

-- Shell selection
o.shell = vim.uv.os_uname().sysname:find "Windows" and "pwsh" or "zsh"

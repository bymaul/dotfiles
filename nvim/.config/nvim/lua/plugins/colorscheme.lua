vim.cmd.packadd "tokyonight.nvim"
require("tokyonight").setup {
  transparent = true,
  italic_comments = true,
}
vim.cmd "colorscheme tokyonight"

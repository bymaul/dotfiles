vim.cmd.packadd "mason.nvim"
vim.cmd.packadd "mason-lspconfig.nvim"
vim.cmd.packadd "mason-tool-installer.nvim"

local servers = require("plugins.lsp.servers")

require("mason").setup()
require("mason-lspconfig").setup()

require("mason-tool-installer").setup {
  ensure_installed = vim.iter({ servers, { "prettierd", "stylua" } }):flatten():totable(),
}

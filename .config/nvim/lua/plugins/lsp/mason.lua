vim.cmd.packadd "mason.nvim"
vim.cmd.packadd "mason-lspconfig.nvim"
vim.cmd.packadd "mason-tool-installer.nvim"

local servers = require("plugins.lsp.servers")

require("mason").setup()
require("mason-lspconfig").setup {
  automatic_installation = true,
  ensure_installed = servers,
}

require("mason-tool-installer").setup {
  ensure_installed = {
    "prettierd",
    "stylua",
  },
}

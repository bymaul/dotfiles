vim.cmd.packadd "mason.nvim"
vim.cmd.packadd "mason-lspconfig.nvim"
vim.cmd.packadd "mason-tool-installer.nvim"

require("mason").setup()
require("mason-lspconfig").setup {
  automatic_installation = true,
  ensure_installed = {
    "lua_ls",
    "ts_ls",
    "tailwindcss",
    "gopls",
    "intelephense",
    "emmet_ls",
  },
}

require("mason-tool-installer").setup {
  ensure_installed = {
    "prettierd",
    "stylua",
    "eslint_d",
  },
}

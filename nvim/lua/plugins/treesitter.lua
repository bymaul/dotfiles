local parsers =
  { "bash", "css", "go", "html", "javascript", "json", "lua", "markdown", "php", "tsx", "typescript", "yaml" }

require("nvim-treesitter").setup {
  install_dir = vim.fn.stdpath "data" .. "/site",
}

require("nvim-treesitter").install(parsers)

require("nvim-ts-autotag").setup()

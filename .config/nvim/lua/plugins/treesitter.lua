vim.cmd.packadd "nvim-treesitter"

local parsers = {
  "lua", "typescript", "tsx", "javascript",
  "html", "markdown", "markdown_inline", "php",
}

vim.schedule(function()
  require("nvim-treesitter.install").install(parsers)
end)

vim.cmd.packadd "nvim-ts-autotag"
require("nvim-ts-autotag").setup()

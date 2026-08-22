vim.cmd.packadd "conform.nvim"

local conform = require "conform"

conform.setup {
  notify_on_error = false,
  format_on_save = function(bufnr)
    local disable_filetypes = { c = true, cpp = true }
    if disable_filetypes[vim.bo[bufnr].filetype] then
      return nil
    else
      return {
        timeout_ms = 500,
        lsp_format = "fallback",
      }
    end
  end,
  formatters_by_ft = {
    javascript = { "prettierd" },
    typescript = { "prettierd" },
    javascriptreact = { "prettierd" },
    typescriptreact = { "prettierd" },
    css = { "prettierd" },
    html = { "prettierd" },
    json = { "prettierd" },
    yaml = { "prettierd" },
    markdown = { "prettierd" },
    lua = { "stylua" },
  },
}

vim.keymap.set("n", "<leader>f", function()
  conform.format { async = true, lsp_format = "fallback" }
end, { desc = "Format buffer" })

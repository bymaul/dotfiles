require("mason").setup()
require("mason-lspconfig").setup()

vim.lsp.config("*", {
  capabilities = vim.tbl_deep_extend(
    "force",
    vim.lsp.protocol.make_client_capabilities(),
    require("blink.cmp").get_lsp_capabilities()
  ),
})

local servers = { "gopls", "intelephense", "lua_ls", "tailwindcss", "vtsls" }
vim.lsp.enable(servers)

require("mason-tool-installer").setup {
  ensure_installed = vim.iter({ servers, { "prettierd", "stylua" } }):flatten():totable(),
}

vim.diagnostic.config {
  update_in_insert = false,
  severity_sort = true,
  float = { border = "rounded", source = "if_many" },
  underline = { severity = { min = vim.diagnostic.severity.WARN } },
  signs = { text = { ERROR = "", WARN = "", INFO = "", HINT = "" } },
}

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(event)
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if client and client:supports_method("textDocument/documentHighlight", event.buf) then
      local group = vim.api.nvim_create_augroup("custom-lsp-highlight", { clear = false })
      vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
        buffer = event.buf,
        group = group,
        callback = vim.lsp.buf.document_highlight,
      })
      vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
        buffer = event.buf,
        group = group,
        callback = vim.lsp.buf.clear_references,
      })
    end
  end,
})

vim.api.nvim_create_autocmd("LspDetach", {
  callback = function(event)
    vim.lsp.buf.clear_references()
    vim.api.nvim_clear_autocmds { group = "custom-lsp-highlight", buffer = event.buf }
  end,
})

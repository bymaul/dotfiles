vim.cmd.packadd "mason.nvim"
vim.cmd.packadd "mason-lspconfig.nvim"
vim.cmd.packadd "mason-tool-installer.nvim"

require("mason").setup()
require("mason-lspconfig").setup()

vim.lsp.config("*", {
  capabilities = vim.tbl_deep_extend(
    "force",
    vim.lsp.protocol.make_client_capabilities(),
    require("blink.cmp").get_lsp_capabilities()
  ),
})

local servers = {
  "emmet_language_server",
  "gopls",
  "intelephense",
  "lua_ls",
  "tailwindcss",
  "vtsls",
}

vim.lsp.enable(servers)

require("mason-tool-installer").setup {
  ensure_installed = vim.iter({ servers, { "prettierd", "stylua" } }):flatten():totable(),
}

local signs = { ERROR = "", WARN = "", INFO = "", HINT = "" }
local diagnostic_signs = {}
for type, icon in pairs(signs) do
  diagnostic_signs[vim.diagnostic.severity[type]] = icon
end
vim.diagnostic.config {
  update_in_insert = false,
  severity_sort = true,
  float = { border = "rounded", source = "if_many" },
  underline = { severity = { min = vim.diagnostic.severity.WARN } },
  signs = { text = diagnostic_signs },
}

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("custom-lsp-attach", { clear = true }),
  callback = function(event)
    local client = vim.lsp.get_client_by_id(event.data.client_id)

    if client:supports_method("textDocument/foldingRange", event.buf) then
      local win = vim.api.nvim_get_current_win()
      vim.wo[win][0].foldexpr = "v:lua.vim.lsp.foldexpr()"
      vim.wo[win][0].foldtext = "v:lua.vim.lsp.foldtext()"
    end

    if client:supports_method("textDocument/documentHighlight", event.buf) then
      local highlight_group = vim.api.nvim_create_augroup("custom-lsp-highlight", { clear = false })
      vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
        buffer = event.buf,
        group = highlight_group,
        callback = vim.lsp.buf.document_highlight,
      })
      vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
        buffer = event.buf,
        group = highlight_group,
        callback = vim.lsp.buf.clear_references,
      })
    end
  end,
})

vim.api.nvim_create_autocmd("LspDetach", {
  group = vim.api.nvim_create_augroup("custom-lsp-detach", { clear = true }),
  callback = function(event)
    vim.lsp.buf.clear_references()
    vim.api.nvim_clear_autocmds { group = "custom-lsp-highlight", buffer = event.buf }
    for _, client in ipairs(vim.lsp.get_clients { bufnr = event.buf }) do
      if client.id ~= event.data.client_id and client:supports_method("textDocument/foldingRange", event.buf) then
        return
      end
    end
    for _, win in ipairs(vim.fn.win_findbuf(event.buf)) do
      vim.api.nvim_win_call(win, function()
        vim.api.nvim_buf_call(event.buf, function()
          vim.wo[0][0].foldexpr = nil
          vim.wo[0][0].foldtext = nil
        end)
      end)
    end
  end,
})

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("custom-lsp-attach", { clear = true }),
  callback = function(event)
    local map = function(keys, func, desc, mode)
      mode = mode or "n"
      vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
    end

    local function supports(cap)
      local clients = vim.lsp.get_clients { bufnr = event.buf }
      for _, client in ipairs(clients) do
        if client.server_capabilities[cap] then
          return true
        end
      end
      return false
    end

    map("K", vim.lsp.buf.hover, "[H]over documentation")
    map("gd", vim.lsp.buf.definition, "[G]oto [D]efinition")
    map("gr", vim.lsp.buf.references, "[G]oto [R]eferences")
    map("gI", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")
    map("<leader>D", require("telescope.builtin").lsp_type_definitions, "Type [D]efinition")
    map("<leader>ds", require("telescope.builtin").lsp_document_symbols, "[D]ocument [S]ymbols")
    map("<leader>ws", require("telescope.builtin").lsp_dynamic_workspace_symbols, "[W]orkspace [S]ymbols")
    map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
    map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction", { "n", "x" })
    if supports "declarationProvider" then
      map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
    end
    map("<leader>uh", function()
      vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled(), { bufnr = event.buf })
    end, "[U]i [H]ints toggle")

    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if client:supports_method("textDocument/foldingRange", event.buf) then
      local win = vim.api.nvim_get_current_win()
      vim.wo[win][0].foldexpr = "v:lua.vim.lsp.foldexpr()"
      vim.wo[win][0].foldtext = "v:lua.vim.lsp.foldtext()"
    end
  end,
})

vim.api.nvim_create_autocmd("LspDetach", {
  group = vim.api.nvim_create_augroup("custom-lsp-detach", { clear = true }),
  callback = function(event)
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

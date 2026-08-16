vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("custom-lsp-attach", { clear = true }),
  callback = function(event)
    local map = function(keys, func, desc, mode)
      mode = mode or "n"
      vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
    end

    local client = vim.lsp.get_client_by_id(event.data.client_id)

    map("K", vim.lsp.buf.hover, "[H]over documentation")
    map("gd", vim.lsp.buf.definition, "[G]oto [D]efinition")
    map("gr", vim.lsp.buf.references, "[G]oto [R]eferences")
    map("gI", vim.lsp.buf.implementation, "[G]oto [I]mplementation")
    map("<leader>D", vim.lsp.buf.type_definition, "Type [D]efinition")
    map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
    map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction", { "n", "x" })
    if client:supports_method("textDocument/declaration", event.buf) then
      map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
    end

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

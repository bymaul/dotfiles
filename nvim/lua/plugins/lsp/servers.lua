local servers = { "lua_ls", "vtsls", "tailwindcss", "gopls", "intelephense", "emmet_ls" }

vim.lsp.config("*", {
  capabilities = vim.tbl_deep_extend(
    "force",
    vim.lsp.protocol.make_client_capabilities(),
    require("blink.cmp").get_lsp_capabilities()
  ),
})

vim.lsp.config("lua_ls", {
  cmd = { "lua-language-server" },
  filetypes = { "lua" },
  root_markers = { ".luarc.json", "neorg.config" },
  settings = {
    Lua = {
      completion = {
        callSnippet = "Replace",
      },
      hint = {
        enable = true,
      },
    },
  },
})

vim.lsp.config("vtsls", {
  cmd = { "vtsls", "--stdio" },
  filetypes = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
  root_markers = { "package.json", "tsconfig.json", "jsconfig.json" },
  settings = {
    typescript = { suggest = { autoImports = true } },
    javascript = { suggest = { autoImports = true } },
  },
})

vim.lsp.config("tailwindcss", {
  cmd = { "tailwindcss-language-server", "--stdio" },
  filetypes = { "html", "css", "javascript", "typescript", "javascriptreact", "typescriptreact" },
  root_markers = { "tailwind.config.js", "tailwind.config.ts", "postcss.config.js", "postcss.config.mjs" },
})

vim.lsp.config("gopls", {
  cmd = { "gopls" },
  filetypes = { "go" },
  root_markers = { "go.mod", "go.sum" },
  settings = {
    gopls = {
      hints = {
        assignVariableTypes = true,
        compositeLiteralFields = true,
        functionTypeParameters = true,
        parameterNames = true,
        rangeVariableTypes = true,
      },
    },
  },
})

vim.lsp.config("intelephense", {
  cmd = { "intelephense", "--stdio" },
  filetypes = { "php" },
  root_markers = { "composer.json" },
})

vim.lsp.config("emmet_ls", {
  cmd = { "emmet-ls", "--stdio" },
  filetypes = { "html", "typescriptreact", "javascriptreact", "css", "sass", "scss", "less" },
})

vim.lsp.enable(servers)

return servers

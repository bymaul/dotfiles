return {
  cmd = { "vtsls", "--stdio" },
  filetypes = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
  root_markers = { "package.json", "tsconfig.json", "jsconfig.json" },
  settings = {
    typescript = { suggest = { autoImports = true } },
    javascript = { suggest = { autoImports = true } },
  },
}

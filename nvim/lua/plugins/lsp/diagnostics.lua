local signs = { ERROR = "", WARN = "", INFO = "", HINT = "" }
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

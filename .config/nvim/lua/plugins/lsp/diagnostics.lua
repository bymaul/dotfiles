local signs = { ERROR = "", WARN = "", INFO = "", HINT = "" }
local diagnostic_signs = {}
for type, icon in pairs(signs) do
  diagnostic_signs[vim.diagnostic.severity[type]] = icon
end
vim.diagnostic.config { signs = { text = diagnostic_signs } }

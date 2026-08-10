vim.cmd.packadd "mini.nvim"
require("mini.ai").setup { n_lines = 500 }
require("mini.pairs").setup()
require("mini.surround").setup()
require("mini.bracketed").setup()

local statusline = require "mini.statusline"
statusline.setup { use_icons = true }
statusline.section_location = function()
  return "%2l:%-2v"
end

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

local miniclue = require "mini.clue"
miniclue.setup {
  window = { delay = 50 },
  triggers = {
    { mode = { "n", "x" }, keys = "<Leader>" },
    { mode = "n", keys = "[" },
    { mode = "n", keys = "]" },
    { mode = { "n", "x" }, keys = "g" },
    { mode = "n", keys = "<C-w>" },
    { mode = { "n", "x" }, keys = "z" },
  },
  clues = {
    miniclue.gen_clues.square_brackets(),
    miniclue.gen_clues.g(),
    miniclue.gen_clues.windows(),
    miniclue.gen_clues.z(),
    { mode = "n", keys = "<Leader>h", desc = "+Git Hunk" },
    { mode = { "n", "x" }, keys = "<Leader>s", desc = "+Search" },
  },
}

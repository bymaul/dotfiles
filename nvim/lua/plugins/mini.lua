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
    { mode = { "n", "x" }, keys = "<Leader>c", desc = "+[C]ode" },
    { mode = { "n" }, keys = "<Leader>D", desc = "Type [D]efinition" },
    { mode = { "n" }, keys = "<Leader>f", desc = "[F]ormat buffer" },
    { mode = { "n", "v" }, keys = "<Leader>h", desc = "+Git [H]unk" },
    { mode = { "n" }, keys = "<Leader>q", desc = "Open diagnostic [Q]uickfix list" },
    { mode = { "n" }, keys = "<Leader>r", desc = "+[R]ename" },
    { mode = { "n" }, keys = "<Leader>s", desc = "+[S]earch" },
  },
}

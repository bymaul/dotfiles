vim.cmd.packadd "fff"

local fff = require "fff"
fff.setup {
  prompt = "❯ ",
  lazy_sync = true,
}

vim.keymap.set("n", "<leader>sf", fff.find_files, { desc = "[S]earch [F]iles" })
vim.keymap.set("n", "<leader>sg", fff.live_grep, { desc = "[S]earch by [G]rep" })
vim.keymap.set({ "n", "x" }, "<leader>sw", fff.live_grep_under_cursor, { desc = "[S]earch current [W]ord/Selection" })

vim.cmd.packadd "fff"

local fff = require "fff"
fff.setup {
  lazy_sync = true,
  prompt = "❯ ",
}

vim.keymap.set("n", "<leader>sf", fff.find_files, { desc = "Search Files" })
vim.keymap.set("n", "<leader>sg", fff.live_grep, { desc = "Search Grep" })
vim.keymap.set({ "n", "x" }, "<leader>sw", fff.live_grep_under_cursor, {
  desc = "Search Word",
})

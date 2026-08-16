vim.cmd.packadd "fff"

local fff = require "fff"
fff.setup {
  lazy_sync = true,
}

vim.keymap.set("n", "<leader>sf", fff.find_files, { desc = "[S]earch Files" })
vim.keymap.set("n", "<leader>sg", fff.live_grep, { desc = "[S]earch by [G]rep" })

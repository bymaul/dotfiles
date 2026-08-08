vim.cmd.packadd "telescope.nvim"
require("telescope").setup {
  extensions = {
    fzf = {},
  },
}
require("telescope").load_extension "fzf"
require("telescope").load_extension "ui-select"

local builtin = require "telescope.builtin"
vim.keymap.set("n", "<leader>sf", builtin.find_files, { desc = "[S]earch Files" })
vim.keymap.set("n", "<leader>sk", builtin.keymaps, { desc = "[S]earch [K]eymaps" })
vim.keymap.set("n", "<leader>sh", builtin.help_tags, { desc = "[S]earch [H]elp" })
vim.keymap.set("n", "<leader>sg", builtin.live_grep, { desc = "[S]earch by [G]rep" })
vim.keymap.set("n", "<leader>sr", builtin.resume, { desc = "[S]earch [R]esume" })
vim.keymap.set("n", "<leader><leader>", builtin.buffers, { desc = "[ ] Find existing buffers" })

vim.keymap.set("n", "<leader>sn", function()
  builtin.find_files { cwd = vim.fn.stdpath "config" }
end, { desc = "[S]earch [N]eovim files" })

local map = vim.keymap.set

-- General
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })
map("n", "<leader>w", "<cmd>write<CR>", { desc = "Save file" })
map("n", "<leader>q", "<cmd>quit<CR>", { desc = "Quit" })

-- Search
local fff = require "fff"
local fff_plus = require "fff_plus"

map("n", "<leader>sf", fff.find_files, { desc = "Search Files" })
map("n", "<leader>sg", fff.live_grep, { desc = "Search Grep" })
map("n", "<leader><leader>", fff_plus.buffers, { desc = "Search Buffers" })
map("n", "<leader>d", fff_plus.diagnostics, { desc = "Diagnostic Quickfix list" })

-- Format
map("n", "<leader>f", function()
  require("conform").format { async = true, lsp_format = "fallback" }
end, { desc = "Format buffer" })

-- Scrolling
map("n", "<C-d>", "<C-d>zz", { desc = "Scroll down" })
map("n", "<C-u>", "<C-u>zz", { desc = "Scroll up" })

-- Search navigation
map("n", "n", "nzzzv", { desc = "Next search result" })
map("n", "N", "Nzzzv", { desc = "Previous search result" })

-- Terminal
map("t", "<Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Files
map("n", "-", "<cmd>Oil<CR>", { desc = "Open parent directory" })

-- Visual
map("v", "<", "<gv", { desc = "Indent left" })
map("v", ">", ">gv", { desc = "Indent right" })
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move line down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move line up" })

local map = vim.keymap.set

-- General
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })
map("n", "<leader>w", "<cmd>write<CR>", { desc = "Save file" })
map("n", "<leader>q", "<cmd>quit<CR>", { desc = "Quit" })
map("n", "<leader>d", vim.diagnostic.setloclist, { desc = "Diagnostic Quickfix list" })

-- Search
map("n", "<leader>sf", function()
  require("fff").find_files()
end, { desc = "Search Files" })
map("n", "<leader>sg", function()
  require("fff").live_grep()
end, { desc = "Search Grep" })
map({ "n", "x" }, "<leader>sw", function()
  require("fff").live_grep_under_cursor()
end, { desc = "Search Word" })

-- Buffers
vim.keymap.set("n", "<leader><leader>", function()
  local buffers = vim.tbl_filter(function(buf)
    return vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted
  end, vim.api.nvim_list_bufs())

  vim.ui.select(buffers, {
    prompt = "Buffers:",
    format_item = function(buf)
      local name = vim.api.nvim_buf_get_name(buf)
      return name ~= "" and vim.fn.fnamemodify(name, ":~:.") or "[No Name]"
    end,
  }, function(buf)
    if buf then
      vim.api.nvim_set_current_buf(buf)
    end
  end)
end, { desc = "Find Buffers" })

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
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Files
map("n", "-", "<cmd>Oil<CR>", { desc = "Open parent directory" })

-- Visual
map("v", "<", "<gv", { desc = "Indent left" })
map("v", ">", ">gv", { desc = "Indent right" })
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move line down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move line up" })

vim.cmd.packadd "gitsigns.nvim"

require("gitsigns").setup {
  signs = {
    add = { text = "▎" },
    change = { text = "▎" },
    delete = { text = "" },
    topdelete = { text = "" },
    changedelete = { text = "▎" },
    untracked = { text = "▎" },
  },
  current_line_blame = false,
  on_attach = function(buffer)
    local gs = package.loaded.gitsigns
    local function map(l, r, desc)
      vim.keymap.set("n", l, r, { buffer = buffer, desc = desc })
    end

    map("]h", gs.next_hunk, "Next Hunk")
    map("[h", gs.prev_hunk, "Prev Hunk")
    map("<leader>hs", ":Gitsigns stage_hunk<CR>", "[S]tage Hunk")
    map("<leader>hr", ":Gitsigns reset_hunk<CR>", "[R]eset Hunk")
    map("<leader>hS", gs.stage_buffer, "[S]tage Buffer")
    map("<leader>hu", gs.undo_stage_hunk, "[U]ndo Stage Hunk")
    map("<leader>hR", gs.reset_buffer, "[R]eset Buffer")
    map("<leader>hb", gs.toggle_current_line_blame, "Toggle current line [b]lame")
  end,
}

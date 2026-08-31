local gs = require "gitsigns"
gs.setup {
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
    local function map(l, r, desc)
      vim.keymap.set("n", l, r, { buffer = buffer, desc = "Git: " .. desc })
    end

    map("]h", gs.next_hunk, "Next Hunk")
    map("[h", gs.prev_hunk, "Prev Hunk")
    map("<leader>hs", gs.stage_hunk, "Stage Hunk")
    map("<leader>hr", gs.reset_hunk, "Reset Hunk")
    map("<leader>hS", gs.stage_buffer, "Stage Buffer")
    map("<leader>hu", gs.undo_stage_hunk, "Undo Stage Hunk")
    map("<leader>hR", gs.reset_buffer, "Reset Buffer")
    map("<leader>hp", gs.preview_hunk, "Preview Hunk")
    map("<leader>hb", gs.toggle_current_line_blame, "Toggle blame")
  end,
}

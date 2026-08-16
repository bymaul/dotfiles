vim.cmd.packadd "oil.nvim"

require("oil").setup {
  default_file_explorer = true,
  skip_confirm_for_simple_edits = true,
  watch_for_changes = true,
  view_options = {
    show_hidden = true,
    natural_order = true,
    is_always_hidden = function(name, _)
      return name == ".." or name == ".git"
    end,
  },
}

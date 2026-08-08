vim.cmd.packadd "nvim-treesitter"
require("nvim-treesitter.config").setup {
  ensure_installed = { "lua", "typescript", "tsx", "javascript", "html", "markdown", "markdown_inline", "php" },
  auto_install = true,
  highlight = {
    enable = true,
    disable = function(_, buf)
      local max_filesize = 100 * 1024
      local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
      if ok and stats and stats.size > max_filesize then
        return true
      end
    end,
    additional_vim_regex_highlighting = false,
  },
}

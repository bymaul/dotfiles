vim.cmd.packadd "which-key.nvim"

require("which-key").setup {
  spec = {
    { "<leader>c", group = "[C]ode", mode = { "n", "x" } },
    { "<leader>r", group = "[R]ename" },
    { "<leader>s", group = "[S]earch" },
    { "<leader>h", group = "Git [H]unk", mode = { "n", "v" } },
  },
}

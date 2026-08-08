local data_site = vim.fn.stdpath "data" .. "/site"
if not vim.tbl_contains(vim.opt.packpath:get(), data_site) then
  vim.opt.packpath:prepend(data_site)
end

vim.api.nvim_create_autocmd("PackChanged", {
  group = vim.api.nvim_create_augroup("pack-build", { clear = true }),
  callback = function(ev)
    local name, kind = ev.data.spec.name, ev.data.kind
    if kind == "install" or kind == "update" then
      if name == "telescope-fzf-native.nvim" then
        vim.system({ "make" }, { cwd = ev.data.path })
      elseif name == "nvim-treesitter" then
        if ev.data.active then
          vim.cmd.TSUpdate()
        end
      end
    end
  end,
})

local gh = function(x)
  return "https://github.com/" .. x
end

vim.pack.add {
  gh "vague-theme/vague.nvim",
  { src = gh "saghen/blink.cmp", version = "v1" },
  gh "rafamadriz/friendly-snippets",
  gh "stevearc/conform.nvim",
  gh "lewis6991/gitsigns.nvim",
  gh "mfussenegger/nvim-lint",
  gh "nvim-treesitter/nvim-treesitter",
  gh "windwp/nvim-ts-autotag",
  gh "nvim-telescope/telescope.nvim",
  gh "nvim-lua/plenary.nvim",
  gh "nvim-telescope/telescope-fzf-native.nvim",
  gh "nvim-telescope/telescope-ui-select.nvim",
  gh "stevearc/oil.nvim",
  gh "echasnovski/mini.nvim",
  gh "folke/which-key.nvim",
  gh "williamboman/mason.nvim",
  gh "williamboman/mason-lspconfig.nvim",
  gh "WhoIsSethDaniel/mason-tool-installer.nvim",
  gh "neovim/nvim-lspconfig",
}

-- UI / appearance
require "plugins.colorscheme"
require "plugins.which-key"

-- Editing
require "plugins.mini"
require "plugins.blink"
require "plugins.conform"
require "plugins.treesitter"
require "plugins.ts-autotag"

-- Navigation
require "plugins.oil"
require "plugins.telescope"

-- Git
require "plugins.gitsigns"

-- LSP & linting
require "plugins.lsp"
require "plugins.lint"

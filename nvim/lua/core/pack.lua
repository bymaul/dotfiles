local data_site = vim.fn.stdpath "data" .. "/site"
if not vim.tbl_contains(vim.opt.packpath:get(), data_site) then
  vim.opt.packpath:prepend(data_site)
end

vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(ev)
    local name, kind = ev.data.spec.name, ev.data.kind
    if name == "fff" and (kind == "install" or kind == "update") then
      if not ev.data.active then
        vim.cmd.packadd "fff"
      end
      require("fff.download").download_or_build_binary()
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
  gh "nvim-treesitter/nvim-treesitter",
  gh "windwp/nvim-ts-autotag",
  gh "stevearc/oil.nvim",
  gh "echasnovski/mini.nvim",
  gh "williamboman/mason.nvim",
  gh "williamboman/mason-lspconfig.nvim",
  gh "WhoIsSethDaniel/mason-tool-installer.nvim",
  gh "NMAC427/guess-indent.nvim",
  gh "dmtrKovalenko/fff",
}

-- UI / appearance
require "plugins.colorscheme"

-- Editing
require "plugins.mini"
require "plugins.blink"
require "plugins.conform"
require "plugins.guess-indent"
require "plugins.treesitter"

-- Navigation
require "plugins.oil"
require "plugins.fff"

-- Git
require "plugins.gitsigns"

-- LSP
require "plugins.lsp"

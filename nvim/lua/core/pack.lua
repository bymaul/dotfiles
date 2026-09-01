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
      vim.schedule(function()
        if pcall(require, "fff.download") then
          require("fff.download").download_or_build_binary()
        end
      end)
    elseif name == "nvim-treesitter" and (kind == "install" or kind == "update") then
      if not ev.data.active then
        vim.cmd.packadd "nvim-treesitter"
      end
      vim.schedule(function()
        if pcall(require, "nvim-treesitter") then
          vim.cmd "TSUpdate"
        end
      end)
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
  gh "mason-org/mason.nvim",
  gh "mason-org/mason-lspconfig.nvim",
  gh "WhoIsSethDaniel/mason-tool-installer.nvim",
  gh "dmtrKovalenko/fff",
}

for _, plug in ipairs(vim.pack.get()) do
  if plug.active then
    vim.cmd.packadd(plug.spec.name)
  end
end

local M = {}

local function plugin_configs()
  local dir = vim.fn.stdpath "config" .. "/lua/plugins"
  local handle = vim.uv.fs_scandir(dir)
  local configs = {}
  while handle do
    local name, ftype = vim.uv.fs_scandir_next(handle)
    if not name then
      break
    end
    if ftype == "file" then
      configs[#configs + 1] = ("plugins.%s"):format(name:gsub("%.lua$", ""))
    end
  end
  return configs
end

local configs = plugin_configs()

for _, mod in ipairs(configs) do
  require(mod)
end

function M.check()
  local errors = {}
  for _, active in ipairs(vim.pack.get()) do
    if active.active then
      local target = vim.fs.normalize(active.path)
      local on_rtp = false
      for _, rtp in ipairs(vim.opt.runtimepath:get()) do
        if vim.fs.normalize(rtp) == target then
          on_rtp = true
          break
        end
      end
      if not on_rtp then
        errors[#errors + 1] = ("plugin not loaded: %s"):format(active.spec.name)
      end
    end
  end
  for _, mod in ipairs(configs) do
    if not pcall(require, mod) then
      errors[#errors + 1] = ("config failed to load: %s"):format(mod)
    end
  end
  if #errors > 0 then
    vim.notify("Plugin self-check failed:\n" .. table.concat(errors, "\n"), vim.log.levels.ERROR)
  end
end

return M

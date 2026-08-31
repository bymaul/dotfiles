require("blink.cmp").setup {
  keymap = { preset = "default" },
  appearance = {
    nerd_font_variant = "mono",
  },
  signature = { enabled = true },
  completion = {
    menu = {
      auto_show = true,
      draw = {
        columns = { { "kind_icon" }, { "label", "label_description", gap = 1 } },
      },
    },
    documentation = {
      auto_show = true,
      auto_show_delay_ms = 200,
    },
    list = {
      selection = {
        preselect = true,
        auto_insert = false,
      },
    },
  },
  sources = {
    default = { "lsp", "path", "snippets", "buffer" },
  },
}

return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "tokyonight-moon",
    },
  },
  {
    "folke/tokyonight.nvim",
    init = function()
      require("config.terminal-capability").patch_tokyonight()
    end,
    opts = {
      style = "moon",
      terminal_colors = true,
    },
  },
}

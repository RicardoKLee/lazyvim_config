vim.o.background = "dark"
vim.env.NVIM_BACKGROUND = "dark"

-- Terminal.app cannot render nvim truecolor (icon red blocks; neovim #11327).
-- iTerm/Cursor: full truecolor — identical tokyonight-moon palette.
if vim.env.TERM_PROGRAM == "Apple_Terminal" then
  vim.g.terminal_features = { undercurl = true, truecolor = false }
  vim.o.termguicolors = false
else
  vim.g.terminal_features = { truecolor = true, undercurl = true }
  vim.o.termguicolors = true
end

require("config.terminal-capability").setup()
require("config.lazy")

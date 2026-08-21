-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- File reference (fref): `path:start-end` open/jump & yank
--   <leader>gy  -- yank file reference (visual selection or current line)
--   <leader>gr  -- open file reference under cursor
--   :RefOpen <path[:start][-end]>   -- open + visual-select the line range
--   :RefYank                       -- yank current selection as reference
require("fref").setup()

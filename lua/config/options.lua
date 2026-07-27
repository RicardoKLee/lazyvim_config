if vim.env.TERM_PROGRAM == "Apple_Terminal" then
  vim.opt.termguicolors = false
else
  vim.opt.termguicolors = true
end
vim.opt.background = "dark"

-- Prefer locally-built tree-sitter-cli (Ubuntu 20.04 GLIBC 2.31 cannot run
-- Mason's prebuilt tree-sitter-linux-x64, which needs GLIBC >= 2.32).
local cargo_bin = vim.fn.expand("~/.cargo/bin")
if vim.fn.isdirectory(cargo_bin) == 1 then
  vim.env.PATH = cargo_bin .. ":" .. vim.env.PATH
end

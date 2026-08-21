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

vim.opt.clipboard = "unnamedplus"

-- SSH 场景统一走 OSC 52（nvim 官方内置 provider）：
--   - 复制：写入 OSC 52 -> Ghostty 默认 clipboard-write=allow，直接进客户端剪贴板
--   - 粘贴：读取 OSC 52 -> Ghostty 默认 clipboard-read=ask，会弹窗确认一次
-- 不再依赖 xclip：远程 X(:1) 剪贴板与客户端剪贴板无关，SSH 下读取永远拿不到内容。
vim.g.clipboard = {
  name = "OSC 52",
  copy = {
    ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
    ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
  },
  paste = {
    ["+"] = require("vim.ui.clipboard.osc52").paste("+"),
    ["*"] = require("vim.ui.clipboard.osc52").paste("*"),
  },
}

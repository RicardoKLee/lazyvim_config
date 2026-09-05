-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Support opening file:line (e.g. nvim config:20 or nvim foo.py:42:5)
vim.api.nvim_create_autocmd({ "BufNewFile", "BufReadPost" }, {
  group = vim.api.nvim_create_augroup("file_line_goto", { clear = true }),
  callback = function(args)
    local bufname = vim.api.nvim_buf_get_name(args.buf)
    if bufname == "" then
      return
    end
    local file, line, col = bufname:match("^(.-):(%d+):?(%d*)$")
    if file and vim.fn.filereadable(file) == 1 then
      local l = tonumber(line) or 1
      local c = tonumber(col) or 1
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(args.buf) then
          vim.api.nvim_buf_delete(args.buf, { force = true })
        end
        vim.cmd.edit(vim.fn.fnameescape(file))
        pcall(vim.api.nvim_win_set_cursor, 0, { l, math.max(0, c - 1) })
      end)
    end
  end,
})

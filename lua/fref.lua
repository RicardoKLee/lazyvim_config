local M = {}

local function trim(s)
  return s and s:gsub("^%s+", ""):gsub("%s+$", "") or ""
end

local function normalize(p)
  return vim.fs.normalize(vim.fn.fnamemodify(p, ":p"))
end

--- Parse a `path[:start][-end]` reference.
---@param ref string
---@return string pattern
---@return integer start_line
---@return integer|nil end_line
local function parse_ref(ref)
  ref = trim(ref)
  local p, a, b = ref:match("^(.-):%s*(%d+)%s*[-~]%s*(%d+)%s*$")
  if p and p ~= "" then
    return p, tonumber(a), tonumber(b)
  end
  local p2, a2 = ref:match("^(.-):%s*(%d+)%s*$")
  if p2 and p2 ~= "" then
    return p2, tonumber(a2), nil
  end
  return ref, 1, nil
end

--- Expand a path pattern (absolute, relative, or with `**`/`*` globs).
--- Fast paths avoid full-tree `**` globs that freeze nvim on huge repos.
---@param pattern string
---@return string|nil absolute path of the first match
local function resolve(pattern)
  pattern = pattern:gsub("^~", vim.fn.expand("~"))
  -- `**/<static>` (no wildcard): prefer `<cwd>/<static>` without scanning the tree
  local static = pattern:match("^%*%*/%s*(.-)%s*$")
  if static and not static:find("[*?]") then
    local joined = static:sub(1, 1) == "/" and static or vim.fs.joinpath(vim.fn.getcwd(), static)
    if vim.fn.filereadable(joined) == 1 then
      return normalize(joined)
    end
  elseif static == nil and pattern:sub(1, 1) ~= "/" and not pattern:find("[*?]") then
    local joined = vim.fs.joinpath(vim.fn.getcwd(), pattern)
    if vim.fn.filereadable(joined) == 1 then
      return normalize(joined)
    end
  end
  local ok, matches = pcall(vim.fn.glob, pattern, false, true)
  if not ok or #matches == 0 then
    return nil
  end
  if #matches > 1 then
    vim.notify(
      ("fref: %d matches for '%s', opening first: %s"):format(#matches, pattern, matches[1]),
      vim.log.levels.INFO
    )
  end
  return normalize(matches[1])
end

--- Open a file reference and visually select the requested line range.
---@param ref string
function M.open(ref)
  local pattern, a, b = parse_ref(ref)
  local path = resolve(pattern)
  if not path then
    vim.notify(("fref: no match for '%s'"):format(pattern), vim.log.levels.ERROR)
    return
  end
  if vim.fn.filereadable(path) == 0 then
    vim.notify(("fref: not a readable file: %s"):format(path), vim.log.levels.ERROR)
    return
  end

  local ok, err = pcall(vim.cmd, "edit " .. vim.fn.fnameescape(path))
  if not ok then
    vim.notify(("fref: failed to open %s: %s"):format(path, err), vim.log.levels.ERROR)
    return
  end

  local total = vim.api.nvim_buf_line_count(0)
  a = math.max(1, math.min(a, total))
  if b then
    b = math.max(a, math.min(b, total))
  end
  vim.api.nvim_win_set_cursor(0, { a, 0 })
  if b and b > a then
    vim.cmd("normal! V")
    vim.api.nvim_win_set_cursor(0, { b, 0 })
  end
  vim.notify(("fref: %s  [%d%s]"):format(path, a, b and ("-" .. b) or ""), vim.log.levels.INFO)
end

--- Open the file reference under the cursor.
function M.open_under_cursor()
  local word = vim.fn.expand("<cWORD>")
  if not word or word == "" then
    vim.notify("fref: nothing under cursor", vim.log.levels.WARN)
    return
  end
  M.open(word)
end

--- Reference path for a file: cwd-relative when under cwd, else absolute.
--- Yanked refs are deterministic paths, no `**` globs.
---@param file string path to the file
---@return string
local function reference_path(file)
  file = normalize(file)
  if file:find("[*?%[%]{}]") then
    return file
  end
  local cwd = normalize(vim.fn.getcwd())
  local rel = vim.fs.relpath(cwd, file)
  if rel and rel:sub(1, 1) ~= "/" then
    return rel
  end
  return file
end

--- Build a `path:start-end` reference for a file/line range.
---@param file string
---@param a integer
---@param b integer
---@return string
function M.make_reference(file, a, b)
  if b and b ~= a then
    return string.format("%s:%d-%d", reference_path(file), a, b)
  end
  return string.format("%s:%d", reference_path(file), a)
end

--- Yank a reference for the current visual selection (or current line).
---@return string|nil
function M.yank()
  local mode = vim.fn.mode()
  local a, b
  if mode == "v" or mode == "V" or mode == "\22" then
    -- '< '> marks only sync when leaving visual mode; exit then restore selection
    vim.cmd("normal! <Esc>")
    local mark_a = vim.fn.getpos("'<")
    local mark_b = vim.fn.getpos("'>")
    a, b = mark_a[2], mark_b[2]
    if not a or a == 0 then
      a, b = vim.fn.line("."), vim.fn.line(".")
    end
    if a > b then
      a, b = b, a
    end
    vim.cmd("normal! gv")
  else
    a, b = vim.fn.line("."), vim.fn.line(".")
  end
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" or vim.bo.buflisted ~= true then
    vim.notify("fref: buffer has no file name", vim.log.levels.WARN)
    return nil
  end
  local ref = M.make_reference(file, a, b)
  vim.fn.setreg("+", ref)
  vim.fn.setreg('"', ref)
  vim.notify(("fref: %s"):format(ref), vim.log.levels.INFO)
  return ref
end

---@param ref? string optional command range (a-b)
local function cmd_open(opts)
  local ref = opts.fargs[1]
  if not ref or ref == "" then
    vim.notify("Usage: RefOpen <path[:start][-end]>", vim.log.levels.WARN)
    return
  end
  M.open(ref)
end

function M.setup()
  pcall(vim.api.nvim_del_user_command, "RefOpen")
  vim.api.nvim_create_user_command("RefOpen", cmd_open, { nargs = 1, complete = "file", desc = "Open file reference (path:start-end)" })
  pcall(vim.api.nvim_del_user_command, "RefYank")
  vim.api.nvim_create_user_command("RefYank", function()
    M.yank()
  end, { nargs = 0, desc = "Copy file reference of current selection" })

  local keys = {
    { "<leader>gy", function() M.yank() end, { mode = { "n", "x" }, desc = "Yank file reference", silent = true, nowait = true } },
    { "<leader>gr", function() M.open_under_cursor() end, { mode = { "n" }, desc = "Open file reference under cursor", silent = true, nowait = true } },
  }
  for _, k in ipairs(keys) do
    local lhs, rhs, spec = k[1], k[2], k[3]
    local modes = spec.mode
    spec.mode = nil
    for _, m in ipairs(modes) do
      vim.keymap.set(m, lhs, rhs, spec)
    end
  end
end

return M
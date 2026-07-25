local M = {}

function M.is_apple_terminal()
  return vim.env.TERM_PROGRAM == "Apple_Terminal"
end

--- xterm-256 RGB palette (0-255), used for nearest-neighbor conversion.
local palette = {}

local function cube_component(n)
  if n == 0 then
    return 0
  end
  return 95 + 40 * (n - 1)
end

do
  local ansi = {
    { 0, 0, 0 },
    { 128, 0, 0 },
    { 0, 128, 0 },
    { 128, 128, 0 },
    { 0, 0, 128 },
    { 128, 0, 128 },
    { 0, 128, 128 },
    { 192, 192, 192 },
    { 128, 128, 128 },
    { 255, 0, 0 },
    { 0, 255, 0 },
    { 255, 255, 0 },
    { 0, 0, 255 },
    { 255, 0, 255 },
    { 0, 255, 255 },
    { 255, 255, 255 },
  }
  for i = 0, 15 do
    palette[i] = ansi[i + 1]
  end
  for i = 16, 231 do
    local n = i - 16
    palette[i] = {
      cube_component(math.floor(n / 36)),
      cube_component(math.floor(n / 6) % 6),
      cube_component(n % 6),
    }
  end
  for i = 232, 255 do
    local v = 8 + (i - 232) * 10
    palette[i] = { v, v, v }
  end
end

--- Nearest xterm-256 index (avoids #222436 -> 17 pure-blue bug).
---@param rgb integer
local function rgb_to_cterm256(rgb)
  local r = bit.rshift(bit.band(rgb, 0xff0000), 16)
  local g = bit.rshift(bit.band(rgb, 0x00ff00), 8)
  local b = bit.band(rgb, 0x0000ff)
  local best, best_dist = 16, math.huge
  for i = 0, 255 do
    local p = palette[i]
    local dr, dg, db = r - p[1], g - p[2], b - p[3]
    local dist = dr * dr + dg * dg + db * db
    if dist < best_dist then
      best_dist = dist
      best = i
    end
  end
  return best
end

--- Convert all GUI highlights to 256-color for Terminal.app.
function M.apply_cterm_highlights()
  if not M.is_apple_terminal() then
    return
  end

  vim.o.termguicolors = false

  for _, name in ipairs(vim.fn.getcompletion("", "highlight")) do
    local hl = vim.api.nvim_get_hl(0, { name = name, link = false })
    if hl.link or (not hl.fg and not hl.bg and not hl.sp) then
      goto continue
    end
    local def = {
      bold = hl.bold or nil,
      italic = hl.italic or nil,
      underline = hl.underline or nil,
      undercurl = hl.undercurl or nil,
      reverse = hl.reverse or nil,
      standout = hl.standout or nil,
    }
    if hl.fg then
      def.ctermfg = rgb_to_cterm256(hl.fg)
    end
    if hl.bg then
      def.ctermbg = rgb_to_cterm256(hl.bg)
    end
    vim.api.nvim_set_hl(0, name, def)
    ::continue::
  end
end

function M.patch_tokyonight()
  if not M.is_apple_terminal() then
    return
  end
  local ok, theme = pcall(require, "tokyonight.theme")
  if not ok or not theme.setup or theme._apple_terminal_patched then
    return
  end
  local orig = theme.setup
  theme.setup = function(opts)
    vim.o.termguicolors = false
    local ret = { orig(opts) }
    vim.o.termguicolors = false
    M.apply_cterm_highlights()
    return unpack(ret)
  end
  theme._apple_terminal_patched = true
end

function M.setup()
  if not M.is_apple_terminal() then
    return
  end

  vim.o.termguicolors = false
  vim.g.terminal_features = vim.tbl_extend("force", vim.g.terminal_features or {}, { truecolor = false })

  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("apple_terminal_cterm", { clear = true }),
    callback = function()
      vim.o.termguicolors = false
      vim.schedule(M.apply_cterm_highlights)
    end,
  })

  vim.api.nvim_create_autocmd("User", {
    group = vim.api.nvim_create_augroup("apple_terminal_lazy", { clear = true }),
    pattern = "VeryLazy",
    callback = function()
      vim.o.termguicolors = false
      M.patch_tokyonight()
      if vim.g.colors_name then
        M.apply_cterm_highlights()
      end
    end,
  })
end

return M

--- Find File icon: fa-search (F002) on Terminal.app, oct-search (F422) on iTerm2.
--- JetBrainsMonoNF renders these glyphs differently per terminal emulator.
local function find_file_icon()
  if vim.env.TERM_PROGRAM == "Apple_Terminal" then
    return "\u{f002} "
  end
  return "\u{f422} "
end

---@param paths string[]
---@return string[]
local function uniq_paths(paths)
  local seen, out = {}, {}
  for _, p in ipairs(paths) do
    p = vim.fs.normalize(p)
    if p ~= "" and not seen[p] then
      seen[p] = true
      out[#out + 1] = p
    end
  end
  return out
end

local function scan_roots()
  local roots = { vim.fn.getcwd() }
  for _, arg in ipairs(vim.fn.argv()) do
    local p = vim.fn.fnamemodify(arg, ":p")
    if vim.fn.isdirectory(p) == 1 then
      roots[#roots + 1] = p
    elseif vim.fn.filereadable(p) == 1 then
      roots[#roots + 1] = vim.fn.fnamemodify(p, ":h")
    end
  end
  return uniq_paths(roots)
end

return {
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      opts.picker = vim.tbl_deep_extend("force", opts.picker or {}, {
        sources = {
          projects = {
            dev = { "~/dev", "~/projects" },
            recent = true,
            max_depth = 3,
            finder = function(fopts, ctx)
              local dev = type(fopts.dev) == "string" and { fopts.dev } or vim.list_extend({}, fopts.dev or {})
              vim.list_extend(dev, scan_roots())
              fopts = vim.tbl_deep_extend("force", {}, fopts, { dev = uniq_paths(dev) })
              return require("snacks.picker.source.recent").projects(fopts, ctx)
            end,
          },
        },
      })
      opts.terminal = vim.tbl_deep_extend("force", opts.terminal or {}, {
        win = { position = "float" },
      })
      opts.dashboard = vim.tbl_deep_extend("force", opts.dashboard or {}, {
        preset = {
          header = [[
          ██╗      █████╗ ███████╗██╗   ██╗██╗   ██╗██╗███╗   ███╗
          ██║     ██╔══██╗╚══███╔╝╚██╗ ██╔╝██║   ██║██║████╗ ████║
          ██║     ███████║  ███╔╝  ╚████╔╝ ██║   ██║██║██╔████╔██║
          ██║     ██╔══██║ ███╔╝    ╚██╔╝  ╚██╗ ██╔╝██║██║╚██╔╝██║
          ███████╗██║  ██║███████╗   ██║    ╚████╔╝ ██║██║ ╚═╝ ██║
          ╚══════╝╚═╝  ╚═╝╚══════╝   ╚═╝     ╚═══╝  ╚═╝╚═╝     ╚═╝
   ]],
          keys = {
            { icon = find_file_icon(), key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
            { icon = "\u{f15b} ", key = "n", desc = "New File", action = ":ene | startinsert" },
            { icon = "\u{f502} ", key = "p", desc = "Projects", action = ":lua Snacks.picker.projects()" },
            { icon = "\u{f022} ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
            { icon = "\u{f0c5} ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
            { icon = "\u{f4a3} ", key = "c", desc = "Config", action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
            { icon = "\u{e348} ", key = "s", desc = "Restore Session", section = "session" },
            { icon = "\u{ea8c} ", key = "x", desc = "Lazy Extras", action = ":LazyExtras" },
            { icon = "\u{f0b2} ", key = "l", desc = "Lazy", action = ":Lazy" },
            { icon = "\u{f426} ", key = "q", desc = "Quit", action = ":qa" },
          },
        },
      })
      return opts
    end,
  },
}

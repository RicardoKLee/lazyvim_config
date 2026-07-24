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

--- Scan roots: Neovim cwd, plus directories from argv (e.g. `nvim /path/to/dir`).
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
    opts = {
      picker = {
        sources = {
          projects = {
            -- Common home layouts; cwd/argv are injected when the picker opens.
            dev = { "~/dev", "~/projects" },
            recent = true,
            max_depth = 3,
            finder = function(opts, ctx)
              local dev = type(opts.dev) == "string" and { opts.dev } or vim.list_extend({}, opts.dev or {})
              vim.list_extend(dev, scan_roots())
              opts = vim.tbl_extend("force", {}, opts, { dev = uniq_paths(dev) })
              return require("snacks.picker.source.recent").projects(opts, ctx)
            end,
          },
        },
      },
      terminal = {
        win = { position = "float" },
      },
    },
  },
}

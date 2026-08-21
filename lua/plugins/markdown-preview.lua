-- Markdown 预览插件
-- 官方仓库: https://github.com/iamcco/markdown-preview.nvim
-- 配置依据官方 README 的 lazy.nvim 方式
--
-- 原生插件"第一次按键只启动服务器不带开浏览器"，这里包装成
-- "一次按键 = 启动服务器 + 服务器就绪后自动打开预览页"，再次按键即关闭。
local function mkdp_toggle()
  if vim.b.mkdp_preview_open then
    vim.b.mkdp_preview_open = nil
    vim.cmd("MarkdownPreviewStop")
    return
  end
  vim.b.mkdp_preview_open = true
  if vim.fn["mkdp#rpc#get_server_status"]() == -1 then
    vim.fn["mkdp#rpc#start_server"]()
  end
  local tries, done = 0, false
  local timer = vim.uv.new_timer()
  timer:start(800, 800, vim.schedule_wrap(function()
    tries = tries + 1
    local s = vim.fn["mkdp#rpc#get_server_status"]()
    if done or tries > 6 then
      timer:stop()
      done = true
      return
    end
    if s == 1 then
      timer:stop()
      done = true
      vim.fn["mkdp#util#open_browser"]()
    end
  end))
end

return {
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown" },
    build = function()
      -- lazy.nvim 执行 build 任务时该插件目录可能尚未加入 runtimepath，
      -- 导致 autoload 函数不可调用（E117），故先显式追加
      vim.opt.rtp:append(vim.fn.stdpath("data") .. "/lazy/markdown-preview.nvim")
      vim.fn["mkdp#util#install"]()
    end,
    init = function()
      -- 预览主题: dark（与 tokoynight 深色编辑器一致）
      vim.g.mkdp_theme = "dark"
      -- 同步滚动方式与 YAML front-matter 隐藏
      vim.g.mkdp_preview_options = {
        sync_scroll_type = "middle",
        hide_yaml_meta = 1,
        disable_filename = 0,
      }
      -- 回显预览 URL（SSH/无浏览器环境下便于手动打开）
      vim.g.mkdp_echo_preview_url = 1
      -- 固定预览端口（默认随机端口不便端口转发）：
      -- SSH 会话用 `ssh -L 9011:localhost:9011` 或在 ~/.ssh/config 配置 LocalForward
      vim.g.mkdp_port = 9011
    end,
    keys = {
      {
        "<leader>mp",
        mkdp_toggle,
        ft = "markdown",
        desc = "Markdown 预览开关",
      },
      {
        "<leader>ms",
        "<cmd>MarkdownPreviewStop<CR>",
        ft = "markdown",
        desc = "Markdown 停止预览",
      },
    },
  },
}
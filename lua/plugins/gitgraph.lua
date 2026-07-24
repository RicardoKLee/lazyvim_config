return {
  {
    "Daiki48/gbv.nvim",
    cmd = { "GBV", "GBVFlow" },
    opts = {
      page_size = 200,
      max_message_width = 60,
    },
    keys = {
      {
        "<leader>gV",
        cmd = "GBV",
        desc = "Git Commit Graph",
      },
      {
        "<leader>gF",
        cmd = "GBVFlow",
        desc = "Git Release Flow Matrix",
      },
    },
  },
}

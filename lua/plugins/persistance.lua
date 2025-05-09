return {
  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = {},
    -- stylua: ignore
    keys = {
      { "<leader>ys", function() require("persistence").load() end, desc = "Restore Session" },
      { "<leader>yS", function() require("persistence").select() end,desc = "Select Session" },
      { "<leader>yl", function() require("persistence").load({ last = true }) end, desc = "Restore Last Session" },
      { "<leader>yd", function() require("persistence").stop() end, desc = "Don't Save Current Session" },
    },
  },
}

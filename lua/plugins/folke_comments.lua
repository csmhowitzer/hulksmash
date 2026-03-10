return {
  {
    "folke/todo-comments.nvim",
    event = "VimEnter",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      colors = {
        default = { "#C970FF" },
        test = { "#FFC878" },
      },
      keywords = {
        IDEA = { icon = " ", color = "info" },
        CONFIG = { icon = " ", color = "#5454FF", alt = { "CONF" } },
        STEP1 = { icon = "1", color = "info" },
        STEP2 = { icon = "2", color = "info" },
        STEP3 = { icon = "3", color = "info" },
        STEP4 = { icon = "4", color = "info" },
        STEP5 = { icon = "5", color = "info" },
      },
    },
  },
}

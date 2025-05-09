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
      },
    },
  },
}

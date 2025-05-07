return {
  {
    "rcarriga/nvim-notify",
    config = function()
      require("notify").setup({
        -- background_colour = 'NotifyBackground',
        background_colour = "#000000",
        fps = 30,
        icons = {
          DEBUG = "",
          ERROR = "",
          INFO = "",
          TRACE = "✎",
          WARN = "",
        },
        level = 2,
        minimum_width = 50,
        render = "default",
        -- stages = 'fade_in_slide_out',
        stages = "slide",
        time_formats = {
          notification = "%T",
          notification_history = "%FT%T",
        },
        timeout = 5000,
        top_down = true,
      })
    end,
  },
}

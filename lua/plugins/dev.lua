return {
  {
    dir = "~/plugins/present.nvim",
    name = "present",
    config = function() end,
  },
  {
    dir = "~/plugins/auto_cwd.nvim",
    name = "auto_cwd",
    config = function()
      require("auto_cwd").setup({
        enabled_languages = { "csharp", "golang", "obsidian" },
        cache_enabled = true,
        fallback_to_git = false,
        debug = false,
      })
    end,
  },
}

return {
  {
    dir = "~/plugins/present.nvim",
    name = "present",
    config = function() end,
  },
  {
    dir = "~/plugins/auto_cwd.nvim",
    name = "auto_cwd",
    build = ":helptags doc",
    config = function()
      require("auto_cwd").setup({
        enabled_languages = { "csharp", "golang", "obsidian" },
        cache_enabled = true,
        fallback_to_git = false,
        debug = false,
      })
    end,
  },
  {
    dir = "~/plugins/format-width.nvim",
    name = "format-width",
    build = ":helptags doc",
    config = function()
      require("format-width").setup({
        -- Uses built-in defaults:
        -- markdown: 80 chars, conceallevel=2
        -- cs: 120 chars, tabstop=4
        -- lua: 120 chars, tabstop=2
      })
    end,
  },
  {
    dir = "~/plugins/scratch-manager.nvim",
    name = "scratch-manager",
    build = ":helptags doc",
    config = function()
      require("scratch-manager").setup({
        -- Uses built-in defaults:
        -- border_color = "#F7DC6F"
        -- default_filetype = "markdown"
        -- enable_keymaps = true
      })
    end,
  },
}

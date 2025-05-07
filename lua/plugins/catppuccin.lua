return {
  { -- You can easily change to a different colorscheme.
    -- Change the name of the colorscheme plugin below, and then
    -- change the command in the config to whatever the name of that colorscheme is
    --
    -- If you want to see what colorschemes are already installed, you can use `:Telescope colorscheme`
    --'folke/tokyonight.nvim',
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000, -- make sure to load this before all the other start plugins
    init = function()
      -- Load the colorscheme here.
      -- Like many other themes, this one has different styles, and you could load
      -- any other, such as 'tokyonight-storm', 'tokyonight-moon', or 'tokyonight-day'.
      vim.cmd.colorscheme("catppuccin")
      vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
      vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
      vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
      vim.api.nvim_set_hl(0, "NeoTreeNormal", { bg = "none" })
      vim.api.nvim_set_hl(0, "NeoTreeNormalNC", { bg = "none" })
      vim.api.nvim_set_hl(0, "TelescopeNormal", { bg = "none" })
      vim.api.nvim_set_hl(0, "SignColumn", { fg = "#CB444A" }) -- a pinkish color

      -- You can configure highlights by doing something like
      vim.cmd.hi("Comment gui=italic")
      -- italic, bold, underline, strikethrough
      -- these are the standard gui settings ":h highlight-args
      -- vim.cmd.hi 'Comment gui=none' -- default
    end,
    -- this function is used to update any custom color changes for my personal tastes
    config = function()
      require("catppuccin").setup({
        flavour = "mocha",
        -- INFO: This is how we set the comment colors to RED (#FF0000)
        -- There are many colors and can be set per theme.
        custom_highlights = function(colors)
          return {
            Comment = { fg = "#FF0000" },
            DiagnosticUnnecessary = { fg = "#dd7878" },
          }
        end,
      })
    end,
  },
}

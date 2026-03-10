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
            ["@string.yaml"] = { fg = "#a6e3a1" }, -- green for strings
            ["@field.yaml"] = { fg = "#89b4fa" }, -- blue for keys
            ["@number.yaml"] = { fg = "#fab387" }, -- orange for numbers
            ["@boolean.yaml"] = { fg = "#f38ba8" }, -- red for booleans
            ["@punctuation.delimiter.yaml"] = { fg = "#89b4fa" }, -- blue for colons, commas
            ["@punctuation.special.yaml"] = { fg = "#89b4fa" }, -- blue for dashes
            ["@text.literal.yaml"] = { fg = "#a6e3a1" }, -- green for string literals
            ["@text.uri.yaml"] = { fg = "#89b4fa" }, -- blue for URLs
            ["@text.reference.yaml"] = { fg = "#89b4fa" }, -- blue for references
            ["@text.emphasis.yaml"] = { fg = "#a6e3a1", bold = true }, -- bold green for emphasis
            ["@text.strong.yaml"] = { fg = "#a6e3a1", bold = true }, -- bold green for strong
            ["@text.title.yaml"] = { fg = "#89b4fa", bold = true }, -- blue for titles
          }
        end,
      })
    end,
  },
}

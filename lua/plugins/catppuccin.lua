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
            -- Comment = { fg = "#FF0000" }, -- red (original preference)
            DiagnosticUnnecessary = { fg = "#dd7878" },
            -- yaml
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
            -- ── C# ─────────────────────────────────────────────────────────────
            -- Principle: Structure Recedes (Cool), Data Pops (Warm)

            -- Types (cool — structural)
            ["@lsp.type.class.cs"] = { fg = "#f9e2af" },                    -- Yellow
            ["@lsp.type.recordClass.cs"] = { fg = "#d4c095" },               -- Yellow ~15% darker than class
            ["@lsp.type.struct.cs"] = { fg = "#b8d090" },                   -- Yellow-green darker — value type
            ["@lsp.type.interface.cs"] = { fg = "#a4dcb0" },        -- Yellow-green teal
            ["@lsp.typemod.class.static.cs"] = { fg = "#f2cdcd" },  -- Flamingo

            -- Attributes (Peach — TS query at priority 200 beats LSP class at 125)
            ["@lsp.type.attribute.cs"] = { fg = "#fab387" },        -- Peach (LSP fallback)
            ["@attribute.c_sharp"] = { fg = "#fab387" },            -- Peach (TS priority 200)

            -- Data (warm — values)
            ["@lsp.type.constant.cs"] = { fg = "#e06c75", bold = true },          -- Red-pink bold
            ["@lsp.typemod.field.static.cs"] = { fg = "#e8b860", bold = true },   -- Yellow-orange bold
            ["@lsp.typemod.property.static.cs"] = { fg = "#d4a840", bold = true },-- Gold yellow bold

            -- Members (cool — structural)
            ["@lsp.type.property.cs"] = { fg = "#7e84c8" },         -- Lavender
            ["@lsp.type.extensionMethod.cs"] = { fg = "#74c7ec" },  -- Sapphire

            -- Parameters & variables
            ["@lsp.type.parameter.cs"] = { fg = "#eba0ac", italic = true }, -- Maroon italic

            -- Keywords & operators
            ["@lsp.type.keyword.cs"] = {},                                       -- cleared — let TS split primitives vs keywords
            ["@lsp.type.operator.cs"] = { fg = "#c4726a" },                     -- Brick red
            ["@keyword.operator.c_sharp"] = { fg = "#cba6f7" },                 -- Mauve
            ["@keyword.coroutine.c_sharp"] = { fg = "#cba6f7", italic = true }, -- Mauve italic

            -- Primitives & builtins (TS — cool blue-mauve)
            ["@type.builtin.c_sharp"] = { fg = "#6b86ef" },         -- predefined types (int, string, bool, var)
            ["@type.parameter"] = { fg = "#f9e2af", italic = true }, -- class type args inside <>
            ["@type.builtin.generic"] = { fg = "#6b86ef", italic = true }, -- primitive type args inside <>

            -- Punctuation
            ["@punctuation.special.c_sharp"] = { fg = "#f5914a" },  -- interpolated string braces
            ["@string.escape.c_sharp"] = { fg = "#f5914a" },        -- escape chars \r\n etc
          }
        end,
      })
    end,
  },
}

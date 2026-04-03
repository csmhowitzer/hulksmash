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
            -- c-sharp
            ["@lsp.type.attribute.cs"] = { fg = "#fab387" }, -- Peach — attributes distinct from classes
            ["@lsp.type.class.cs"] = {}, -- disable LSP class token — let Treesitter @attribute/@type win
            ["@lsp.type.constant.cs"] = { fg = "#e06c75", bold = true }, -- Red-pink bold — original from init.lua
            ["@lsp.typemod.class.static.cs"] = { fg = "#f2cdcd" }, -- Flamingo — same as interfaces, baseline
            ["@lsp.type.interface.cs"] = { fg = "#a4dcb0" }, -- Teal shifted more yellow-green — interfaces
            ["@lsp.typemod.field.static.cs"] = { fg = "#e8b860", bold = true }, -- yellow-orange bold (testing #6)
            ["@lsp.type.parameter.cs"] = { fg = "#eba0ac", italic = true }, -- Maroon italic — matches @variable.parameter at usage sites
            ["@lsp.type.property.cs"] = { fg = "#c9a0c9" }, -- muted orchid — confirmed
            ["@lsp.type.extensionMethod.cs"] = { fg = "#74c7ec" }, -- Sapphire — distinct from regular methods
            ["@lsp.type.operator.cs"] = { fg = "#c4726a" }, -- brick red, orange-shifted
            ["@punctuation.special.c_sharp"] = { fg = "#f5914a" }, -- saturated peach-orange — interpolated string braces
            ["@string.escape.c_sharp"] = { fg = "#f5914a" }, -- same — escape chars \r\n etc
            ["@lsp.type.keyword.cs"] = {}, -- clear LSP keyword — let Treesitter split primitives vs keywords
            ["@type.builtin.c_sharp"] = { fg = "#6b86ef" }, -- cool blue-mauve — predefined types (int, string, bool, var)
            ["@keyword.operator.c_sharp"] = { fg = "#cba6f7" }, -- Mauve — new, out, etc. (fell to Operator cyan when LSP cleared)
            ["@type.parameter"] = { fg = "#f9e2af", italic = true }, -- Yellow italic — class type args inside <>
            ["@type.builtin.generic"] = { fg = "#6b86ef", italic = true }, -- muted blue italic — primitive type args inside <>
            ["@keyword.coroutine.c_sharp"] = { fg = "#cba6f7", italic = true }, -- Mauve italic — async/await keywords
            -- ["@lsp.type.class.cs"] = { fg = "#f9e2af" },
            -- ["@lsp.type.struct.cs"] = { fg = "#94e2d5" },
            -- ["@lsp.type.enum.cs"] = { fg = "#94e2d5" },
            -- ["@lsp.type.variable.cs"] = { fg = "#cdd6f4" },
            -- ["@lsp.type.property.cs"] = { fg = "#89b4fa" },
            -- ["@lsp.type.extensionMethod.cs"] = { fg = "#f9e2af" },
            -- ["@lsp.type.method.cs"] = { fg = "#f9e2af" },
            -- ["@lsp.type.constant.cs"] = { fg = "#eba0ac" },
            -- ["@lsp.type.attribute.cs"] = { fg = "#4CCAE1" },
            -- ["@lsp.type.interface.cs"] = { fg = "#89dceb" },
            -- ["@lsp.typemod.field.static.cs"] = { fg = "#74c7ec" },
            -- c-sharp — Tier 1: Class, Struct (Mocha Yellow, pastel)
            -- ["@lsp.type.class.cs"] = { fg = "#f9e2af" },
            -- ["@lsp.type.struct.cs"] = { fg = "#f9e2af" },
            -- ["@lsp.type.delegate.cs"] = { fg = "#f9e2af" },
            -- ["@lsp.type.typeParameter.cs"] = { fg = "#f9e2af", italic = true },
            -- -- c-sharp — Tier 1c: Namespace (Mauve)
            -- ["@lsp.type.namespace.cs"] = { fg = "#74c7ec" }, -- sapphire — distinct from keywords/conditionals
            -- -- c-sharp — Tier 1b: Interface (Flamingo), Enum (Frappé Sapphire), Attribute (Orange)
            -- ["@lsp.type.interface.cs"] = { fg = "#f2cdcd" },
            -- ["@lsp.type.enum.cs"] = { fg = "#85c1dc" },
            -- ["@lsp.type.attribute.cs"] = { fg = "#d19a66" },
            -- -- c-sharp — Electric: Constants (Latte Mauve, bold)
            -- ["@lsp.type.constant.cs"] = { fg = "#8839ef", bold = true },
            -- ["@lsp.typemod.variable.readonly.cs"] = { fg = "#8839ef", bold = true },
            -- ["@lsp.typemod.property.readonly.cs"] = { fg = "#8839ef", bold = true },
            -- -- c-sharp — Tier 2: Methods (Orange), Properties/Fields (Yellow)
            -- ["@lsp.type.method.cs"] = { fg = "#d19a66" },
            -- ["@lsp.type.extensionMethod.cs"] = { fg = "#d19a66" },
            -- ["@lsp.type.property.cs"] = { fg = "#e5c07b" },
            -- ["@lsp.type.field.cs"] = { fg = "#e5c07b" },
            -- ["@lsp.type.event.cs"] = { fg = "#e5c07b" },
            -- -- c-sharp — Tier 3: Enum Members, Statics (Peach)
            -- ["@lsp.type.enumMember.cs"] = { fg = "#fab387" },
            -- ["@lsp.typemod.field.static.cs"] = { fg = "#fab387" },
            -- ["@lsp.typemod.method.static.cs"] = { fg = "#fab387" },
            -- -- c-sharp — Tier 4: Parameters (Red italic), Variables (Lavender)
            -- ["@lsp.type.parameter.cs"] = { fg = "#f38ba8", italic = true },
            -- ["@lsp.type.variable.cs"] = { fg = "#b4befe" },
            -- -- c-sharp — Tier 5: Keywords (Latte Mauve)
            -- -- ["@lsp.type.keyword.cs"] = { fg = "#8839ef" }, -- too stark, letting default take over
            -- -- c-sharp — Treesitter overrides
            -- -- ["@attribute.c_sharp"] = { fg = "#d19a66" },        -- LSP overrides this, no effect
            -- -- ["@type.builtin.c_sharp"] = { fg = "#cba6f7" },     -- LSP overrides this, no effect
            -- ["@variable.c_sharp"] = { fg = "#b4befe" },
            -- ["@variable.member.c_sharp"] = { fg = "#e5c07b" },
            -- ["@function.method.call.c_sharp"] = { fg = "#d19a66" },
            -- -- ["@type.c_sharp"] = { fg = "#f9e2af" },             -- LSP overrides this, no effect
            -- ["@operator.c_sharp"] = { fg = "#89dceb" },
            -- ["@punctuation.delimiter.c_sharp"] = { fg = "#89dceb" },
            -- ["@punctuation.bracket.c_sharp"] = { fg = "#89dceb" }
          }
        end,
      })
    end,
  },
}

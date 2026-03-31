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
            -- c-sharp
            ["@lsp.type.class.cs"] = { fg = "#e5c07b" }, -- yellow for classes
            ["@lsp.type.struct.cs"] = { fg = "#e5c07b" }, -- yellow for structs
            ["@lsp.type.enum.cs"] = { fg = "#e5c07b" }, -- yellow for enums
            ["@lsp.type.interface.cs"] = { fg = "#56b6c2" }, -- cyan for interfaces
            ["@lsp.type.delegate.cs"] = { fg = "#e5c07b" }, -- yellow for delegates (type-like)
            ["@lsp.type.namespace.cs"] = { fg = "#e5c07b" }, -- yellow for namespaces
            ["@lsp.type.typeParameter.cs"] = { fg = "#e5c07b", italic = true }, -- yellow italic for generics <T>
            ["@lsp.type.variable.cs"] = { fg = "#e06c75" }, -- red for variables
            ["@lsp.type.field.cs"] = { fg = "#e06c75" }, -- red for fields
            ["@lsp.type.property.cs"] = { fg = "#e06c75" }, -- red for properties
            ["@lsp.type.event.cs"] = { fg = "#e06c75" }, -- red for events
            ["@lsp.type.parameter.cs"] = { fg = "#abb2bf", italic = true }, -- grey italic for parameters
            ["@lsp.type.method.cs"] = { fg = "#61afef" }, -- blue for methods
            ["@lsp.type.extensionMethod.cs"] = { fg = "#61afef" }, -- blue for extension methods
            ["@lsp.type.enumMember.cs"] = { fg = "#56b6c2" }, -- cyan for enum members
            ["@lsp.type.constant.cs"] = { fg = "#d19a66" }, -- orange for constants
            ["@lsp.type.attribute.cs"] = { fg = "#d19a66" }, -- orange for attributes [Attribute]
            ["@lsp.type.keyword.cs"] = { fg = "#c678dd" }, -- purple for keywords
            -- type modifiers
            ["@lsp.typemod.field.static.cs"] = { fg = "#e5c07b" }, -- yellow for static fields
            ["@lsp.typemod.method.static.cs"] = { fg = "#61afef" }, -- blue for static methods
            ["@lsp.typemod.variable.readonly.cs"] = { fg = "#d19a66" }, -- orange for readonly vars
            ["@lsp.typemod.property.readonly.cs"] = { fg = "#d19a66" }, -- orange for readonly properties
            -- treesitter c_sharp groups (from c_sharp parser)
            ["@variable.c_sharp"] = { fg = "#e06c75" }, -- red for variables
            ["@variable.member.c_sharp"] = { fg = "#e06c75" }, -- red for member access
            ["@function.method.call.c_sharp"] = { fg = "#61afef" }, -- blue for method calls
            ["@type.c_sharp"] = { fg = "#e5c07b" }, -- yellow for types
          }
        end,
      })
    end,
  },
}

return {
  {
    "Decodetalkers/csharpls-extended-lsp.nvim",
    enabled = false, -- Disabled: roslyn.nvim works better on macOS
    ft = "cs",
    dependencies = {
      "neovim/nvim-lspconfig",
      "nvim-telescope/telescope.nvim", -- Optional: for telescope integration
    },
    config = function()
      -- Setup csharp-ls with extended decompilation support
      local lspconfig = require("lspconfig")
      
      -- Check if csharp-ls is available
      local csharp_ls_cmd = vim.fn.exepath("csharp-ls")
      if csharp_ls_cmd == "" then
        vim.notify("csharp-ls not found. Install with: dotnet tool install --global csharp-ls", vim.log.levels.WARN)
        return
      end
      
      local config = {
        cmd = { csharp_ls_cmd },
        root_dir = function(fname)
          return lspconfig.util.root_pattern("*.sln", "*.csproj", ".git")(fname)
        end,
        settings = {
          csharp = {
            solution = nil, -- Auto-detect solution
            applyFormattingOptions = false, -- Use .editorconfig
          },
        },
        init_options = {
          AutomaticWorkspaceInit = true,
        },
        capabilities = require('blink.cmp').get_lsp_capabilities(),
      }
      
      -- For Neovim < 0.11
      if vim.fn.has("nvim-0.11") == 0 then
        config.handlers = {
          ["textDocument/definition"] = require("csharpls_extended").handler,
          ["textDocument/typeDefinition"] = require("csharpls_extended").handler,
        }
      end
      
      lspconfig.csharp_ls.setup(config)
      
      -- For Neovim 0.11+
      if vim.fn.has("nvim-0.11") == 1 then
        require("csharpls_extended").buf_read_cmd_bind()
      end
      
      -- Optional: Load telescope extension for enhanced navigation
      pcall(function()
        require("telescope").load_extension("csharpls_definition")
      end)
      
      vim.notify("csharp-ls with decompilation support loaded!", vim.log.levels.INFO)
    end,
  },
}

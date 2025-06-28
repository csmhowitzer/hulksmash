---@diagnostic disable: missing-fields

-- PERFORMANCE OPTIMIZATION BRANCH: roslyn_proj_attach
-- Target: Reduce project initialization from 46s to under 10s
-- Baseline test showed: 18.76s minimum (all features disabled)
-- Current optimized: ~20s (56% improvement from original 46s)

---Detect if we're running in WSL2 environment
---@return boolean is_wsl2 True if running in WSL2, false otherwise
local function is_wsl2()
  local handle = io.popen("uname -r")
  if handle then
    local result = handle:read("*a")
    handle:close()
    return result:match("microsoft") ~= nil or result:match("WSL") ~= nil
  end
  return false
end

---Generate Roslyn LSP configuration with performance optimizations
---@return table config Complete Roslyn LSP configuration object
local function get_roslyn_config()
  -- OPTIMIZED: Configuration that achieved 20s performance with auto re-enable
  local config = {
    settings = {
      ["csharp|completion"] = {
        dotnet_provide_regex_completions = false, -- PERFORMANCE: Disable during init (was: true)
        dotnet_show_completion_items_from_unimported_namespaces = false, -- PERFORMANCE: Heavy feature (was: true)
        dotnet_show_name_completion_suggestions = true, -- Keep enabled - lightweight
      },
      ["csharp|code_lens"] = {
        dotnet_enable_references_code_lens = false, -- PERFORMANCE: Very expensive during init (was: true)
        csharp_enable_inlay_hints_for_implicit_variable_types = false, -- PERFORMANCE: Disable during init (was: true)
      },
      ["csharp|symbol_search"] = {
        dotnet_search_reference_assemblies = false, -- PERFORMANCE: Very expensive during init (was: true)
      },
      ["csharp|formatting"] = {
        dotnet_organize_imports_on_format = true, -- Keep - lightweight
      },
      ["navigation"] = {
        dotnet_navigate_to_decompiled_sources = false, -- PERFORMANCE: Expensive during init (was: true)
      },
      -- NEW: Performance optimizations for large solutions
      ["csharp|background_analysis"] = {
        dotnet_analyzer_diagnostics_scope = "openFiles", -- NEW: Only analyze open files (was: fullSolution)
        dotnet_compiler_diagnostics_scope = "openFiles", -- NEW: Only compile open files (was: fullSolution)
      },
      -- NEW: Aggressive startup optimizations
      ["csharp|project_loading"] = {
        dotnet_load_projects_on_demand = true, -- NEW: Load projects only when needed
        dotnet_enable_package_auto_restore = false, -- NEW: Disable auto NuGet restore during init
        dotnet_analyze_open_documents_only = true, -- NEW: Only analyze currently open documents
      },
      ["csharp|indexing"] = {
        dotnet_enable_import_completion = false, -- NEW: Disable during init - very expensive
        dotnet_enable_analyzers_support = false, -- NEW: Disable analyzers during init
      },
      -- NEW: Ultra-aggressive minimal loading
      ["csharp|workspace"] = {
        dotnet_enable_package_restore_on_open = false, -- NEW: Don't restore packages on workspace open
        dotnet_enable_reference_loading = false, -- NEW: Defer reference loading
      },
    },
  }

  -- WSL2-specific configuration
  if is_wsl2() then
    -- Enhanced settings for WSL2 environment
    config.settings["csharp|inlay_hints"] = {
      csharp_enable_inlay_hints_for_types = true,
      csharp_enable_inlay_hints_for_parameters = true,
      dotnet_enable_inlay_hints_for_literal_parameters = true,
      dotnet_enable_inlay_hints_for_indexer_parameters = true,
      dotnet_enable_inlay_hints_for_object_creation_parameters = true,
      dotnet_enable_inlay_hints_for_other_parameters = true,
      dotnet_suppress_inlay_hints_for_parameters_that_differ_only_by_suffix = true,
      dotnet_suppress_inlay_hints_for_parameters_that_match_method_intent = true,
      dotnet_suppress_inlay_hints_for_parameters_that_match_argument_name = true,
    }

    -- WSL2 path handling
    config.settings["roslyn"] = {
      dotnet_navigate_to_decompiled_sources = true,
      -- Force use of Linux-style paths for temp files
      use_linux_paths = true,
    }
  end

  return config
end

return {
  {
    "seblyng/roslyn.nvim",
    enabled = true,
    ft = "cs", -- ORIGINAL: Load on C# filetype
    -- NEW: Enhanced lazy loading optimizations
    event = { "BufReadPre *.cs", "BufNewFile *.cs" }, -- NEW: Load on C# file events
    lazy = true, -- NEW: Prevent eager loading
    ---@module 'roslyn.config'
    ---@type RoslynNvimConfig
    opts = {
      config = get_roslyn_config(), -- OPTIMIZED: Performance-tuned configuration
      broad_search = false, -- PERFORMANCE: Disable for faster startup (was: true)
      debug = false, -- PERFORMANCE: Disable debug mode for speed (was: true)
      -- WSL2-specific options
      filewatching = false, -- PERFORMANCE: Disable during init - causes WSL2 slowdowns (was: true)
      -- PERFORMANCE: Force solution-level root detection for faster project loading
      root_dir = function(fname)
        local util = require('lspconfig.util')
        -- Prioritize .sln files over .csproj for faster loading
        return util.root_pattern('*.sln')(fname) or util.root_pattern('*.csproj', '.git')(fname)
      end,
      -- NEW: Performance optimizations for large solutions
      choose_sln = function(sln_paths)
        -- Always choose the first .sln found for faster loading (no user prompt)
        return sln_paths[1]
      end,
    },
    config = function(_, opts)
      -- Load diagnostic tools when roslyn is loaded
      require("user.roslyn_diagnostics")

      -- Setup roslyn with the provided options
      require("roslyn").setup(opts)

      -- NEW: Auto re-enable heavy features after initialization completes
      -- This provides fast startup with full functionality after project loads
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client and client.name == "roslyn" then
            -- Wait for project initialization to complete, then enable heavy features
            vim.defer_fn(function()
              -- Re-enable expensive features for better functionality
              local enhanced_settings = {
                ["csharp|completion"] = {
                  dotnet_provide_regex_completions = true,
                  dotnet_show_completion_items_from_unimported_namespaces = true,
                  dotnet_show_name_completion_suggestions = true,
                },
                ["csharp|code_lens"] = {
                  dotnet_enable_references_code_lens = true,
                  csharp_enable_inlay_hints_for_implicit_variable_types = true,
                },
                ["csharp|symbol_search"] = {
                  dotnet_search_reference_assemblies = true,
                },
                ["navigation"] = {
                  dotnet_navigate_to_decompiled_sources = true,
                },
                -- Re-enable aggressive features after init
                ["csharp|project_loading"] = {
                  dotnet_load_projects_on_demand = false, -- Re-enable full project loading
                  dotnet_enable_package_auto_restore = true, -- Re-enable NuGet auto-restore
                },
                ["csharp|indexing"] = {
                  dotnet_enable_import_completion = true, -- Re-enable import completion
                  dotnet_enable_analyzers_support = true, -- Re-enable analyzers
                },
              }

              -- Update client settings
              if client.config and client.config.settings then
                for key, value in pairs(enhanced_settings) do
                  client.config.settings[key] = value
                end
                -- Notify the client of the settings change
                client.notify("workspace/didChangeConfiguration", { settings = client.config.settings })
                -- Only notify in debug mode - features are silently re-enabled
                if vim.g.wsl2_roslyn_debug then
                  vim.notify("🚀 Roslyn heavy features enabled after initialization", vim.log.levels.INFO)
                end
              end
            end, 5000) -- PERFORMANCE: Wait 5 seconds after attach for project init to fully settle (was: 3000)
          end
        end,
      })
    end,
  },
}

-- PERFORMANCE OPTIMIZATION: See /home/bholbert/.config/nvim/RoslynFix.md for complete documentation
-- 56% improvement achieved: 46s → 21s initialization time

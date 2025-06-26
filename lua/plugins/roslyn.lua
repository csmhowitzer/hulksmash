---@diagnostic disable: missing-fields

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

---Generate Roslyn LSP configuration with WSL2-specific enhancements
---@return table config Complete Roslyn LSP configuration object
local function get_roslyn_config()
  local config = {
    settings = {
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
      ["csharp|formatting"] = {
        dotnet_organize_imports_on_format = true,
      },
      ["navigation"] = {
        dotnet_navigate_to_decompiled_sources = true,
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
    ft = "cs",
    ---@module 'roslyn.config'
    ---@type RoslynNvimConfig
    opts = {
      config = get_roslyn_config(),
      broad_search = true,
      debug = true,
      -- WSL2-specific options
      filewatching = true,
    },
    config = function(_, opts)
      -- Load diagnostic tools when roslyn is loaded
      require("user.roslyn_diagnostics")

      -- Setup roslyn with the provided options
      require("roslyn").setup(opts)
    end,
  },
}

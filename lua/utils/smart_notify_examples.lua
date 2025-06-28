-- Smart Notify Usage Examples
-- Demonstrates how to use the smart notification utility in different scenarios

local smart_notify = require('utils.smart_notify')

-- Example 1: Using predefined configurations
local function example_predefined()
  -- These will only show in relevant project directories or debug mode
  smart_notify.dotnet("Building .NET project...", vim.log.levels.INFO)
  smart_notify.nodejs("Installing npm dependencies...", vim.log.levels.INFO)
  smart_notify.python("Running Python tests...", vim.log.levels.INFO)
  smart_notify.rust("Compiling Rust project...", vim.log.levels.INFO)
  smart_notify.go("Running go mod tidy...", vim.log.levels.INFO)
  
  -- Errors always show regardless of context
  smart_notify.dotnet("Build failed!", vim.log.levels.ERROR)
end

-- Example 2: Creating a custom notifier for a specific plugin
local function example_custom_plugin()
  -- Create a notifier for a hypothetical Docker plugin
  local docker_notify = smart_notify.create_notifier({
    debug_var = "docker_plugin_debug",
    project_patterns = {
      "Dockerfile",
      "docker-compose.yml",
      "docker-compose.yaml",
      ".dockerignore"
    },
    title = "Docker"
  })
  
  -- Usage - only shows in Docker projects or when docker_plugin_debug is enabled
  docker_notify("Building Docker image...", vim.log.levels.INFO)
  docker_notify("Container started successfully", vim.log.levels.INFO)
  docker_notify("Failed to connect to Docker daemon", vim.log.levels.ERROR) -- Always shows
  
  -- Create debug command for this plugin
  smart_notify.create_debug_command("DockerDebug", "docker_plugin_debug", "Docker Plugin")
  -- Now users can run :DockerDebug on/off
end

-- Example 3: Creating a notifier for a language server
local function example_lsp_plugin()
  -- Create a notifier for a TypeScript LSP enhancement
  local ts_notify = smart_notify.create_notifier({
    debug_var = "typescript_lsp_debug",
    project_patterns = {
      "tsconfig.json",
      "package.json", -- If it has TypeScript deps
      "*.ts",
      "*.tsx"
    },
    title = "TypeScript LSP"
  })
  
  -- Usage examples
  ts_notify("TypeScript server starting...", vim.log.levels.INFO)
  ts_notify("Auto-imports configured", vim.log.levels.INFO)
  ts_notify("Type checking complete", vim.log.levels.INFO)
  ts_notify("TypeScript server crashed", vim.log.levels.ERROR) -- Always shows
  
  -- Create debug command
  smart_notify.create_debug_command("TypeScriptDebug", "typescript_lsp_debug", "TypeScript LSP")
end

-- Example 4: Using the low-level notify function with custom config
local function example_low_level()
  -- Custom configuration for a specific use case
  local custom_config = {
    debug_var = "my_feature_debug",
    project_patterns = { "*.config", "settings.json" },
    always_show_levels = { vim.log.levels.ERROR }, -- Only show errors by default
    title = "My Feature"
  }
  
  -- Use the low-level function
  smart_notify.notify("Feature initialized", vim.log.levels.INFO, nil, custom_config)
  smart_notify.notify("Configuration loaded", vim.log.levels.INFO, { timeout = 2000 }, custom_config)
  smart_notify.notify("Critical error occurred", vim.log.levels.ERROR, nil, custom_config) -- Always shows
end

-- Example 5: Migration from regular vim.notify
local function example_migration()
  -- OLD WAY (noisy):
  -- vim.notify("Plugin loaded", vim.log.levels.INFO)
  -- vim.notify("Processing file...", vim.log.levels.INFO)
  -- vim.notify("Operation complete", vim.log.levels.INFO)
  
  -- NEW WAY (smart):
  local my_notify = smart_notify.create_notifier({
    debug_var = "my_plugin_debug",
    project_patterns = { "*.myproject" },
    title = "My Plugin"
  })
  
  my_notify("Plugin loaded", vim.log.levels.INFO)        -- Only in relevant projects/debug
  my_notify("Processing file...", vim.log.levels.INFO)   -- Only in relevant projects/debug
  my_notify("Operation complete", vim.log.levels.INFO)   -- Only in relevant projects/debug
  my_notify("Fatal error", vim.log.levels.ERROR)         -- Always shows
  
  -- Create debug command for users
  smart_notify.create_debug_command("MyPluginDebug", "my_plugin_debug", "My Plugin")
end

-- Example 6: Testing the utility
local function test_smart_notify()
  print("Testing smart_notify utility...")
  
  -- Test in current directory
  local test_notify = smart_notify.create_notifier({
    debug_var = "test_debug",
    project_patterns = { "*.md" }, -- Should match this file's directory
    title = "Test"
  })
  
  print("Sending test notification (should show if *.md files present)...")
  test_notify("Test notification - should show in directories with .md files", vim.log.levels.INFO)
  
  print("Enable debug mode with: vim.g.test_debug = true")
  print("Then test again to see debug notifications")
end

-- Export examples for testing
return {
  predefined = example_predefined,
  custom_plugin = example_custom_plugin,
  lsp_plugin = example_lsp_plugin,
  low_level = example_low_level,
  migration = example_migration,
  test = test_smart_notify,
}

-- Smart Notification Utility
-- Provides context-aware notifications that respect user preferences and project context
--
-- USAGE EXAMPLES:
--
-- 1. Use predefined configurations:
--    local smart_notify = require('utils.smart_notify')
--    smart_notify.dotnet("Building project...", vim.log.levels.INFO)
--    smart_notify.nodejs("Installing dependencies...", vim.log.levels.INFO)
--
-- 2. Create custom notifier:
--    local my_notify = smart_notify.create_notifier({
--      debug_var = "my_plugin_debug",
--      project_patterns = { "*.myconfig" },
--      title = "My Plugin"
--    })
--    my_notify("Custom notification", vim.log.levels.INFO)
--
-- 3. Create debug command:
--    smart_notify.create_debug_command("MyPluginDebug", "my_plugin_debug", "My Plugin")
--    -- Creates :MyPluginDebug [on|off] command

local M = {}

---@class SmartNotifyConfig
---@field debug_var string|nil Global variable name for debug mode (e.g., "my_plugin_debug")
---@field project_patterns table|nil File patterns to detect relevant projects
---@field always_show_levels table|nil Log levels to always show regardless of context
---@field title string|nil Default notification title

---Default configuration
local default_config = {
  debug_var = nil,
  project_patterns = {},
  always_show_levels = { vim.log.levels.ERROR, vim.log.levels.WARN },
  title = nil,
}

---Check if current directory contains files matching any of the given patterns
---Searches current directory and one level of subdirectories for project files
---@param patterns table List of file patterns to check (e.g., {"*.sln", "package.json"})
---@return boolean is_relevant_project True if in a relevant project directory
local function is_relevant_project(patterns)
  if not patterns or #patterns == 0 then
    return false
  end

  local cwd = vim.fn.getcwd()

  -- Check for patterns in current directory
  for _, pattern in ipairs(patterns) do
    local files = vim.fn.glob(cwd .. "/" .. pattern, false, true)
    if #files > 0 then
      return true
    end
  end

  -- Check subdirectories for project files (one level deep)
  local subdirs = vim.fn.glob(cwd .. "/*", false, true)
  for _, subdir in ipairs(subdirs) do
    if vim.fn.isdirectory(subdir) == 1 then
      for _, pattern in ipairs(patterns) do
        local files = vim.fn.glob(subdir .. "/" .. pattern, false, true)
        if #files > 0 then
          return true
        end
      end
    end
  end

  return false
end

---Check if notifications should be shown based on context and configuration
---Evaluates debug mode, project context, and log level to determine notification visibility
---@param level number Log level (vim.log.levels.*)
---@param config SmartNotifyConfig Configuration for this notification
---@return boolean should_notify True if notification should be shown
local function should_show_notification(level, config)
  -- Always show configured levels (errors/warnings by default)
  for _, always_level in ipairs(config.always_show_levels or default_config.always_show_levels) do
    if level == always_level then
      return true
    end
  end

  -- Show if debug mode is enabled for this plugin
  if config.debug_var and vim.g[config.debug_var] then
    return true
  end

  -- Show if in a relevant project
  if config.project_patterns and is_relevant_project(config.project_patterns) then
    return true
  end

  return false
end

---Smart notification wrapper that respects user preferences and project context
---Only shows notifications when appropriate based on debug mode, project type, or error level
---@param message string Notification message to display
---@param level number|nil Log level (vim.log.levels.*), defaults to INFO
---@param opts table|nil Notification options (title, timeout, etc.)
---@param config SmartNotifyConfig|nil Configuration for this notification
function M.notify(message, level, opts, config)
  level = level or vim.log.levels.INFO
  opts = opts or {}
  config = vim.tbl_deep_extend("force", default_config, config or {})

  -- Add default title if configured and not already set
  if config.title and not opts.title then
    opts.title = config.title
  end

  -- Check if we should show this notification
  if should_show_notification(level, config) then
    vim.notify(message, level, opts)
  end
end

---Create a configured smart notify function for a specific plugin
---Returns a notification function pre-configured with plugin-specific settings
---@param plugin_config SmartNotifyConfig Configuration for the plugin
---@return function notify_fn Configured notification function (message, level, opts)
function M.create_notifier(plugin_config)
  return function(message, level, opts)
    M.notify(message, level, opts, plugin_config)
  end
end

---Predefined configurations for common project types

---Configuration for .NET projects
M.dotnet_config = {
  debug_var = "wsl2_roslyn_debug",
  project_patterns = {
    "*.sln",      -- Solution files
    "*.csproj",   -- C# project files
    "*.fsproj",   -- F# project files
    "*.vbproj",   -- VB.NET project files
    "global.json" -- .NET global configuration
  },
  title = ".NET",
}

---Configuration for Node.js projects
M.nodejs_config = {
  debug_var = "nodejs_debug",
  project_patterns = {
    "package.json",
    "package-lock.json",
    "yarn.lock",
    "pnpm-lock.yaml",
  },
  title = "Node.js",
}

---Configuration for Python projects
M.python_config = {
  debug_var = "python_debug",
  project_patterns = {
    "requirements.txt",
    "pyproject.toml",
    "setup.py",
    "Pipfile",
    "poetry.lock",
  },
  title = "Python",
}

---Configuration for Rust projects
M.rust_config = {
  debug_var = "rust_debug",
  project_patterns = {
    "Cargo.toml",
    "Cargo.lock",
  },
  title = "Rust",
}

---Configuration for Go projects
M.go_config = {
  debug_var = "go_debug",
  project_patterns = {
    "go.mod",
    "go.sum",
  },
  title = "Go",
}

---Convenience functions for common project types
M.dotnet = M.create_notifier(M.dotnet_config)
M.nodejs = M.create_notifier(M.nodejs_config)
M.python = M.create_notifier(M.python_config)
M.rust = M.create_notifier(M.rust_config)
M.go = M.create_notifier(M.go_config)

---Create a debug toggle command for a plugin
---Automatically creates a user command that toggles debug notifications for the plugin
---@param command_name string Name of the command (e.g., "MyPluginDebug")
---@param debug_var string Global variable name for debug mode (e.g., "my_plugin_debug")
---@param plugin_name string Human-readable plugin name for notifications
function M.create_debug_command(command_name, debug_var, plugin_name)
  vim.api.nvim_create_user_command(command_name, function(opts)
    local action = opts.args:lower()
    if action == "on" or action == "enable" or action == "true" then
      vim.g[debug_var] = true
      vim.notify(plugin_name .. " debug notifications enabled", vim.log.levels.INFO)
    elseif action == "off" or action == "disable" or action == "false" then
      vim.g[debug_var] = false
      vim.notify(plugin_name .. " debug notifications disabled", vim.log.levels.INFO)
    else
      local status = vim.g[debug_var] and "enabled" or "disabled"
      vim.notify(plugin_name .. " debug notifications: " .. status, vim.log.levels.INFO)
      vim.notify("Usage: :" .. command_name .. " [on|off]", vim.log.levels.INFO)
    end
  end, {
    nargs = "?",
    desc = "Toggle " .. plugin_name .. " debug notifications",
    complete = function()
      return { "on", "off", "enable", "disable", "true", "false" }
    end,
  })
end

return M

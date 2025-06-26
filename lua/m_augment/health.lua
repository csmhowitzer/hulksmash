---@diagnostic disable: undefined-field
-- Health check module for m_augment plugin
-- Provides comprehensive diagnostics via :checkhealth m_augment

local M = {}

---Check if a module can be loaded without errors
---@param module_name string The module name to check
---@return boolean success True if module loads successfully
---@return string|nil error_msg Error message if loading fails
local function check_module_loadable(module_name)
  local ok, result = pcall(require, module_name)
  if ok then
    return true, nil
  else
    return false, tostring(result)
  end
end

---Check if a file exists and is readable
---@param filepath string Path to check
---@return boolean exists True if file exists and is readable
local function check_file_exists(filepath)
  local expanded_path = vim.fn.expand(filepath)
  local stat = vim.loop.fs_stat(expanded_path)
  return stat ~= nil and stat.type == "file"
end

---Check if a directory exists and is accessible
---@param dirpath string Directory path to check
---@return boolean exists True if directory exists and is accessible
local function check_directory_exists(dirpath)
  local expanded_path = vim.fn.expand(dirpath)
  local stat = vim.loop.fs_stat(expanded_path)
  return stat ~= nil and stat.type == "directory"
end

---Check if a command is available in the system
---@param command string Command name to check
---@return boolean available True if command is available
local function check_command_available(command)
  return vim.fn.executable(command) == 1
end

---Check core m_augment modules
local function check_core_modules()
  vim.health.start("m_augment Core Modules")
  
  local core_modules = {
    "m_augment",
    "m_augment.code",
    "m_augment.state", 
    "m_augment.utils",
    "m_augment.ui",
    "m_augment.inline",
    "m_augment.init"
  }
  
  local all_loaded = true
  
  for _, module in ipairs(core_modules) do
    local success, error_msg = check_module_loadable(module)
    if success then
      vim.health.ok(module .. " - loaded successfully")
    else
      vim.health.error(module .. " - failed to load", error_msg)
      all_loaded = false
    end
  end
  
  if all_loaded then
    vim.health.ok("All core modules loaded successfully")
  else
    vim.health.error("Some core modules failed to load", 
      "Check your m_augment installation and lua path configuration")
  end
end

---Check plugin dependencies
local function check_dependencies()
  vim.health.start("m_augment Dependencies")
  
  local dependencies = {
    { name = "augmentcode/augment.vim", module = "augment", required = true },
    { name = "nvim-lua/plenary.nvim", module = "plenary", required = true },
    { name = "nvim-telescope/telescope.nvim", module = "telescope", required = false },
  }
  
  for _, dep in ipairs(dependencies) do
    local success, error_msg = check_module_loadable(dep.module)
    if success then
      vim.health.ok(dep.name .. " - available")
    else
      if dep.required then
        vim.health.error(dep.name .. " - missing (required)", 
          "Install with your plugin manager: " .. dep.name)
      else
        vim.health.warn(dep.name .. " - missing (optional)", 
          "Some features may not be available")
      end
    end
  end
end

---Check workspace configuration
local function check_workspace_config()
  vim.health.start("m_augment Workspace Configuration")
  
  -- Check workspace file
  local workspace_path = "~/.augment/workspaces.json"
  if check_file_exists(workspace_path) then
    vim.health.ok("Workspace file found: " .. vim.fn.expand(workspace_path))
    
    -- Try to parse workspace file
    local success, workspaces = pcall(function()
      return require("m_augment.utils").ingest_workspaces()
    end)
    
    if success and workspaces then
      vim.health.ok("Workspace file parsed successfully (" .. #workspaces .. " workspaces)")
      
      -- Check if workspaces are accessible
      local accessible_count = 0
      for _, workspace in ipairs(workspaces) do
        if check_directory_exists(workspace) then
          accessible_count = accessible_count + 1
        end
      end
      
      if accessible_count == #workspaces then
        vim.health.ok("All workspace directories accessible")
      elseif accessible_count > 0 then
        vim.health.warn(accessible_count .. "/" .. #workspaces .. " workspace directories accessible",
          "Some workspace paths may be invalid or inaccessible")
      else
        vim.health.error("No workspace directories accessible",
          "Check workspace paths in " .. workspace_path)
      end
    else
      vim.health.error("Failed to parse workspace file", 
        "Check JSON syntax in " .. workspace_path)
    end
  else
    vim.health.warn("Workspace file not found: " .. vim.fn.expand(workspace_path),
      "Run :lua require('m_augment').setup() to initialize")
  end
end

---Check plugin configuration and setup
local function check_plugin_setup()
  vim.health.start("m_augment Plugin Setup")
  
  -- Check if plugin has been initialized
  local success, state = pcall(require, "m_augment.state")
  if success then
    vim.health.ok("m_augment.state module loaded successfully")

    -- Check if get_config function exists
    if state.get_config then
      local config = state.get_config()
      if config then
        vim.health.ok("Plugin initialized with configuration")
        vim.health.info("Max recent buffers: " .. (config.max_recent_buffers or "default"))
        vim.health.info("Max code blocks: " .. (config.max_code_blocks or "default"))
        vim.health.info("Workspace path: " .. (config.workspace_path or "default"))
      else
        vim.health.warn("Plugin not initialized",
          "Call require('m_augment').setup() in your config")
      end
    else
      vim.health.info("Plugin state available (get_config function not implemented yet)")
    end
  else
    vim.health.warn("m_augment.state module issue",
      "This may be normal if state management is not fully implemented")
  end
  
  -- Check global variables
  if vim.g.augment_workspace_folders then
    vim.health.ok("Augment workspace folders configured")
  else
    vim.health.warn("Augment workspace folders not set",
      "May affect workspace detection")
  end
end

---Check test suite availability
local function check_test_suite()
  vim.health.start("m_augment Test Suite")
  
  local test_dir = "tests/m_augment"
  if check_directory_exists(test_dir) then
    vim.health.ok("Test directory found: " .. test_dir)
    
    -- Check for test files
    local test_files = vim.fn.glob(test_dir .. "/*_spec.lua", false, true)
    if #test_files > 0 then
      vim.health.ok("Found " .. #test_files .. " test files")
      
      -- Check if plenary is available for running tests
      local plenary_ok = check_module_loadable("plenary.busted")
      if plenary_ok then
        vim.health.ok("Plenary test runner available")
        vim.health.info("Run tests with: :PlenaryBustedDirectory tests/m_augment")
      else
        vim.health.warn("Plenary test runner not available",
          "Install plenary.nvim to run tests")
      end
    else
      vim.health.warn("No test files found in " .. test_dir)
    end
  else
    vim.health.warn("Test directory not found: " .. test_dir,
      "Tests may not be available")
  end
end

---Check keymaps and commands
local function check_keymaps_commands()
  vim.health.start("m_augment Keymaps & Commands")

  -- Check if main Augment commands are available (from augment.vim)
  local augment_commands = {
    { cmd = "AugmentChat", desc = "Main Augment chat command" },
  }

  local augment_available = false
  for _, cmd_info in ipairs(augment_commands) do
    if vim.fn.exists(":" .. cmd_info.cmd) == 2 then
      vim.health.ok("Augment command :" .. cmd_info.cmd .. " - available")
      augment_available = true
    end
  end

  if not augment_available then
    vim.health.info("Augment.vim commands not found",
      "This is normal if using m_augment as standalone or if augment.vim is not loaded")
  end

  -- Check m_augment specific commands (if any)
  local m_augment_commands = {
    -- Add any m_augment specific commands here when implemented
  }

  if #m_augment_commands == 0 then
    vim.health.info("No m_augment specific commands implemented yet")
  else
    for _, cmd in ipairs(m_augment_commands) do
      if vim.fn.exists(":" .. cmd) == 2 then
        vim.health.ok("m_augment command :" .. cmd .. " - available")
      else
        vim.health.warn("m_augment command :" .. cmd .. " - not found")
      end
    end
  end

  -- Check key mappings
  local key_mappings = {
    { mode = "n", key = "<leader>ac", desc = "Augment Chat" },
    { mode = "n", key = "<leader>ai", desc = "Augment Inline" },
    { mode = "n", key = "<leader>pbf", desc = "Plenary Busted File" },
  }

  for _, mapping in ipairs(key_mappings) do
    local maps = vim.api.nvim_get_keymap(mapping.mode)
    local found = false
    for _, map in ipairs(maps) do
      if map.lhs == mapping.key then
        found = true
        break
      end
    end

    if found then
      vim.health.ok("Keymap " .. mapping.key .. " - configured")
    else
      vim.health.info("Keymap " .. mapping.key .. " - not found (may be buffer-local)")
    end
  end
end

---Check Neovim version compatibility
local function check_neovim_version()
  vim.health.start("m_augment Neovim Compatibility")

  local version = vim.version()
  local version_str = string.format("%d.%d.%d", version.major, version.minor, version.patch)

  vim.health.info("Neovim version: " .. version_str)

  -- Check minimum version requirements
  if version.major > 0 or (version.major == 0 and version.minor >= 9) then
    vim.health.ok("Neovim version compatible (>= 0.9.0)")
  else
    vim.health.error("Neovim version too old (< 0.9.0)",
      "m_augment requires Neovim 0.9.0 or later")
  end

  -- Check for specific features
  if vim.fn.has("nvim-0.10") == 1 then
    vim.health.ok("Advanced LSP features available (Neovim 0.10+)")
  else
    vim.health.warn("Some advanced features may not be available",
      "Consider upgrading to Neovim 0.10+ for best experience")
  end
end

---Check system environment
local function check_system_environment()
  vim.health.start("m_augment System Environment")

  -- Check operating system
  local os_name = vim.loop.os_uname().sysname
  vim.health.info("Operating system: " .. os_name)

  -- Check for WSL2 if on Linux
  if os_name == "Linux" then
    local handle = io.popen("uname -r 2>/dev/null")
    if handle then
      local result = handle:read("*a")
      handle:close()
      if result:match("microsoft") or result:match("WSL") then
        vim.health.info("WSL2 environment detected")
        vim.health.ok("WSL2 compatibility features available")
      end
    end
  end

  -- Check important directories
  local important_dirs = {
    { path = vim.fn.stdpath("data"), name = "Neovim data directory" },
    { path = vim.fn.stdpath("config"), name = "Neovim config directory" },
    { path = "~/.augment", name = "Augment directory" },
  }

  for _, dir in ipairs(important_dirs) do
    if check_directory_exists(dir.path) then
      vim.health.ok(dir.name .. " - accessible")
    else
      vim.health.warn(dir.name .. " - not found: " .. vim.fn.expand(dir.path))
    end
  end
end

---Main health check function
function M.check()
  -- Protect against LazyVim/Lualine compatibility issues in checkhealth buffer
  local original_buf_get_name = vim.api.nvim_buf_get_name
  vim.api.nvim_buf_get_name = function(bufnr)
    bufnr = bufnr or 0
    return original_buf_get_name(bufnr)
  end

  -- Temporarily disable lualine refresh during health check
  local lualine_disabled = false
  local ok, lualine = pcall(require, "lualine")
  if ok and lualine.hide then
    lualine.hide()
    lualine_disabled = true
  end

  -- Run health checks
  local success, error_msg = pcall(function()
    check_neovim_version()
    check_system_environment()
    check_core_modules()
    check_dependencies()
    check_workspace_config()
    check_plugin_setup()
    check_keymaps_commands()
    check_test_suite()

    -- Final summary
    vim.health.start("m_augment Summary")
    vim.health.info("Health check completed")
    vim.health.info("Run ':checkhealth m_augment' anytime to re-check")
    vim.health.info("For detailed diagnostics, see individual sections above")
  end)

  -- Restore lualine if we disabled it
  if lualine_disabled and lualine.show then
    vim.defer_fn(function()
      lualine.show()
    end, 100)
  end

  -- Restore original function
  vim.api.nvim_buf_get_name = original_buf_get_name

  if not success then
    vim.health.error("Health check failed", tostring(error_msg))
  end
end

return M

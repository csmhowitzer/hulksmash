---@diagnostic disable: undefined-field
-- Health check module for WSL2 Roslyn fixes
-- Provides comprehensive diagnostics via :checkhealth wsl2_roslyn
--
-- NOTE: This file should be moved to lua/wsl2_roslyn/health.lua for proper health check detection

local M = {}

---Check if a command is available in the system
---@param command string Command name to check
---@return boolean available True if command is available
local function check_command_available(command)
  return vim.fn.executable(command) == 1
end

---Check if we're running in WSL2 environment
---@return boolean is_wsl2 True if running in WSL2
---@return string|nil version_info WSL version information if available
local function check_wsl2_environment()
  local handle = io.popen("uname -r 2>/dev/null")
  if not handle then
    return false, nil
  end
  
  local result = handle:read("*a")
  handle:close()
  
  if result:match("microsoft") or result:match("WSL") then
    return true, result:gsub("%s+", "")
  end
  
  return false, nil
end

---Test wslpath functionality
---@param test_path string Path to test conversion
---@return boolean success True if conversion works
---@return string|nil result Converted path or error message
local function test_wslpath_conversion(test_path)
  if not check_command_available("wslpath") then
    return false, "wslpath command not available"
  end
  
  local handle = io.popen("wslpath -w '" .. test_path .. "' 2>/dev/null")
  if not handle then
    return false, "Failed to execute wslpath"
  end
  
  local result = handle:read("*a")
  handle:close()
  
  if result and result:match("%S") then
    return true, result:gsub("%s+", "")
  else
    return false, "wslpath returned empty result"
  end
end

---Check WSL2 environment and compatibility
local function check_wsl2_compatibility()
  vim.health.start("WSL2 Environment")
  
  local is_wsl2, version_info = check_wsl2_environment()
  
  if is_wsl2 then
    vim.health.ok("WSL2 environment detected")
    if version_info then
      vim.health.info("Kernel version: " .. version_info)
    end
  else
    vim.health.info("Not running in WSL2 environment")
    vim.health.info("WSL2-specific fixes will be disabled")
    return false
  end
  
  -- Check wslpath availability
  if check_command_available("wslpath") then
    vim.health.ok("wslpath command available")
    
    -- Test wslpath functionality
    local test_paths = {
      "/tmp",
      "/home",
      "/mnt/c"
    }
    
    for _, path in ipairs(test_paths) do
      local success, result = test_wslpath_conversion(path)
      if success then
        vim.health.ok("wslpath conversion test: " .. path .. " -> " .. result)
      else
        vim.health.warn("wslpath conversion failed for " .. path, result)
      end
    end
  else
    vim.health.error("wslpath command not available", 
      "WSL2 path conversion will not work")
    return false
  end
  
  return true
end

---Check Roslyn LSP availability and configuration
local function check_roslyn_lsp()
  vim.health.start("Roslyn LSP Configuration")
  
  -- Check if roslyn.nvim is available
  local roslyn_ok, roslyn = pcall(require, "roslyn")
  if roslyn_ok then
    vim.health.ok("roslyn.nvim plugin loaded")
  else
    vim.health.error("roslyn.nvim plugin not available", 
      "Install seblyng/roslyn.nvim")
    return false
  end
  
  -- Check Mason installation
  local mason_bin = vim.fn.expand("~/.local/share/nvim/mason/bin")
  local roslyn_lsp_path = mason_bin .. "/roslyn"
  
  if vim.fn.executable(roslyn_lsp_path) == 1 then
    vim.health.ok("Roslyn LSP binary found in Mason: " .. roslyn_lsp_path)
  else
    vim.health.warn("Roslyn LSP binary not found in Mason", 
      "Run :MasonInstall roslyn or check Mason installation")
  end
  
  -- Check if LSP is currently running
  local clients = vim.lsp.get_active_clients({ name = "roslyn" })
  if #clients > 0 then
    vim.health.ok("Roslyn LSP client active (" .. #clients .. " instance(s))")
    
    for _, client in ipairs(clients) do
      vim.health.info("Client ID: " .. client.id .. ", Root: " .. (client.config.root_dir or "unknown"))
    end
  else
    vim.health.info("No active Roslyn LSP clients", 
      "Open a C# file to start the LSP")
  end
  
  return true
end

---Check WSL2 Roslyn fix implementation
local function check_wsl2_roslyn_fixes()
  vim.health.start("WSL2 Roslyn Fixes")
  
  -- Check if WSL2 fix module is available (loaded via after/plugin)
  local wsl2_fix_ok, wsl2_fix = pcall(function()
    -- Try to access the global functions set by after/plugin/wsl2_roslyn_fix.lua
    return {
      _is_wsl2 = _G._wsl2_is_wsl2,
      _convert_path = _G._wsl2_convert_path
    }
  end)
  if wsl2_fix_ok and (wsl2_fix._is_wsl2 or wsl2_fix._convert_path) then
    vim.health.ok("WSL2 Roslyn fix functions available")

    -- Test WSL2 detection function
    if wsl2_fix._is_wsl2 then
      local is_wsl2 = wsl2_fix._is_wsl2()
      if is_wsl2 then
        vim.health.ok("WSL2 detection working correctly")
      else
        vim.health.info("WSL2 not detected by fix module (expected on non-WSL2)")
      end
    else
      vim.health.info("WSL2 detection function not available (may not be exposed)")
    end

    -- Test path conversion function
    if wsl2_fix._convert_path then
      local test_path = "/tmp/test"
      local converted = wsl2_fix._convert_path(test_path)
      if converted and converted ~= test_path then
        vim.health.ok("Path conversion function working: " .. test_path .. " -> " .. converted)
      else
        vim.health.info("Path conversion returned original path (expected on non-WSL2)")
      end
    else
      vim.health.info("Path conversion function not available (may not be exposed)")
    end
  else
    vim.health.info("WSL2 Roslyn fix functions not available",
      "This is expected if after/plugin/wsl2_roslyn_fix.lua doesn't expose test functions")
  end
  
  return true
end

---Check diagnostic tools
local function check_diagnostic_tools()
  vim.health.start("WSL2 Roslyn Diagnostic Tools")
  
  -- Check if diagnostic module is available
  local diag_ok, diagnostics = pcall(require, "user.roslyn_diagnostics")
  if diag_ok then
    vim.health.ok("Roslyn diagnostics module loaded")
    
    -- Check if commands are available
    if vim.fn.exists(":RoslynDiagnostics") == 2 then
      vim.health.ok("Command :RoslynDiagnostics available")
    else
      vim.health.warn("Command :RoslynDiagnostics not found")
    end
    
    if vim.fn.exists(":TestWSLPath") == 2 then
      vim.health.ok("Command :TestWSLPath available")
    else
      vim.health.warn("Command :TestWSLPath not found")
    end
    
    -- Check keymap
    local maps = vim.api.nvim_get_keymap("n")
    local found_keymap = false
    for _, map in ipairs(maps) do
      if map.lhs == "<leader>ard" then
        found_keymap = true
        break
      end
    end
    
    if found_keymap then
      vim.health.ok("Keymap <leader>ard configured for diagnostics")
    else
      vim.health.info("Keymap <leader>ard not found (may be buffer-local)")
    end
  else
    vim.health.warn("Roslyn diagnostics module not found", 
      "Check if lua/user/roslyn_diagnostics.lua exists")
  end
end

---Check file system and temp directories
local function check_filesystem()
  vim.health.start("WSL2 File System")
  
  -- Check important directories
  local directories = {
    { path = "/tmp", name = "Linux temp directory" },
    { path = "/mnt/c", name = "Windows C: drive mount" },
    { path = "/var/tmp", name = "Alternative temp directory" },
  }
  
  for _, dir in ipairs(directories) do
    local stat = vim.loop.fs_stat(dir.path)
    if stat and stat.type == "directory" then
      vim.health.ok(dir.name .. " accessible: " .. dir.path)
      
      -- Test write permissions
      local test_file = dir.path .. "/nvim_wsl2_test_" .. os.time()
      local handle = io.open(test_file, "w")
      if handle then
        handle:write("test")
        handle:close()
        os.remove(test_file)
        vim.health.ok(dir.name .. " writable")
      else
        vim.health.warn(dir.name .. " not writable")
      end
    else
      vim.health.warn(dir.name .. " not accessible: " .. dir.path)
    end
  end
end

---Main health check function
function M.check()
  local is_wsl2 = check_wsl2_compatibility()
  check_roslyn_lsp()
  
  if is_wsl2 then
    check_wsl2_roslyn_fixes()
    check_filesystem()
  end
  
  check_diagnostic_tools()
  
  -- Final summary
  vim.health.start("WSL2 Roslyn Summary")
  if is_wsl2 then
    vim.health.info("WSL2 environment detected - all WSL2-specific checks completed")
    vim.health.info("Run ':RoslynDiagnostics' for detailed runtime diagnostics")
    vim.health.info("Use ':TestWSLPath <path>' to test path conversion")
  else
    vim.health.info("Non-WSL2 environment - WSL2-specific features disabled")
  end
  vim.health.info("Run ':checkhealth wsl2_roslyn' anytime to re-check")
end

return M

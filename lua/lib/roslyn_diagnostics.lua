-- Roslyn LSP Diagnostics for WSL2 environments
-- Use this to troubleshoot decompilation navigation issues

local M = {}

---Detect if we're running in WSL2 environment
---@return boolean is_wsl2 True if running in WSL2, false otherwise
local function is_wsl2()
  local handle = io.popen("uname -r 2>/dev/null")
  if handle then
    local result = handle:read("*a")
    handle:close()
    return result:match("microsoft") ~= nil or result:match("WSL") ~= nil
  end
  return false
end

---Check accessibility of decompiled files in common temp directories
---Searches for MetadataAsSource directories and lists sample C# files
local function check_decompiled_files()
  local temp_dirs = {
    "/tmp/MetadataAsSource",
    "/var/tmp/MetadataAsSource",
    vim.fn.expand("~/.cache/MetadataAsSource"),
  }

  print("=== Decompiled Files Check ===")
  for _, dir in ipairs(temp_dirs) do
    local stat = vim.loop.fs_stat(dir)
    if stat then
      print("✓ Found: " .. dir)
      -- List some files
      local handle = io.popen("find '" .. dir .. "' -name '*.cs' | head -3")
      if handle then
        local files = handle:read("*a")
        handle:close()
        if files and files ~= "" then
          print("  Sample files:")
          for file in files:gmatch("[^\n]+") do
            print("    " .. file)
          end
        end
      end
    else
      print("✗ Not found: " .. dir)
    end
  end
end

---Check status of active LSP clients, specifically looking for Roslyn
---Displays client information and workspace configuration
local function check_lsp_status()
  print("\n=== LSP Status ===")
  local clients = vim.lsp.get_active_clients()
  local roslyn_client = nil

  for _, client in ipairs(clients) do
    if client.name == "roslyn" then
      roslyn_client = client
      break
    end
  end

  if roslyn_client then
    print("✓ Roslyn LSP is active")
    print("  Client ID: " .. roslyn_client.id)
    print("  Root dir: " .. (roslyn_client.config.root_dir or "unknown"))
    print("  Workspace folders: " .. vim.inspect(roslyn_client.workspace_folders or {}))
  else
    print("✗ Roslyn LSP not found")
    print("  Active clients:")
    for _, client in ipairs(clients) do
      print("    " .. client.name)
    end
  end
end

-- Check current file context
local function check_current_file()
  print("\n=== Current File Context ===")
  local current_file = vim.api.nvim_buf_get_name(0)
  print("Current file: " .. current_file)
  print("File type: " .. vim.bo.filetype)
  print("Is Windows path: " .. (current_file:match("^/mnt/[a-zA-Z]/") and "Yes" or "No"))
  print("WSL2 environment: " .. (is_wsl2() and "Yes" or "No"))

  -- Test path conversions
  if is_wsl2() and current_file:match("^/mnt/[a-zA-Z]/") then
    local handle = io.popen("wslpath -w '" .. current_file .. "' 2>/dev/null")
    if handle then
      local windows_path = handle:read("*a"):gsub("\n$", "")
      handle:close()
      print("Windows equivalent: " .. windows_path)
    end
  end

  -- Check if we're in a C# project
  local project_files = vim.fn.glob(vim.fn.expand("%:h") .. "/*.{csproj,sln}", false, true)
  if #project_files > 0 then
    print("✓ C# project files found:")
    for _, file in ipairs(project_files) do
      print("  " .. file)
    end
  else
    print("✗ No C# project files found in current directory")
  end
end

---Check if wslpath utility is available and functional
---@return boolean available True if wslpath is available or not needed, false if missing in WSL2
local function check_wslpath_availability()
  print("\n=== wslpath Dependency Check ===")
  if not is_wsl2() then
    print("Not in WSL2 environment - wslpath not needed")
    return true
  end

  local handle = io.popen("which wslpath 2>/dev/null")
  if handle then
    local result = handle:read("*a")
    handle:close()
    if result ~= "" then
      print("✓ wslpath is available: " .. result:gsub("\n$", ""))
      return true
    else
      print("✗ wslpath not found in PATH")
      print("  This is required for WSL2 path conversion!")
      print("  Please ensure WSL2 is properly configured.")
      return false
    end
  end

  print("✗ Unable to check wslpath availability")
  return false
end

-- Test path conversion functionality
local function test_path_conversion()
  print("\n=== Path Conversion Test ===")
  if not is_wsl2() then
    print("Not in WSL2 environment")
    return
  end

  if not check_wslpath_availability() then
    print("Cannot test path conversion - wslpath not available")
    return
  end

  local test_paths = {
    "/tmp/MetadataAsSource",
    "/mnt/c/projects/acculynx",
    vim.api.nvim_buf_get_name(0)
  }

  for _, path in ipairs(test_paths) do
    if path ~= "" then
      local handle = io.popen("wslpath -w '" .. path .. "' 2>/dev/null")
      if handle then
        local windows_path = handle:read("*a"):gsub("\n$", "")
        handle:close()
        print("WSL: " .. path)
        print("Win: " .. windows_path)
        print("---")
      end
    end
  end
end

-- Test decompilation navigation
local function test_navigation()
  print("\n=== Navigation Test ===")
  print("To test decompilation navigation:")
  print("1. Place cursor on a .NET library type (e.g., 'List', 'Console', 'Dictionary')")
  print("2. Press 'gd' or use LSP go-to-definition")
  print("3. Check if it opens a decompiled source file")
  print("4. If it fails, run :lua require('lib.roslyn_diagnostics').debug_last_navigation()")
end

---Debug the last navigation attempt by checking LSP capabilities and decompiled files
---Provides detailed information about Roslyn LSP state and recent decompilation activity
function M.debug_last_navigation()
  print("\n=== Navigation Debug ===")

  -- Check recent LSP requests
  local clients = vim.lsp.get_active_clients()
  for _, client in ipairs(clients) do
    if client.name == "roslyn" then
      print("Roslyn client found, checking capabilities...")
      print("Definition provider: " .. tostring(client.server_capabilities.definitionProvider))
      print("Type definition provider: " .. tostring(client.server_capabilities.typeDefinitionProvider))
      break
    end
  end

  -- Check for recent decompiled files
  check_decompiled_files()
end

---Run comprehensive diagnostics for Roslyn LSP in WSL2 environments
---Checks environment, LSP status, decompiled files, dependencies, and path conversion
function M.run_diagnostics()
  print("=== Roslyn LSP Diagnostics for WSL2 ===")
  print("Environment: " .. (is_wsl2() and "WSL2" or "Native Linux"))

  check_current_file()
  check_lsp_status()
  check_decompiled_files()
  check_wslpath_availability()
  test_path_conversion()
  test_navigation()

  print("\n=== Summary ===")
  print("If decompilation navigation is not working:")
  print("1. Ensure you're using 'gd' on external library types")
  print("2. Check that Roslyn LSP is active and attached")
  print("3. Verify decompiled files are being created in /tmp/MetadataAsSource")
  print("4. Ensure wslpath utility is available (WSL2 only)")
  print("5. Try restarting LSP with :LspRestart")
  print("6. Check for path permission issues in WSL2")
  print("7. Test path conversion with :TestWSLPath")
end

-- Create user command
vim.api.nvim_create_user_command("RoslynDiagnostics", function()
  M.run_diagnostics()
end, { desc = "Run Roslyn LSP diagnostics" })

-- Create keymapping
vim.keymap.set("n", "<leader>ard", function()
  M.run_diagnostics()
end, { desc = "[A]ugment [R]oslyn [D]iagnostics" })

-- Expose local functions for testing
M._is_wsl2 = is_wsl2
M._check_decompiled_files = check_decompiled_files
M._check_lsp_status = check_lsp_status
M._check_current_file = check_current_file
M._check_wslpath_availability = check_wslpath_availability
M._test_path_conversion = test_path_conversion

return M

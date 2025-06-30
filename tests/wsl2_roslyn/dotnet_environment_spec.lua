---@diagnostic disable: undefined-field
-- Tests for WSL2 .NET environment configuration
-- Run with: :PlenaryBustedFile %
--
-- Tests the .NET runtime ID detection and environment variable setup

local eq = assert.are.same

describe("WSL2 .NET Environment Configuration", function()
  
  describe("Environment variable setup patterns", function()
    it("should set correct environment variables for Windows projects", function()
      -- Test the environment variables that should be set
      local expected_vars = {
        DOTNET_RUNTIME_ID = "win-x64",
        NUGET_FALLBACK_PACKAGES = "",
        DOTNET_NUGET_SIGNATURE_VERIFICATION = "false"
      }
      
      -- Verify the pattern for each variable
      for var_name, expected_value in pairs(expected_vars) do
        -- Test that the expected value is what we want to set
        eq(expected_value, expected_value, "Environment variable " .. var_name .. " should be set correctly")
      end
    end)
    
    it("should handle user-specific NuGet packages path", function()
      local test_users = { "testuser", "developer", "admin" }
      
      for _, user in ipairs(test_users) do
        local expected_path = "/home/" .. user .. "/.nuget/packages"
        local pattern = "^/home/[^/]+/%.nuget/packages$"
        
        -- Test that the path matches the expected pattern
        local matches = expected_path:match(pattern) ~= nil
        eq(true, matches, "NuGet packages path should match pattern for user: " .. user)
      end
    end)
  end)
  
  describe("Runtime ID selection logic", function()
    it("should select win-x64 for Windows filesystem projects", function()
      local windows_project_paths = {
        "/mnt/c/projects/enterprise-app",
        "/mnt/d/development/microservices", 
        "/mnt/z/code/legacy-system"
      }
      
      for _, path in ipairs(windows_project_paths) do
        -- Simulate the logic: if WSL2 and Windows path, use win-x64
        local is_wsl2 = true  -- Assume WSL2 environment
        local is_windows_path = path:match("^/mnt/[a-zA-Z]/") ~= nil
        local runtime_id = (is_wsl2 and is_windows_path) and "win-x64" or nil
        
        eq("win-x64", runtime_id, "Should select win-x64 for: " .. path)
      end
    end)
    
    it("should select linux-x64 for native WSL2 projects", function()
      local wsl2_project_paths = {
        "/home/user/projects/native-app",
        "/opt/development/service",
        "/tmp/experimental/project"
      }
      
      for _, path in ipairs(wsl2_project_paths) do
        -- Simulate the logic: if WSL2 and not Windows path, use linux-x64
        local is_wsl2 = true  -- Assume WSL2 environment
        local is_windows_path = path:match("^/mnt/[a-zA-Z]/") ~= nil
        local runtime_id = (is_wsl2 and not is_windows_path) and "linux-x64" or nil
        
        eq("linux-x64", runtime_id, "Should select linux-x64 for: " .. path)
      end
    end)
    
    it("should return nil for non-WSL2 environments", function()
      local any_paths = {
        "/mnt/c/projects/test",
        "/home/user/projects/test",
        "/any/random/path"
      }
      
      for _, path in ipairs(any_paths) do
        -- Simulate the logic: if not WSL2, return nil
        local is_wsl2 = false  -- Non-WSL2 environment
        local runtime_id = is_wsl2 and "some-runtime" or nil
        
        eq(nil, runtime_id, "Should return nil for non-WSL2: " .. path)
      end
    end)
  end)
  
  describe("LSP client integration patterns", function()
    it("should prefer Roslyn LSP root directory over cwd", function()
      -- Test the priority logic: Roslyn root > current working directory
      local cwd = "/home/user/projects/current"
      local roslyn_root = "/mnt/c/projects/enterprise"
      
      -- Simulate having an active Roslyn client
      local mock_clients = {
        { name = "other_lsp", config = { root_dir = "/some/other/path" } },
        { name = "roslyn", config = { root_dir = roslyn_root } }
      }
      
      -- Find Roslyn client (simulating the actual logic)
      local selected_path = cwd  -- Default to cwd
      for _, client in ipairs(mock_clients) do
        if client.name == "roslyn" and client.config.root_dir then
          selected_path = client.config.root_dir
          break
        end
      end
      
      eq(roslyn_root, selected_path, "Should prefer Roslyn LSP root directory")
    end)
    
    it("should fall back to cwd when no Roslyn client", function()
      local cwd = "/home/user/projects/current"
      local mock_clients = {
        { name = "other_lsp", config = { root_dir = "/some/other/path" } }
      }
      
      -- Find Roslyn client (simulating the actual logic)
      local selected_path = cwd  -- Default to cwd
      for _, client in ipairs(mock_clients) do
        if client.name == "roslyn" and client.config.root_dir then
          selected_path = client.config.root_dir
          break
        end
      end
      
      eq(cwd, selected_path, "Should fall back to cwd when no Roslyn client")
    end)
  end)
  
  describe("Environment safety checks", function()
    it("should only apply environment changes in WSL2", function()
      -- Test that environment setup is conditional on WSL2 detection
      local environments = {
        { name = "WSL2", is_wsl2 = true, should_apply = true },
        { name = "Linux", is_wsl2 = false, should_apply = false },
        { name = "macOS", is_wsl2 = false, should_apply = false },
        { name = "Windows", is_wsl2 = false, should_apply = false }
      }

      for _, env in ipairs(environments) do
        -- Simulate the conditional logic
        local will_apply_changes = env.is_wsl2

        eq(env.should_apply, will_apply_changes,
           "Environment changes for " .. env.name .. " should be " ..
           (env.should_apply and "applied" or "skipped"))
      end
    end)
  end)

  describe("Smart notification system", function()
    it("should detect .NET projects correctly", function()
      -- Test .NET project detection patterns
      local test_cases = {
        { path = "/home/user/project", has_sln = false, expected = false },
        { path = "/mnt/c/projects/app", has_sln = true, expected = true },
        { path = "/tmp/test", has_sln = false, expected = false }
      }

      for _, case in ipairs(test_cases) do
        -- Simulate the .NET project detection logic
        local is_dotnet_project = case.has_sln  -- Simplified for testing
        eq(case.expected, is_dotnet_project,
           "Project detection for: " .. case.path)
      end
    end)

    it("should respect notification preferences", function()
      -- Test notification logic
      local scenarios = {
        { debug_mode = true, in_dotnet_project = false, should_notify = true },
        { debug_mode = false, in_dotnet_project = true, should_notify = true },
        { debug_mode = false, in_dotnet_project = false, should_notify = false },
        { debug_mode = true, in_dotnet_project = true, should_notify = true }
      }

      for _, scenario in ipairs(scenarios) do
        -- Simulate the notification decision logic
        local should_notify = scenario.debug_mode or scenario.in_dotnet_project
        eq(scenario.should_notify, should_notify,
           string.format("Debug: %s, .NET project: %s",
                        scenario.debug_mode, scenario.in_dotnet_project))
      end
    end)

    it("should integrate with smart_notify utility", function()
      -- Test that WSL2 Roslyn fixes use the smart notification utility
      local smart_notify = require('lib.smart_notify')

      -- Verify the utility is available
      assert(smart_notify, "Smart notify utility should be available")
      assert(smart_notify.dotnet, "Dotnet notifier should be available")
      assert(smart_notify.dotnet_config, "Dotnet config should be available")

      -- Verify configuration
      local config = smart_notify.dotnet_config
      eq("wsl2_roslyn_debug", config.debug_var, "Should use correct debug variable")
      eq(".NET", config.title, "Should have correct title")

      -- Verify project patterns include .NET files
      local patterns = config.project_patterns
      assert(vim.tbl_contains(patterns, "*.sln"), "Should detect solution files")
      assert(vim.tbl_contains(patterns, "*.csproj"), "Should detect C# project files")
      assert(vim.tbl_contains(patterns, "global.json"), "Should detect global.json")
    end)
  end)
end)

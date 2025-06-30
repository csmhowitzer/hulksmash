-- Unit tests for smart notification utility
-- Tests context-aware notification behavior and configuration

local smart_notify = require('lib.smart_notify')

describe("Smart Notification Utility", function()
  -- Store original values to restore after tests
  local original_cwd
  local original_debug_vars = {}
  
  before_each(function()
    original_cwd = vim.fn.getcwd()
    -- Store any existing debug variables
    original_debug_vars.wsl2_roslyn_debug = vim.g.wsl2_roslyn_debug
    original_debug_vars.test_debug = vim.g.test_debug
    
    -- Clear debug variables for clean test state
    vim.g.wsl2_roslyn_debug = nil
    vim.g.test_debug = nil
  end)
  
  after_each(function()
    -- Restore original state
    vim.cmd("cd " .. original_cwd)
    vim.g.wsl2_roslyn_debug = original_debug_vars.wsl2_roslyn_debug
    vim.g.test_debug = original_debug_vars.test_debug
  end)

  describe("Project Detection", function()
    it("should detect .NET projects correctly", function()
      -- Test the .NET configuration patterns
      local dotnet_patterns = smart_notify.dotnet_config.project_patterns
      
      -- Should include common .NET file patterns
      assert.truthy(vim.tbl_contains(dotnet_patterns, "*.sln"))
      assert.truthy(vim.tbl_contains(dotnet_patterns, "*.csproj"))
      assert.truthy(vim.tbl_contains(dotnet_patterns, "global.json"))
    end)
    
    it("should detect Node.js projects correctly", function()
      local nodejs_patterns = smart_notify.nodejs_config.project_patterns
      
      assert.truthy(vim.tbl_contains(nodejs_patterns, "package.json"))
      assert.truthy(vim.tbl_contains(nodejs_patterns, "package-lock.json"))
      assert.truthy(vim.tbl_contains(nodejs_patterns, "yarn.lock"))
    end)
    
    it("should detect Python projects correctly", function()
      local python_patterns = smart_notify.python_config.project_patterns
      
      assert.truthy(vim.tbl_contains(python_patterns, "requirements.txt"))
      assert.truthy(vim.tbl_contains(python_patterns, "pyproject.toml"))
      assert.truthy(vim.tbl_contains(python_patterns, "setup.py"))
    end)
  end)

  describe("Notification Logic", function()
    it("should always show errors and warnings", function()
      local notification_shown = false
      local original_notify = vim.notify
      
      -- Mock vim.notify to track calls
      vim.notify = function(message, level, opts)
        notification_shown = true
      end
      
      -- Test error notification (should always show)
      smart_notify.notify("Test error", vim.log.levels.ERROR, nil, {
        debug_var = "test_debug",
        project_patterns = { "nonexistent.file" }
      })
      
      assert.truthy(notification_shown, "Error notifications should always be shown")
      
      -- Reset for warning test
      notification_shown = false
      smart_notify.notify("Test warning", vim.log.levels.WARN, nil, {
        debug_var = "test_debug", 
        project_patterns = { "nonexistent.file" }
      })
      
      assert.truthy(notification_shown, "Warning notifications should always be shown")
      
      -- Restore original notify
      vim.notify = original_notify
    end)
    
    it("should respect debug mode", function()
      local notification_shown = false
      local original_notify = vim.notify
      
      vim.notify = function(message, level, opts)
        notification_shown = true
      end
      
      -- Test without debug mode (should not show INFO)
      vim.g.test_debug = false
      smart_notify.notify("Test info", vim.log.levels.INFO, nil, {
        debug_var = "test_debug",
        project_patterns = { "nonexistent.file" }
      })
      
      assert.falsy(notification_shown, "INFO notifications should not show without debug mode")
      
      -- Test with debug mode (should show INFO)
      notification_shown = false
      vim.g.test_debug = true
      smart_notify.notify("Test info", vim.log.levels.INFO, nil, {
        debug_var = "test_debug",
        project_patterns = { "nonexistent.file" }
      })
      
      assert.truthy(notification_shown, "INFO notifications should show in debug mode")
      
      vim.notify = original_notify
    end)
  end)

  describe("Notifier Creation", function()
    it("should create working notifiers with custom config", function()
      local test_notifier = smart_notify.create_notifier({
        debug_var = "test_debug",
        project_patterns = { "*.test" },
        title = "Test Plugin"
      })
      
      -- Should return a function
      assert.equals("function", type(test_notifier))
      
      -- Test the created notifier
      local notification_shown = false
      local original_notify = vim.notify
      
      vim.notify = function(message, level, opts)
        notification_shown = true
      end
      
      -- Should show errors regardless of context
      test_notifier("Test error", vim.log.levels.ERROR)
      assert.truthy(notification_shown, "Custom notifier should show errors")
      
      vim.notify = original_notify
    end)
  end)

  describe("Predefined Configurations", function()
    it("should have correct debug variables", function()
      assert.equals("wsl2_roslyn_debug", smart_notify.dotnet_config.debug_var)
      assert.equals("nodejs_debug", smart_notify.nodejs_config.debug_var)
      assert.equals("python_debug", smart_notify.python_config.debug_var)
      assert.equals("rust_debug", smart_notify.rust_config.debug_var)
      assert.equals("go_debug", smart_notify.go_config.debug_var)
    end)
    
    it("should have appropriate titles", function()
      assert.equals(".NET", smart_notify.dotnet_config.title)
      assert.equals("Node.js", smart_notify.nodejs_config.title)
      assert.equals("Python", smart_notify.python_config.title)
      assert.equals("Rust", smart_notify.rust_config.title)
      assert.equals("Go", smart_notify.go_config.title)
    end)
    
    it("should have working convenience functions", function()
      -- Test that convenience functions exist and are callable
      assert.equals("function", type(smart_notify.dotnet))
      assert.equals("function", type(smart_notify.nodejs))
      assert.equals("function", type(smart_notify.python))
      assert.equals("function", type(smart_notify.rust))
      assert.equals("function", type(smart_notify.go))
    end)
  end)

  describe("Debug Command Creation", function()
    it("should create debug commands without errors", function()
      -- This should not throw an error
      assert.has_no.errors(function()
        smart_notify.create_debug_command("TestDebugCommand", "test_debug_var", "Test Plugin")
      end)
      
      -- Check that the command was created
      local commands = vim.api.nvim_get_commands({})
      assert.truthy(commands.TestDebugCommand, "Debug command should be created")
    end)
  end)

  describe("Configuration Merging", function()
    it("should merge configurations correctly", function()
      local notification_count = 0
      local original_notify = vim.notify
      
      vim.notify = function(message, level, opts)
        notification_count = notification_count + 1
      end
      
      -- Test with partial config (should use defaults)
      smart_notify.notify("Test", vim.log.levels.ERROR, nil, {
        debug_var = "test_debug"
        -- project_patterns not specified, should use default (empty)
      })
      
      assert.equals(1, notification_count, "Should show error with partial config")
      
      vim.notify = original_notify
    end)
  end)
end)

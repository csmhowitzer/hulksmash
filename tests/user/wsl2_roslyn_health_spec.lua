-- Tests for WSL2 Roslyn health check module
-- Run with: :PlenaryBustedFile tests/user/wsl2_roslyn_health_spec.lua

local health = require("user.wsl2_roslyn_health")

describe("user.wsl2_roslyn_health", function()
  it("should have a check function", function()
    assert.is_function(health.check)
  end)
  
  it("should run health check without errors", function()
    -- Mock vim.health functions to capture output
    local health_output = {}
    local original_health = vim.health
    
    vim.health = {
      start = function(name)
        table.insert(health_output, { type = "start", name = name })
      end,
      ok = function(msg)
        table.insert(health_output, { type = "ok", msg = msg })
      end,
      warn = function(msg, advice)
        table.insert(health_output, { type = "warn", msg = msg, advice = advice })
      end,
      error = function(msg, advice)
        table.insert(health_output, { type = "error", msg = msg, advice = advice })
      end,
      info = function(msg)
        table.insert(health_output, { type = "info", msg = msg })
      end,
    }
    
    -- Run health check
    local success, error_msg = pcall(health.check)
    
    -- Restore original vim.health
    vim.health = original_health
    
    -- Verify it ran without errors
    assert.is_true(success, "WSL2 Roslyn health check should run without errors: " .. tostring(error_msg))
    
    -- Verify we got some output
    assert.is_true(#health_output > 0, "Health check should produce output")
    
    -- Verify we have the expected sections
    local sections = {}
    for _, output in ipairs(health_output) do
      if output.type == "start" then
        table.insert(sections, output.name)
      end
    end
    
    -- Check for key sections
    local expected_sections = {
      "WSL2 Environment",
      "Roslyn LSP Configuration",
      "WSL2 Roslyn Summary"
    }
    
    for _, expected in ipairs(expected_sections) do
      local found = false
      for _, section in ipairs(sections) do
        if section == expected then
          found = true
          break
        end
      end
      assert.is_true(found, "Should have section: " .. expected)
    end
  end)
  
  it("should detect non-WSL2 environment correctly on macOS", function()
    -- On macOS, should detect non-WSL2 environment
    local handle = io.popen("uname -r 2>/dev/null")
    if handle then
      local result = handle:read("*a")
      handle:close()
      
      -- Should not contain WSL markers on macOS
      assert.is_false(result:match("microsoft") ~= nil, "macOS should not have microsoft in kernel")
      assert.is_false(result:match("WSL") ~= nil, "macOS should not have WSL in kernel")
    end
  end)
  
  it("should check for required commands", function()
    -- wslpath should not be available on macOS
    local wslpath_available = vim.fn.executable("wslpath") == 1
    assert.is_false(wslpath_available, "wslpath should not be available on macOS")
  end)
end)

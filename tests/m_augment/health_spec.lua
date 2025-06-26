-- Tests for m_augment health check module
-- Run with: :PlenaryBustedFile tests/m_augment/health_spec.lua

local health = require("m_augment.health")

describe("m_augment.health", function()
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
    assert.is_true(success, "Health check should run without errors: " .. tostring(error_msg))
    
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
      "m_augment Neovim Compatibility",
      "m_augment System Environment", 
      "m_augment Core Modules",
      "m_augment Dependencies",
      "m_augment Summary"
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
  
  it("should detect core modules correctly", function()
    -- Test that core modules can be loaded
    local core_modules = {
      "m_augment",
      "m_augment.code",
      "m_augment.state", 
      "m_augment.utils",
      "m_augment.ui",
      "m_augment.inline",
      "m_augment.init"
    }
    
    for _, module in ipairs(core_modules) do
      local success, _ = pcall(require, module)
      assert.is_true(success, "Core module should be loadable: " .. module)
    end
  end)
  
  it("should check Neovim version compatibility", function()
    local version = vim.version()
    
    -- Should be running on a compatible version
    assert.is_true(version.major > 0 or (version.major == 0 and version.minor >= 9),
      "Tests should run on Neovim 0.9.0 or later")
  end)
end)

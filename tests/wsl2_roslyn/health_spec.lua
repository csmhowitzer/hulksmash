-- Tests for WSL2 Roslyn health check module
-- Run with: :PlenaryBustedFile tests/wsl2_roslyn/health_spec.lua

local health = require("wsl2_roslyn.health")

describe("wsl2_roslyn.health", function()
  it("should have a check function", function()
    assert.is_function(health.check)
  end)
  
  it("should expose test functions", function()
    assert.is_function(health._check_wsl2_environment)
    assert.is_function(health._check_wslpath_availability)
    assert.is_function(health._check_roslyn_lsp)
    assert.is_function(health._check_dotnet_environment)
  end)
  
  describe("_check_wsl2_environment", function()
    it("should check WSL2 environment detection", function()
      -- This should not throw an error
      assert.has_no.errors(function()
        health._check_wsl2_environment()
      end)
    end)
  end)
  
  describe("_check_wslpath_availability", function()
    it("should check wslpath utility availability", function()
      -- This should not throw an error
      assert.has_no.errors(function()
        health._check_wslpath_availability()
      end)
    end)
  end)
  
  describe("_check_roslyn_lsp", function()
    it("should check Roslyn LSP configuration", function()
      -- This should not throw an error
      assert.has_no.errors(function()
        health._check_roslyn_lsp()
      end)
    end)
  end)
  
  describe("_check_dotnet_environment", function()
    it("should check .NET environment configuration", function()
      -- This should not throw an error
      assert.has_no.errors(function()
        health._check_dotnet_environment()
      end)
    end)
  end)
end)

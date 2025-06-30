-- Tests for m_augment health check module
-- Run with: :PlenaryBustedFile tests/m_augment/health_spec.lua

local health = require("m_augment.health")

describe("m_augment.health", function()
  it("should have a check function", function()
    assert.is_function(health.check)
  end)
  
  it("should expose test functions", function()
    assert.is_function(health._check_neovim_version)
    assert.is_function(health._check_lazy_nvim)
    assert.is_function(health._check_m_augment_modules)
    assert.is_function(health._check_test_suite)
  end)
  
  describe("_check_neovim_version", function()
    it("should check Neovim version compatibility", function()
      -- This should not throw an error
      assert.has_no.errors(function()
        health._check_neovim_version()
      end)
    end)
  end)
  
  describe("_check_lazy_nvim", function()
    it("should check LazyVim availability", function()
      -- This should not throw an error
      assert.has_no.errors(function()
        health._check_lazy_nvim()
      end)
    end)
  end)
  
  describe("_check_m_augment_modules", function()
    it("should check all m_augment modules", function()
      -- This should not throw an error
      assert.has_no.errors(function()
        health._check_m_augment_modules()
      end)
    end)
  end)
  
  describe("_check_test_suite", function()
    it("should check test suite availability", function()
      -- This should not throw an error
      assert.has_no.errors(function()
        health._check_test_suite()
      end)
    end)
  end)
end)

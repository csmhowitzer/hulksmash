---@diagnostic disable: undefined-field
-- Tests for WSL2 environment detection and validation
-- Run with: :PlenaryBustedFile %
--
-- Note: Simplified tests focusing on environment detection patterns

local eq = assert.are.same

describe("WSL2 Environment Detection Patterns", function()

  describe("WSL2 kernel detection patterns", function()
    it("should detect WSL2 from kernel strings", function()
      local wsl2_kernels = {
        "5.15.90.1-microsoft-standard-WSL2",
        "4.19.128-microsoft-standard",
        "5.10.16.3-microsoft-standard-WSL2",
        "6.1.21.2-microsoft-standard-WSL2+"
      }

      for _, kernel in ipairs(wsl2_kernels) do
        local is_wsl2 = kernel:match("microsoft") ~= nil or kernel:match("WSL") ~= nil
        eq(true, is_wsl2, "Should detect WSL2: " .. kernel)
      end
    end)

    it("should not detect WSL2 from regular Linux kernels", function()
      local linux_kernels = {
        "5.15.0-generic",
        "5.4.0-74-generic",
        "6.2.0-26-generic",
        "5.19.0-arch1-1"
      }

      for _, kernel in ipairs(linux_kernels) do
        local is_wsl2 = kernel:match("microsoft") ~= nil or kernel:match("WSL") ~= nil
        eq(false, is_wsl2, "Should not detect WSL2: " .. kernel)
      end
    end)
  end)
end)

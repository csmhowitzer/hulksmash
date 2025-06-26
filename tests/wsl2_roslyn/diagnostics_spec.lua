---@diagnostic disable: undefined-field
-- Tests for WSL2 Roslyn diagnostics functionality
-- Run with: :PlenaryBustedFile %
--
-- Note: Simplified tests that focus on core diagnostic logic without module dependencies

local eq = assert.are.same

describe("WSL2 Diagnostic Concepts", function()

  describe("environment detection patterns", function()
    it("should detect WSL2 from uname output", function()
      local wsl2_patterns = {
        "5.15.90.1-microsoft-standard-WSL2",
        "4.19.128-microsoft-standard",
        "5.10.16.3-microsoft-standard-WSL2",
        "6.1.21.2-microsoft-standard-WSL2+"
      }

      for _, kernel in ipairs(wsl2_patterns) do
        local is_wsl2 = kernel:match("microsoft") ~= nil or kernel:match("WSL") ~= nil
        eq(true, is_wsl2, "Should detect WSL2 in kernel: " .. kernel)
      end
    end)

    it("should not detect WSL2 in regular Linux", function()
      local linux_patterns = {
        "5.15.0-generic",
        "5.4.0-74-generic",
        "6.2.0-26-generic",
        "5.19.0-arch1-1"
      }

      for _, kernel in ipairs(linux_patterns) do
        local is_wsl2 = kernel:match("microsoft") ~= nil or kernel:match("WSL") ~= nil
        eq(false, is_wsl2, "Should not detect WSL2 in kernel: " .. kernel)
      end
    end)
  end)

  describe("wslpath availability patterns", function()
    it("should detect wslpath availability from which output", function()
      local available_outputs = {
        "/usr/bin/wslpath",
        "/bin/wslpath",
        "/usr/local/bin/wslpath"
      }

      for _, output in ipairs(available_outputs) do
        local is_available = output ~= ""
        eq(true, is_available, "Should detect wslpath available: " .. output)
      end
    end)

    it("should detect wslpath unavailable from empty output", function()
      local unavailable_outputs = {
        "",
        nil
      }

      for _, output in ipairs(unavailable_outputs) do
        local is_available = output and output ~= ""
        eq(false, is_available, "Should detect wslpath unavailable")
      end
    end)
  end)

  describe("diagnostic output patterns", function()
    it("should format diagnostic headers correctly", function()
      local headers = {
        "=== WSL2 Environment Check ===",
        "=== LSP Status ===",
        "=== Decompiled Files Check ===",
        "=== wslpath Dependency Check ===",
        "=== Summary ==="
      }

      for _, header in ipairs(headers) do
        eq(true, header:match("^=== .* ===$") ~= nil, "Should match header format: " .. header)
      end
    end)

    it("should format status indicators correctly", function()
      local status_patterns = {
        "✓ Found: /tmp/MetadataAsSource",
        "✗ Not found: /var/tmp/MetadataAsSource",
        "✓ Roslyn LSP is active",
        "✗ Roslyn LSP not found"
      }

      for _, pattern in ipairs(status_patterns) do
        -- Check for either checkmark or X at the beginning
        local has_checkmark = pattern:match("^✓ ") ~= nil
        local has_x_mark = pattern:match("^✗ ") ~= nil
        local has_indicator = has_checkmark or has_x_mark

        eq(true, has_indicator, "Should have status indicator: " .. pattern)
      end
    end)
  end)
end)

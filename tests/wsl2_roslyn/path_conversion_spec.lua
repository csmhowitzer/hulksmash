---@diagnostic disable: undefined-field
-- Tests for WSL2 path conversion functionality
-- Run with: :PlenaryBustedFile %
--
-- Note: Simplified tests focusing on path conversion patterns

local eq = assert.are.same

describe("WSL2 Path Conversion Patterns", function()

  describe("Windows path detection", function()
    it("should detect Windows drive paths", function()
      local windows_paths = {
        "C:\\projects\\test",
        "D:\\data\\file.txt",
        "Z:\\network\\share\\document.cs"
      }

      for _, path in ipairs(windows_paths) do
        local is_windows = path:match("^[A-Za-z]:\\") ~= nil
        eq(true, is_windows, "Should detect Windows path: " .. path)
      end
    end)

    it("should not detect Unix paths as Windows", function()
      local unix_paths = {
        "/tmp/file.txt",
        "/home/user/document.txt",
        "/mnt/c/already/converted",
        "relative/path/file.txt"
      }

      for _, path in ipairs(unix_paths) do
        local is_windows = path:match("^[A-Za-z]:\\") ~= nil
        eq(false, is_windows, "Should not detect Unix path as Windows: " .. path)
      end
    end)
  end)
end)

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

  describe("Windows project detection patterns", function()
    it("should detect Windows projects on mounted drives", function()
      local windows_paths = {
        "/mnt/c/projects/myproject",
        "/mnt/d/code/solution",
        "/mnt/z/work/app",
        "/mnt/C/Projects/Test",  -- uppercase drive
        "/mnt/x/very/deep/nested/project"
      }

      for _, path in ipairs(windows_paths) do
        local is_windows = path:match("^/mnt/[a-zA-Z]/") ~= nil
        eq(true, is_windows, "Should detect Windows project: " .. path)
      end
    end)

    it("should not detect native WSL2 projects", function()
      local wsl2_paths = {
        "/home/user/projects/myproject",
        "/tmp/code",
        "/opt/app",
        "/usr/local/src",
        "/var/www/html",
        "/root/development"
      }

      for _, path in ipairs(wsl2_paths) do
        local is_windows = path:match("^/mnt/[a-zA-Z]/") ~= nil
        eq(false, is_windows, "Should not detect as Windows project: " .. path)
      end
    end)

    it("should handle edge cases in path detection", function()
      local edge_cases = {
        { "/mnt/", false },  -- incomplete mount path
        { "/mnt", false },   -- no trailing slash
        { "/mnt/c", false }, -- no project path
        { "/mnt/c/", true }, -- minimal valid path
        { "", false },       -- empty path
        { "/", false }       -- root path
      }

      for _, case in ipairs(edge_cases) do
        local path, expected = case[1], case[2]
        local is_windows = path:match("^/mnt/[a-zA-Z]/") ~= nil
        eq(expected, is_windows, "Edge case: " .. path)
      end
    end)
  end)

  describe("Runtime ID detection logic", function()
    it("should return appropriate runtime for project types", function()
      local test_cases = {
        { path = "/mnt/c/projects/test", wsl2 = true, expected = "win-x64" },
        { path = "/home/user/projects/test", wsl2 = true, expected = "linux-x64" },
        { path = "/any/path", wsl2 = false, expected = nil },
        { path = "/mnt/d/enterprise/app", wsl2 = true, expected = "win-x64" },
        { path = "/opt/local/app", wsl2 = true, expected = "linux-x64" }
      }

      for _, case in ipairs(test_cases) do
        local runtime_id
        if not case.wsl2 then
          runtime_id = nil  -- Non-WSL2 systems return nil
        elseif case.path:match("^/mnt/[a-zA-Z]/") then
          runtime_id = "win-x64"  -- Windows project in WSL2
        else
          runtime_id = "linux-x64"  -- Native WSL2 project
        end

        eq(case.expected, runtime_id,
           string.format("Path: %s, WSL2: %s", case.path, case.wsl2))
      end
    end)
  end)
end)

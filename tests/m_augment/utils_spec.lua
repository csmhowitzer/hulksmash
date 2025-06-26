---@diagnostic disable: undefined-field
-- Tests for m_augment.utils module
-- Run with: :PlenaryBustedFile %

local eq = assert.are.same
local utils = require("m_augment.utils")

describe("m_augment.utils", function()
  describe("file operations", function()
    it("should read file content", function()
      local test_file_path = vim.fn.tempname()
      local content = "Hello, World!\nSecond line"
      vim.fn.writefile(vim.split(content, "\n"), test_file_path)

      local result = utils.read_file_content(test_file_path)
      -- Remove trailing newline that vim.fn.writefile adds
      result = result:gsub("\n$", "")
      eq(content, result)

      -- Cleanup
      vim.fn.delete(test_file_path)
    end)

    it("should return empty string for non-existent file", function()
      local result = utils.read_file_content("/non/existent/file.txt")
      eq("", result)
    end)

    it("should check if file exists", function()
      local test_file_path = vim.fn.tempname()

      -- File doesn't exist yet
      eq(false, utils.file_exists(test_file_path))

      -- Create file
      vim.fn.writefile({"test"}, test_file_path)
      eq(true, utils.file_exists(test_file_path))

      -- Cleanup
      vim.fn.delete(test_file_path)
    end)
  end)

  describe("workspace management", function()
    local function create_mock_workspace()
      local workspace_path = vim.fn.tempname() .. "_workspaces.json"
      local workspace_data = {
        workspaces = {
          {
            name = "test_workspace",
            path = "/tmp/test_workspace"
          },
          {
            name = "another_test",
            path = "/tmp/another_test"
          }
        }
      }

      local file = io.open(workspace_path, "w")
      if file then
        file:write(vim.json.encode(workspace_data))
        file:close()
      end

      return workspace_path
    end

    it("should read workspaces from file", function()
      local workspace_path = create_mock_workspace()
      local workspaces = utils.read_workspaces(workspace_path)

      assert(workspaces.workspaces ~= nil, "Should have workspaces key")
      eq(2, #workspaces.workspaces)
      eq("test_workspace", workspaces.workspaces[1].name)
      eq("/tmp/test_workspace", workspaces.workspaces[1].path)

      -- Cleanup
      vim.fn.delete(workspace_path)
    end)

    it("should return empty table for invalid JSON", function()
      -- Create file with invalid JSON
      local invalid_path = vim.fn.tempname()
      vim.fn.writefile({"invalid json content"}, invalid_path)

      local workspaces = utils.read_workspaces(invalid_path)
      eq({}, workspaces)

      vim.fn.delete(invalid_path)
    end)

    it("should ingest workspaces and return folder paths", function()
      local workspace_path = create_mock_workspace()
      local folders = utils.ingest_workspaces(workspace_path)

      eq(2, #folders)
      eq("/tmp/test_workspace", folders[1])
      eq("/tmp/another_test", folders[2])

      vim.fn.delete(workspace_path)
    end)

    it("should return nil for missing workspaces", function()
      local empty_path = vim.fn.tempname()
      vim.fn.writefile({"{}"}, empty_path)

      local folders = utils.ingest_workspaces(empty_path)
      eq(nil, folders)

      vim.fn.delete(empty_path)
    end)
  end)

end)

-- Test initialization and setup for m_augment plugin tests
-- This file sets up the testing environment for the Augment Neovim plugin

-- Ensure plenary is available for testing
local ok, plenary = pcall(require, "plenary")
if not ok then
  error("plenary.nvim is required for running tests. Please install it first.")
end

-- Add the lua directory to package.path for module loading
local config_path = vim.fn.stdpath("config")
package.path = package.path .. ";" .. config_path .. "/lua/?.lua"
package.path = package.path .. ";" .. config_path .. "/lua/?/init.lua"

-- Test utilities and helpers
local M = {}

---Create a temporary buffer for testing
---@return integer bufnr Buffer number
function M.create_test_buffer()
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = bufnr })
  return bufnr
end

---Create a temporary file for testing
---@param content string[] Lines of content
---@param filetype string? File type to set
---@return integer bufnr Buffer number
---@return string filepath Temporary file path
function M.create_test_file(content, filetype)
  local filepath = vim.fn.tempname()
  vim.fn.writefile(content or {}, filepath)
  
  local bufnr = vim.fn.bufadd(filepath)
  vim.fn.bufload(bufnr)
  
  if filetype then
    vim.api.nvim_set_option_value("filetype", filetype, { buf = bufnr })
  end
  
  return bufnr, filepath
end

---Clean up test buffer
---@param bufnr integer Buffer number to clean up
function M.cleanup_buffer(bufnr)
  if vim.api.nvim_buf_is_valid(bufnr) then
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end
end

---Clean up test file
---@param filepath string File path to clean up
function M.cleanup_file(filepath)
  if vim.fn.filereadable(filepath) == 1 then
    vim.fn.delete(filepath)
  end
end

---Mock vim.notify for testing
---@param messages table Table to store messages
---@return function restore_notify Function to restore original notify
function M.mock_notify(messages)
  messages = messages or {}
  local original_notify = vim.notify
  
  vim.notify = function(msg, level, opts)
    table.insert(messages, {
      message = msg,
      level = level,
      opts = opts
    })
  end
  
  return function()
    vim.notify = original_notify
  end
end

---Create a mock workspace configuration for testing
---@return string workspace_path Path to temporary workspace file
function M.create_mock_workspace()
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

---Assert that a table contains expected keys
---@param tbl table Table to check
---@param expected_keys string[] Expected keys
function M.assert_has_keys(tbl, expected_keys)
  for _, key in ipairs(expected_keys) do
    assert(tbl[key] ~= nil, "Expected key '" .. key .. "' not found in table")
  end
end

---Assert that a function throws an error
---@param func function Function to test
---@param expected_error string? Expected error message pattern
function M.assert_error(func, expected_error)
  local ok, err = pcall(func)
  assert(not ok, "Expected function to throw an error")
  
  if expected_error then
    assert(string.match(err, expected_error), 
           "Error message '" .. err .. "' does not match expected pattern '" .. expected_error .. "'")
  end
end

return M

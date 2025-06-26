---@diagnostic disable: undefined-field
-- Tests for m_augment.init module
-- Run with: :PlenaryBustedFile %

local eq = assert.are.same
local m_augment = require("m_augment")

describe("m_augment.init", function()
  local original_keymaps = {}
  local original_commands = {}
  local original_autocmds = {}

  before_each(function()
    -- Store original state to restore later
    original_keymaps = {}
    original_commands = {}
    original_autocmds = {}
  end)

  after_each(function()
    -- Clean up any keymaps, commands, autocmds created during tests
    -- This is a simplified cleanup - in practice you might want more thorough cleanup
  end)

  describe("setup", function()
    it("should initialize with default options", function()
      local state = require("m_augment.state")
      
      m_augment.setup()
      
      -- Check that state was initialized
      assert(state.config ~= nil, "State config should be initialized")
      eq("~/.augment/workspaces.json", state.config.workspace_path)
      eq(4, state.config.max_recent_buffers)
      eq(10, state.config.max_code_blocks)
    end)

    it("should initialize with custom options", function()
      local state = require("m_augment.state")
      local custom_opts = {
        workspace_path = "/custom/path/workspaces.json",
        max_recent_buffers = 8,
        max_code_blocks = 20,
        inline = {
          trigger_mode = "auto",
          default_chunk_size = 5
        }
      }
      
      m_augment.setup(custom_opts)
      
      eq("/custom/path/workspaces.json", state.config.workspace_path)
      eq(8, state.config.max_recent_buffers)
      eq(20, state.config.max_code_blocks)
    end)
  end)

  describe("keymaps", function()
    it("should set up core keymaps", function()
      m_augment.setup()

      -- Check that some core keymaps exist
      -- Note: This is a basic check - testing actual keymap functionality would be more complex
      local keymaps = vim.api.nvim_get_keymap("n")

      local augment_keymaps = 0
      for _, keymap in ipairs(keymaps) do
        -- Look for any keymap that contains "augment" in the description (case insensitive)
        if keymap.desc and string.match(string.lower(keymap.desc), "augment") then
          augment_keymaps = augment_keymaps + 1
        end
      end

      assert(augment_keymaps > 0, "Should have set up some Augment keymaps")
    end)
  end)

  describe("commands", function()
    it("should create user commands", function()
      m_augment.setup()
      
      -- Check that AugmentDebugBuffers command exists
      local commands = vim.api.nvim_get_commands({})
      assert(commands.AugmentDebugBuffers ~= nil, "AugmentDebugBuffers command should exist")
    end)
  end)

  describe("autocmds", function()
    it("should set up buffer tracking autocmd", function()
      m_augment.setup()
      
      -- Check that the AugmentBufferTracking augroup exists
      local augroups = vim.api.nvim_get_autocmds({ group = "AugmentBufferTracking" })
      assert(#augroups > 0, "AugmentBufferTracking augroup should exist")
      
      -- Check that it has a BufEnter autocmd
      local buf_enter_found = false
      for _, autocmd in ipairs(augroups) do
        if autocmd.event == "BufEnter" then
          buf_enter_found = true
          break
        end
      end
      assert(buf_enter_found, "Should have BufEnter autocmd for buffer tracking")
    end)
  end)

  describe("module integration", function()
    it("should initialize all submodules", function()
      -- Test that setup doesn't throw errors and initializes submodules
      local success, err = pcall(function()
        m_augment.setup({
          workspace_path = vim.fn.tempname() .. "_test_workspaces.json",
          max_recent_buffers = 2,
          max_code_blocks = 5
        })
      end)
      
      assert(success, "Setup should complete without errors: " .. (err or ""))
      
      -- Verify submodules are accessible
      assert(require("m_augment.state") ~= nil, "State module should be loaded")
      assert(require("m_augment.utils") ~= nil, "Utils module should be loaded")
      assert(require("m_augment.ui") ~= nil, "UI module should be loaded")
      assert(require("m_augment.code") ~= nil, "Code module should be loaded")
      assert(require("m_augment.inline") ~= nil, "Inline module should be loaded")
    end)
  end)

  describe("workspace integration", function()
    it("should set vim global workspace folders", function()
      -- Create a temporary workspace file
      local workspace_path = vim.fn.tempname() .. "_workspaces.json"
      local workspace_data = {
        workspaces = {
          { name = "test1", path = "/tmp/test1" },
          { name = "test2", path = "/tmp/test2" }
        }
      }
      
      local file = io.open(workspace_path, "w")
      if file then
        file:write(vim.json.encode(workspace_data))
        file:close()
      end
      
      m_augment.setup({ workspace_path = workspace_path })
      
      -- Check that vim.g.augment_workspace_folders was set
      assert(vim.g.augment_workspace_folders ~= nil, "Should set global workspace folders")
      
      -- Cleanup
      vim.fn.delete(workspace_path)
    end)
  end)
end)

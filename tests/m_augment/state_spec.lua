---@diagnostic disable: undefined-field
-- Tests for m_augment.state module
-- Run with: :PlenaryBustedFile %

local eq = assert.are.same
local state = require("m_augment.state")

describe("m_augment.state", function()
  local original_state

  before_each(function()
    -- Save original state
    original_state = vim.deepcopy(state)
    
    -- Reset state to defaults
    state.response_info = {
      bufnr = nil,
      winid = nil,
      filetype = nil,
      last_updated = nil,
    }
    state.recent_buffers = {
      max_size = 4,
      items = {},
    }
    state.recent_code_blocks = {
      max_size = 10,
      items = {},
    }
    state.config = {
      workspace_path = "~/.augment/workspaces.json",
      max_recent_buffers = 4,
      max_code_blocks = 10,
    }
    state.buffer_content = {}
    state.message_history = {}
    state.history_index = 0
    state.source_bufnr = nil
    state.source_file = nil
  end)

  after_each(function()
    -- Restore original state
    for k, v in pairs(original_state) do
      state[k] = v
    end
  end)

  describe("init", function()
    it("should initialize with default configuration", function()
      state.init()
      
      eq("~/.augment/workspaces.json", state.config.workspace_path)
      eq(4, state.config.max_recent_buffers)
      eq(10, state.config.max_code_blocks)
      eq(4, state.recent_buffers.max_size)
      eq(10, state.recent_code_blocks.max_size)
    end)

    it("should initialize with custom configuration", function()
      local opts = {
        workspace_path = "/custom/path/workspaces.json",
        max_recent_buffers = 8,
        max_code_blocks = 20
      }
      
      state.init(opts)
      
      eq("/custom/path/workspaces.json", state.config.workspace_path)
      eq(8, state.config.max_recent_buffers)
      eq(20, state.config.max_code_blocks)
      eq(8, state.recent_buffers.max_size)
      eq(20, state.recent_code_blocks.max_size)
    end)
  end)

  describe("source management", function()
    it("should set and get source buffer and file", function()
      local bufnr = 123
      local file = "/path/to/file.lua"
      
      state.set_source(bufnr, file)
      
      eq(bufnr, state.get_source_buffer())
      eq(file, state.get_source_file())
    end)

    it("should return nil for unset source", function()
      eq(nil, state.get_source_buffer())
      eq(nil, state.get_source_file())
    end)
  end)

  describe("recent buffers", function()
    it("should add buffer to recent list", function()
      -- Create a test buffer with a name
      local test_bufnr = vim.api.nvim_create_buf(false, true)
      local test_file = vim.fn.tempname() .. ".lua"
      vim.api.nvim_buf_set_name(test_bufnr, test_file)
      vim.api.nvim_set_option_value("filetype", "lua", { buf = test_bufnr })

      -- Switch to test buffer to trigger update
      vim.api.nvim_set_current_buf(test_bufnr)
      state.update_recent_buffers()

      eq(1, #state.recent_buffers.items)
      eq(test_bufnr, state.recent_buffers.items[1].bufnr)
      eq("lua", state.recent_buffers.items[1].filetype)

      -- Cleanup
      vim.api.nvim_buf_delete(test_bufnr, { force = true })
    end)

    it("should not add special buffers", function()
      -- Create a special buffer (unnamed)
      local special_bufnr = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_set_current_buf(special_bufnr)

      state.update_recent_buffers()

      eq(0, #state.recent_buffers.items)

      vim.api.nvim_buf_delete(special_bufnr, { force = true })
    end)

    it("should maintain max_size limit", function()
      state.recent_buffers.max_size = 2

      -- Create multiple test buffers
      local buffers = {}
      for i = 1, 3 do
        local bufnr = vim.api.nvim_create_buf(false, true)
        local test_file = vim.fn.tempname() .. "_" .. i .. ".lua"
        vim.api.nvim_buf_set_name(bufnr, test_file)
        vim.api.nvim_set_option_value("filetype", "lua", { buf = bufnr })
        table.insert(buffers, bufnr)
        vim.api.nvim_set_current_buf(bufnr)
        state.update_recent_buffers()
      end

      eq(2, #state.recent_buffers.items)

      -- Cleanup
      for _, bufnr in ipairs(buffers) do
        vim.api.nvim_buf_delete(bufnr, { force = true })
      end
    end)
  end)

  describe("code blocks", function()
    it("should add code block to recent list", function()
      state.add_code_block("lua", "print('hello')")
      
      eq(1, #state.recent_code_blocks.items)
      eq("lua", state.recent_code_blocks.items[1].language)
      eq("print('hello')", state.recent_code_blocks.items[1].content)
      assert(state.recent_code_blocks.items[1].timestamp ~= nil)
    end)

    it("should maintain max_size limit for code blocks", function()
      state.recent_code_blocks.max_size = 2

      state.add_code_block("lua", "code1")
      state.add_code_block("python", "code2")
      state.add_code_block("javascript", "code3")

      eq(2, #state.recent_code_blocks.items)
      eq("javascript", state.recent_code_blocks.items[1].language) -- Most recent first
      -- The second item should be "python" since "lua" was removed when max_size was exceeded
      eq("python", state.recent_code_blocks.items[2].language)
    end)
  end)

  describe("response info", function()
    it("should update response info", function()
      local bufnr = vim.api.nvim_create_buf(false, true)
      local winid = 789 -- Window ID can be fake for this test

      state.update_response_info(bufnr, winid)

      eq(bufnr, state.response_info.bufnr)
      eq(winid, state.response_info.winid)
      assert(state.response_info.last_updated ~= nil)

      vim.api.nvim_buf_delete(bufnr, { force = true })
    end)
  end)

  describe("message history", function()
    it("should save message to history", function()
      local message = "test message"
      
      state.save_to_history(message)
      
      eq(1, #state.message_history)
      eq(message, state.message_history[1])
      eq(1, state.history_index)
    end)

    it("should navigate history forward and backward", function()
      state.save_to_history("message1")
      state.save_to_history("message2")
      state.save_to_history("message3")

      -- After saving, history_index should be at the length (3)
      -- History array: ["message3", "message2", "message1"] (newest first)
      -- Current index: 3, pointing to "message1"

      -- Navigate forward (towards newer messages)
      local msg = state.navigate_history("fwd")
      eq("message1", msg) -- Should stay at current position (already at max)

      -- Navigate backward (towards older messages)
      msg = state.navigate_history("back")
      eq("message2", msg)

      msg = state.navigate_history("back")
      eq("message3", msg) -- Newest message (index 1)

      msg = state.navigate_history("back")
      eq("message3", msg) -- Should stay at beginning (index 1)
    end)

    it("should return nil for empty history", function()
      local msg = state.navigate_history("fwd")
      eq(nil, msg)
    end)
  end)
end)

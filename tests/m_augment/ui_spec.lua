---@diagnostic disable: undefined-field
-- Tests for m_augment.ui module
-- Run with: :PlenaryBustedFile %

local eq = assert.are.same
local ui = require("m_augment.ui")
local state = require("m_augment.state")

describe("m_augment.ui", function()
  before_each(function()
    -- Reset state
    state.response_info = {
      bufnr = nil,
      winid = nil,
      filetype = nil,
      last_updated = nil,
    }
    state.buffer_content = {}
    state.message_history = {}
    state.history_index = 0
  end)

  after_each(function()
    -- Close any open windows
    if state.response_info.winid and vim.api.nvim_win_is_valid(state.response_info.winid) then
      vim.api.nvim_win_close(state.response_info.winid, true)
    end
  end)

  describe("setup", function()
    it("should define highlights", function()
      ui.setup({})
      
      -- Check that highlights are defined (this is a basic check)
      -- In a real test environment, you might want to check the actual highlight values
      local highlights = {
        "AugmentChatBorder",
        "AugmentChatTitle", 
        "AugmentChatFooter"
      }
      
      for _, hl in ipairs(highlights) do
        local hl_def = vim.api.nvim_get_hl(0, { name = hl })
        assert(hl_def ~= nil, "Highlight " .. hl .. " should be defined")
      end
    end)
  end)

  describe("open_chat_buffer", function()
    it("should create and configure chat buffer", function()
      local test_bufnr = vim.api.nvim_create_buf(false, true)
      local test_file = vim.fn.tempname() .. ".lua"
      vim.api.nvim_buf_set_name(test_bufnr, test_file)
      vim.api.nvim_set_current_buf(test_bufnr)

      ui.open_chat_buffer()

      -- Verify state was updated
      assert(state.response_info.bufnr ~= nil, "Response buffer should be set")
      assert(state.response_info.winid ~= nil, "Response window should be set")

      -- Verify buffer properties
      local bufnr = state.response_info.bufnr
      assert(vim.api.nvim_buf_is_valid(bufnr), "Buffer should be valid")
      eq("markdown", vim.api.nvim_get_option_value("filetype", { buf = bufnr }))
      eq("hide", vim.api.nvim_get_option_value("bufhidden", { buf = bufnr }))

      -- Verify window properties
      local winid = state.response_info.winid
      assert(vim.api.nvim_win_is_valid(winid), "Window should be valid")
      eq(true, vim.api.nvim_get_option_value("wrap", { win = winid }))
      eq(true, vim.api.nvim_get_option_value("linebreak", { win = winid }))

      -- Cleanup
      vim.api.nvim_buf_delete(test_bufnr, { force = true })
    end)

    it("should restore buffer content if available", function()
      local test_bufnr = vim.api.nvim_create_buf(false, true)
      local test_file = vim.fn.tempname() .. ".lua"
      vim.api.nvim_buf_set_name(test_bufnr, test_file)
      vim.api.nvim_set_current_buf(test_bufnr)

      state.buffer_content = {"line 1", "line 2", "line 3"}

      ui.open_chat_buffer()

      local bufnr = state.response_info.bufnr
      local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
      eq({"line 1", "line 2", "line 3"}, lines)

      -- Cleanup
      vim.api.nvim_buf_delete(test_bufnr, { force = true })
    end)
  end)

  describe("send_selection_to_chat", function()
    it("should format selection with file context", function()
      local test_bufnr = vim.api.nvim_create_buf(false, true)
      local test_file = vim.fn.tempname() .. ".lua"
      vim.api.nvim_buf_set_name(test_bufnr, test_file)
      vim.api.nvim_set_option_value("filetype", "lua", { buf = test_bufnr })
      vim.api.nvim_set_current_buf(test_bufnr)

      vim.api.nvim_buf_set_lines(test_bufnr, 0, -1, false, {
        "function test()",
        "  print('hello')",
        "end"
      })

      -- Select all text (simulate visual selection)
      vim.api.nvim_win_set_cursor(0, {1, 0})
      vim.cmd("normal! VG")

      ui.send_selection_to_chat()

      -- Check that buffer content was set with proper formatting
      assert(#state.buffer_content > 0, "Buffer content should be set")

      local content = table.concat(state.buffer_content, "\n")
      assert(string.match(content, "```lua"), "Should contain lua code block")
      assert(string.match(content, "function test"), "Should contain selected text")
      assert(string.match(content, "File Path:"), "Should contain file path")

      -- Cleanup
      vim.api.nvim_buf_delete(test_bufnr, { force = true })
    end)
  end)

end)

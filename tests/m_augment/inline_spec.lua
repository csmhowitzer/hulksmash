---@diagnostic disable: undefined-field
-- Tests for m_augment.inline module
-- Run with: :PlenaryBustedFile %

local eq = assert.are.same
local inline = require("m_augment.inline")

describe("m_augment.inline", function()
  local test_bufnr

  before_each(function()
    test_bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(test_bufnr, 0, -1, false, {
      "function example()",
      "  local x = 1",
      "  local y = 2", 
      "  return x + y",
      "end"
    })
    
    -- Reset inline state
    inline.current_suggestion = {
      bufnr = nil,
      start_line = nil,
      end_line = nil,
      original_lines = {},
      suggested_lines = {},
      current_chunk = 1,
      total_chunks = 0,
      extmarks = {},
      namespace = vim.api.nvim_create_namespace("augment_inline_test"),
      approved_chunks = {},
      current_line_idx = 1,
    }
  end)

  after_each(function()
    if test_bufnr and vim.api.nvim_buf_is_valid(test_bufnr) then
      vim.api.nvim_buf_delete(test_bufnr, { force = true })
    end
    
    -- Clear any active suggestions
    if inline.current_suggestion.bufnr then
      inline.clear_current_suggestion()
    end
  end)

  describe("setup", function()
    it("should initialize with default config", function()
      inline.setup({})

      assert(inline.config ~= nil, "Config should be initialized")
      eq("manual", inline.config.trigger_mode)
      eq(3, inline.config.chunk_size)
    end)

    it("should accept custom config", function()
      inline.setup({
        trigger_mode = "auto",
        chunk_size = 5
      })

      eq("auto", inline.config.trigger_mode)
      eq(5, inline.config.chunk_size)
    end)
  end)

  describe("show_suggestion_from_chat_response", function()
    it("should initialize suggestion state", function()
      local suggestion_lines = {
        "function improved()",
        "  local a = 10",
        "  local b = 20",
        "  return a * b",
        "end"
      }
      
      inline.show_suggestion_from_chat_response(test_bufnr, 1, suggestion_lines)

      eq(test_bufnr, inline.current_suggestion.bufnr)
      eq(suggestion_lines, inline.current_suggestion.suggested_lines)
      eq(1, inline.current_suggestion.current_line_idx)
    end)
  end)

  describe("chunk management", function()
    it("should calculate current chunk lines correctly", function()
      inline.current_suggestion.bufnr = test_bufnr
      inline.current_suggestion.suggested_lines = {
        "line 1", "line 2", "line 3", "line 4", "line 5", "line 6"
      }
      inline.current_suggestion.current_line_idx = 1
      inline.config.chunk_size = 3

      local chunk_lines = inline.get_current_chunk_lines()

      eq({1, 2, 3}, chunk_lines)
    end)

    it("should handle chunk at end of suggestions", function()
      inline.current_suggestion.bufnr = test_bufnr
      inline.current_suggestion.suggested_lines = {
        "line 1", "line 2", "line 3", "line 4", "line 5"
      }
      inline.current_suggestion.current_line_idx = 4  -- Start at line 4
      inline.config.chunk_size = 3

      local chunk_lines = inline.get_current_chunk_lines()

      eq({4, 5}, chunk_lines)  -- Only 2 lines left
    end)
  end)

  describe("chunk navigation", function()
    it("should navigate to next chunk", function()
      inline.current_suggestion.bufnr = test_bufnr
      inline.current_suggestion.start_line = 1
      inline.current_suggestion.suggested_lines = {"line 1", "line 2", "line 3", "line 4"}
      inline.current_suggestion.current_chunk = 1
      inline.current_suggestion.total_chunks = 2
      inline.current_suggestion.current_line_idx = 1
      inline.config.chunk_size = 2

      inline.next_chunk()

      eq(2, inline.current_suggestion.current_chunk)
    end)

    it("should navigate to previous chunk", function()
      inline.current_suggestion.bufnr = test_bufnr
      inline.current_suggestion.start_line = 1
      inline.current_suggestion.suggested_lines = {"line 1", "line 2", "line 3", "line 4"}
      inline.current_suggestion.current_chunk = 2
      inline.current_suggestion.total_chunks = 2
      inline.current_suggestion.current_line_idx = 3
      inline.config.chunk_size = 2

      inline.prev_chunk()

      eq(1, inline.current_suggestion.current_chunk)
    end)
  end)

  describe("chunk size adjustment", function()
    it("should increase chunk size", function()
      inline.current_suggestion.bufnr = test_bufnr
      inline.current_suggestion.start_line = 1
      inline.current_suggestion.suggested_lines = {"line 1", "line 2", "line 3"}
      inline.current_suggestion.current_line_idx = 1
      inline.config.chunk_size = 3

      inline.increase_chunk_size()

      eq(4, inline.config.chunk_size)
    end)

    it("should decrease chunk size", function()
      inline.current_suggestion.bufnr = test_bufnr
      inline.current_suggestion.start_line = 1
      inline.current_suggestion.suggested_lines = {"line 1", "line 2", "line 3"}
      inline.current_suggestion.current_line_idx = 1
      inline.config.chunk_size = 3

      inline.decrease_chunk_size()

      eq(2, inline.config.chunk_size)
    end)
  end)

  describe("clear_current_suggestion", function()
    it("should clear all suggestion state", function()
      inline.current_suggestion.bufnr = test_bufnr
      inline.current_suggestion.suggested_lines = {"test"}

      inline.clear_current_suggestion()

      eq(nil, inline.current_suggestion.bufnr)
      eq({}, inline.current_suggestion.suggested_lines)
    end)
  end)
end)

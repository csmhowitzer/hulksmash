local M = {}
local state = require("m_augment.state")

---@class InlineConfig
---@field chunk_mode "line"|"word" Chunking mode for suggestions
---@field chunk_size integer Number of lines per chunk (when in line mode)
---@field trigger_mode "manual"|"auto" When to trigger suggestions
---@field delay_ms integer Delay before showing suggestions
---@field enabled boolean Whether inline suggestions are enabled

---@class CurrentSuggestion
---@field bufnr integer|nil Buffer number containing the suggestion
---@field start_line integer|nil Starting line in the buffer
---@field end_line integer|nil Ending line in the buffer
---@field original_lines string[] Original lines from the buffer
---@field suggested_lines string[] Lines suggested by Augment
---@field current_chunk integer Current chunk being reviewed
---@field total_chunks integer Total number of chunks
---@field extmarks integer[] List of extmark IDs for cleanup
---@field namespace integer|nil Namespace for extmarks
---@field approved_chunks table<integer, boolean> Track which chunks have been approved
---@field current_line_idx integer Track the actual line we're currently reviewing

-- Configuration
---@type InlineConfig
M.config = {
  chunk_mode = "line",      -- "word" or "line"
  chunk_size = 3,           -- lines per chunk (when in line mode)
  trigger_mode = "manual",  -- "manual" or "auto"
  delay_ms = 500,
  enabled = true,
}

-- State for current suggestion
---@type CurrentSuggestion
M.current_suggestion = {
  bufnr = nil,
  start_line = nil,
  end_line = nil,
  original_lines = {},
  suggested_lines = {},
  current_chunk = 1,
  total_chunks = 0,
  extmarks = {},
  namespace = nil,
  approved_chunks = {},  -- Track which chunks have been approved
  current_line_idx = 1,  -- Track the actual line we're currently reviewing
}

---Setup the inline suggestion system
---@param opts InlineConfig|nil Configuration options
function M.setup(opts)
  opts = opts or {}
  M.config = vim.tbl_deep_extend("force", M.config, opts)

  -- Create namespace for extmarks
  M.current_suggestion.namespace = vim.api.nvim_create_namespace("augment_inline_suggestions")

  -- Define highlights immediately and on ColorScheme changes
  M.define_highlights()
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("AugmentInlineHighlights", { clear = true }),
    callback = function()
      M.define_highlights()
    end,
  })

  M.setup_keymaps()
  M.setup_autocmds()
end

---Define highlight groups for inline suggestions
function M.define_highlights()
  -- More visible highlights for suggestions
  vim.api.nvim_set_hl(0, "AugmentSuggestion", {
    fg = "#6c7086", italic = true, bg = "#1e1e2e"
  })
  vim.api.nvim_set_hl(0, "AugmentSuggestionAdd", {
    fg = "#a6d189", bg = "#313244", bold = true  -- More visible green
  })
  vim.api.nvim_set_hl(0, "AugmentSuggestionChange", {
    fg = "#f9e2af", bg = "#45475a", bold = true  -- More visible yellow
  })
  vim.api.nvim_set_hl(0, "AugmentSuggestionDelete", {
    fg = "#f38ba8", bg = "#442d30", bold = true
  })
  vim.api.nvim_set_hl(0, "AugmentCurrentChunk", {
    fg = "#cba6f7", bg = "#45475a", bold = true, italic = true  -- More visible purple
  })
  vim.api.nvim_set_hl(0, "AugmentApprovedChunk", {
    fg = "#94e2d5", bg = "#2d3343", bold = true  -- Teal for approved chunks
  })
end

---Setup keymaps for inline suggestions
function M.setup_keymaps()
  -- Accept current chunk
  vim.keymap.set("n", "<C-y>", function()
    M.accept_current_chunk()
  end, { desc = "Accept Augment suggestion chunk" })

  -- Navigate chunks (only when suggestion is active)
  vim.keymap.set("n", "<C-n>", function()
    if M.current_suggestion.bufnr then
      M.next_chunk()
    else
      -- Fallback to normal <C-n> behavior
      vim.cmd("normal! <C-n>")
    end
  end, { desc = "Augment next chunk (when active)" })

  vim.keymap.set("n", "<C-p>", function()
    if M.current_suggestion.bufnr then
      M.prev_chunk()
    else
      -- Fallback to normal <C-p> behavior
      vim.cmd("normal! <C-p>")
    end
  end, { desc = "Augment previous chunk (when active)" })

  -- Reject suggestion
  vim.keymap.set("n", "<leader>ar", function()
    M.reject_suggestion()
  end, { desc = "[A]ugment [R]eject suggestion" })

  -- Apply approved chunks and exit (without reviewing remaining)
  vim.keymap.set("n", "<leader>aex", function()
    if M.current_suggestion.bufnr then
      M.apply_approved_and_exit()
    end
  end, { desc = "[A]ugment [Ex]it and apply approved chunks" })

  -- Toggle modes
  vim.keymap.set("n", "<leader>atm", function()
    M.toggle_trigger_mode()
  end, { desc = "[A]ugment [T]oggle [M]ode (auto/manual)" })

  vim.keymap.set("n", "<leader>atc", function()
    M.toggle_chunk_mode()
  end, { desc = "[A]ugment [T]oggle [C]hunk mode (word/line)" })

  -- Dynamic chunk size adjustment (only when suggestion is active)
  vim.keymap.set("n", "<leader>a=", function()
    if M.current_suggestion.bufnr then
      M.increase_chunk_size()
    end
  end, { desc = "[A]ugment increase chunk size" })

  vim.keymap.set("n", "<leader>a-", function()
    if M.current_suggestion.bufnr then
      M.decrease_chunk_size()
    end
  end, { desc = "[A]ugment decrease chunk size" })
end

---Setup autocmds for inline suggestions
function M.setup_autocmds()
  -- Clear suggestions when leaving buffer or entering insert mode
  vim.api.nvim_create_autocmd({"BufLeave", "InsertEnter"}, {
    group = vim.api.nvim_create_augroup("AugmentInlineSuggestions", { clear = true }),
    callback = function()
      M.clear_current_suggestion()
    end,
  })
end

---Main function to show inline suggestions from chat response
---@param bufnr integer Buffer number to show suggestions in
---@param target_line integer Line number to start suggestions at
---@param suggested_lines string[] Lines of code suggested by Augment
function M.show_suggestion_from_chat_response(bufnr, target_line, suggested_lines)
  if not M.config.enabled then
    return
  end

  M.clear_current_suggestion()

  local current_lines = vim.api.nvim_buf_get_lines(bufnr, target_line - 1, target_line - 1 + #suggested_lines, false)

  M.current_suggestion = {
    bufnr = bufnr,
    start_line = target_line,
    end_line = target_line + #suggested_lines - 1,
    original_lines = current_lines,
    suggested_lines = suggested_lines,
    current_chunk = 1,
    total_chunks = M.calculate_total_chunks(suggested_lines),
    extmarks = {},
    namespace = M.current_suggestion.namespace,
    approved_chunks = {},  -- Initialize approved chunks
    current_line_idx = 1,  -- Start reviewing at line 1
  }

  M.render_suggestion()
  M.highlight_current_chunk()

  vim.notify(string.format("Augment suggestion ready. Chunk %d/%d. Press <C-y> to accept.",
    M.current_suggestion.current_chunk, M.current_suggestion.total_chunks), vim.log.levels.INFO)
end

---Calculate total number of chunks based on lines and chunk mode
---@param lines string[] Lines to calculate chunks for
---@return integer total_chunks Number of chunks
function M.calculate_total_chunks(lines)
  if M.config.chunk_mode == "word" then
    local total_words = 0
    for _, line in ipairs(lines) do
      local words = vim.split(line, "%s+")
      total_words = total_words + #words
    end
    return total_words
  else
    return math.ceil(#lines / M.config.chunk_size)
  end
end

function M.render_suggestion()
  local suggestion = M.current_suggestion
  if not suggestion.bufnr or not vim.api.nvim_buf_is_valid(suggestion.bufnr) then
    return
  end

  -- Clear existing extmarks
  M.clear_extmarks()

  -- Create virtual lines for the suggestion (appears as new lines)
  local virt_lines = {}
  for i, line in ipairs(suggestion.suggested_lines) do
    table.insert(virt_lines, {{" + " .. line, "AugmentSuggestionAdd"}})
  end

  -- Place virtual lines at the cursor position
  local cursor_line = suggestion.start_line - 1  -- 0-indexed
  local extmark_id = vim.api.nvim_buf_set_extmark(suggestion.bufnr, suggestion.namespace, cursor_line, 0, {
    virt_lines = virt_lines,
    virt_lines_above = false,  -- Show below cursor
  })
  table.insert(suggestion.extmarks, extmark_id)
end

function M.highlight_current_chunk()
  local suggestion = M.current_suggestion
  if not suggestion.bufnr then return end

  local chunk_lines = M.get_current_chunk_lines()

  -- Clear and re-render with current chunk highlighted
  M.clear_extmarks()

  -- Create virtual lines with current chunk highlighted
  local virt_lines = {}
  for i, line in ipairs(suggestion.suggested_lines) do
    local is_current_chunk = false
    local is_approved_chunk = suggestion.approved_chunks[i] or false

    for _, chunk_idx in ipairs(chunk_lines) do
      if i == chunk_idx then
        is_current_chunk = true
        break
      end
    end

    if is_current_chunk then
      table.insert(virt_lines, {{" → " .. line, "AugmentCurrentChunk"}})
    elseif is_approved_chunk then
      table.insert(virt_lines, {{" ✓ " .. line, "AugmentApprovedChunk"}})
    else
      table.insert(virt_lines, {{" + " .. line, "AugmentSuggestionAdd"}})
    end
  end

  -- Place virtual lines at the cursor position
  local cursor_line = suggestion.start_line - 1  -- 0-indexed
  local extmark_id = vim.api.nvim_buf_set_extmark(suggestion.bufnr, suggestion.namespace, cursor_line, 0, {
    virt_lines = virt_lines,
    virt_lines_above = false,  -- Show below cursor
  })
  table.insert(suggestion.extmarks, extmark_id)
end

---Get line indices for the current chunk
---@return integer[] chunk_lines List of line indices in current chunk
function M.get_current_chunk_lines()
  local suggestion = M.current_suggestion
  local chunk_lines = {}

  if M.config.chunk_mode == "word" then
    -- Word-by-word implementation (simplified for now)
    table.insert(chunk_lines, suggestion.current_chunk)
  else
    -- Line-based chunks starting from current_line_idx
    local start_idx = suggestion.current_line_idx
    local end_idx = math.min(start_idx + M.config.chunk_size - 1, #suggestion.suggested_lines)

    for i = start_idx, end_idx do
      table.insert(chunk_lines, i)
    end
  end

  return chunk_lines
end

---Accept the current chunk and move to next or finish
function M.accept_current_chunk()
  local suggestion = M.current_suggestion
  if not suggestion.bufnr or not vim.api.nvim_buf_is_valid(suggestion.bufnr) then
    vim.notify("No active suggestion to accept", vim.log.levels.WARN)
    return
  end

  local chunk_lines = M.get_current_chunk_lines()

  -- Mark current chunk as approved (but don't apply yet)
  for _, line_idx in ipairs(chunk_lines) do
    suggestion.approved_chunks[line_idx] = true
  end

  -- Move to next chunk or finish
  if suggestion.current_chunk < suggestion.total_chunks then
    suggestion.current_chunk = suggestion.current_chunk + 1
    -- Update current_line_idx to first line of new chunk (custom chunking)
    suggestion.current_line_idx = suggestion.current_line_idx + M.config.chunk_size
    M.render_suggestion()
    M.highlight_current_chunk()
    vim.notify(string.format("Chunk approved. Review chunk %d/%d.",
      suggestion.current_chunk, suggestion.total_chunks), vim.log.levels.INFO)
  else
    -- All chunks reviewed - now apply all approved chunks
    M.apply_all_approved_chunks()
  end
end

function M.apply_all_approved_chunks()
  local suggestion = M.current_suggestion
  local approved_lines = {}

  -- Collect all approved lines
  for line_idx, is_approved in pairs(suggestion.approved_chunks) do
    if is_approved then
      table.insert(approved_lines, {
        idx = line_idx,
        content = suggestion.suggested_lines[line_idx]
      })
    end
  end

  -- Sort by line index to apply in order
  table.sort(approved_lines, function(a, b) return a.idx < b.idx end)

  -- Apply all approved chunks at once
  local insert_lines = {}
  for _, line_data in ipairs(approved_lines) do
    table.insert(insert_lines, line_data.content)
  end

  if #insert_lines > 0 then
    local target_line = suggestion.start_line - 1  -- 0-indexed
    vim.api.nvim_buf_set_lines(suggestion.bufnr, target_line, target_line, false, insert_lines)
    vim.notify(string.format("Applied %d approved lines to file!", #insert_lines), vim.log.levels.INFO)
  else
    vim.notify("No chunks were approved", vim.log.levels.WARN)
  end

  M.clear_current_suggestion()
end

---Navigate to the next chunk
function M.next_chunk()
  local suggestion = M.current_suggestion
  if suggestion.current_chunk < suggestion.total_chunks then
    suggestion.current_chunk = suggestion.current_chunk + 1
    -- Update current_line_idx to first line of new chunk
    suggestion.current_line_idx = suggestion.current_line_idx + M.config.chunk_size
    M.highlight_current_chunk()
    vim.notify(string.format("Moved to chunk %d/%d",
      suggestion.current_chunk, suggestion.total_chunks), vim.log.levels.INFO)
  end
end

---Navigate to the previous chunk
function M.prev_chunk()
  local suggestion = M.current_suggestion
  if suggestion.current_chunk > 1 then
    suggestion.current_chunk = suggestion.current_chunk - 1
    -- Update current_line_idx to first line of new chunk
    suggestion.current_line_idx = suggestion.current_line_idx - M.config.chunk_size
    M.highlight_current_chunk()
    vim.notify(string.format("Moved to chunk %d/%d",
      suggestion.current_chunk, suggestion.total_chunks), vim.log.levels.INFO)
  end
end

function M.reject_suggestion()
  M.clear_current_suggestion()
  vim.notify("Suggestion rejected and cleared.", vim.log.levels.INFO)
end

function M.apply_approved_and_exit()
  local suggestion = M.current_suggestion
  if not suggestion.bufnr then
    vim.notify("No active suggestion to apply", vim.log.levels.WARN)
    return
  end

  -- Check if there are any approved chunks
  local has_approved = false
  for _, is_approved in pairs(suggestion.approved_chunks) do
    if is_approved then
      has_approved = true
      break
    end
  end

  if not has_approved then
    vim.notify("No chunks approved yet", vim.log.levels.WARN)
    return
  end

  -- Apply all approved chunks
  M.apply_all_approved_chunks()
end

function M.clear_current_suggestion()
  M.clear_extmarks()
  M.current_suggestion = {
    bufnr = nil,
    start_line = nil,
    end_line = nil,
    original_lines = {},
    suggested_lines = {},
    current_chunk = 1,
    total_chunks = 0,
    extmarks = {},
    namespace = M.current_suggestion.namespace,
    approved_chunks = {},
    current_line_idx = 1,
  }
end

function M.clear_extmarks()
  local suggestion = M.current_suggestion
  if suggestion.bufnr and vim.api.nvim_buf_is_valid(suggestion.bufnr) and suggestion.namespace then
    vim.api.nvim_buf_clear_namespace(suggestion.bufnr, suggestion.namespace, 0, -1)
  end
  suggestion.extmarks = {}
end

function M.toggle_chunk_mode()
  M.config.chunk_mode = M.config.chunk_mode == "line" and "word" or "line"
  vim.notify(string.format("Chunk mode: %s", M.config.chunk_mode), vim.log.levels.INFO)

  -- Recalculate chunks if suggestion is active
  if M.current_suggestion.bufnr then
    M.current_suggestion.total_chunks = M.calculate_total_chunks(M.current_suggestion.suggested_lines)
    M.current_suggestion.current_chunk = 1
    M.render_suggestion()
    M.highlight_current_chunk()
  end
end

---Toggle between auto and manual trigger modes
function M.toggle_trigger_mode()
  M.config.trigger_mode = M.config.trigger_mode == "manual" and "auto" or "manual"
  vim.notify(string.format("Trigger mode: %s", M.config.trigger_mode), vim.log.levels.INFO)
end

---Increase chunk size (line mode only)
function M.increase_chunk_size()
  if M.config.chunk_mode == "line" then
    M.config.chunk_size = math.min(M.config.chunk_size + 1, 10)  -- Max 10 lines
    vim.notify(string.format("Chunk size: %d lines", M.config.chunk_size), vim.log.levels.INFO)

    -- Recalculate and re-render if suggestion is active
    if M.current_suggestion.bufnr then
      M.recalculate_chunks_preserving_line()
    end
  else
    vim.notify("Chunk size adjustment only available in line mode", vim.log.levels.WARN)
  end
end

---Decrease chunk size (line mode only)
function M.decrease_chunk_size()
  if M.config.chunk_mode == "line" then
    M.config.chunk_size = math.max(M.config.chunk_size - 1, 1)  -- Min 1 line
    vim.notify(string.format("Chunk size: %d lines", M.config.chunk_size), vim.log.levels.INFO)

    -- Recalculate and re-render if suggestion is active
    if M.current_suggestion.bufnr then
      M.recalculate_chunks_preserving_line()
    end
  else
    vim.notify("Chunk size adjustment only available in line mode", vim.log.levels.WARN)
  end
end



function M.recalculate_chunks_preserving_line()
  local suggestion = M.current_suggestion
  local target_line = suggestion.current_line_idx

  -- Don't use standard chunking! Instead, current_line_idx IS the start of the current chunk
  -- We just need to calculate how many chunks there are total from this point

  -- Calculate remaining lines from current position
  local remaining_lines = #suggestion.suggested_lines - target_line + 1
  local remaining_chunks = math.ceil(remaining_lines / M.config.chunk_size)

  -- Calculate total chunks (approved lines + remaining chunks)
  -- For simplicity, let's say we're always on chunk 1 of the remaining chunks
  suggestion.current_chunk = 1
  suggestion.total_chunks = remaining_chunks

  -- Re-render with preserved position
  M.render_suggestion()
  M.highlight_current_chunk()
end

---Integration function for code injection - determines if code should be shown as inline suggestion
---@param bufnr integer Buffer number to inject code into
---@param target_line integer Line number to inject at
---@param code_lines string[] Lines of code to inject
---@return boolean handled Whether the code was handled as an inline suggestion
function M.inject_as_suggestion(bufnr, target_line, code_lines)
  if M.config.trigger_mode == "auto" or vim.g.augment_force_inline_suggestion then
    M.show_suggestion_from_chat_response(bufnr, target_line, code_lines)
    return true  -- Handled as suggestion
  else
    return false  -- Let normal injection proceed
  end
end

return M

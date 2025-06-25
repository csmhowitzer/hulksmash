---@class CodeBlock
---@field start integer Starting line number
---@field finish integer Ending line number
---@field lang string Programming language
---@field content string[] Lines of code

local M = {}
local state = require("m_augment.state")

---Find the Augment response buffer containing code blocks
---@return integer|nil bufnr Buffer number if found
---@return string[] lines Lines from the buffer
function M.find_augment_response_buffer()
  -- Look for buffers that might contain Augment responses
  local buffers = vim.api.nvim_list_bufs()

  for _, bufnr in ipairs(buffers) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      local buf_name = vim.api.nvim_buf_get_name(bufnr)
      local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

      -- Check if this buffer contains code blocks (likely an Augment response)
      if #lines > 1 then
        for _, line in ipairs(lines) do
          if line:match("^%s*```") then
            -- Update state to track this as the response buffer
            state.response_info.bufnr = bufnr
            state.response_info.last_updated = os.time()
            return bufnr, lines
          end
        end
      end
    end
  end

  return nil, {}
end

---Inject code from chat response into target file
---@param chat_bufnr integer|nil Chat buffer number
---@param source_bufnr integer|nil Source buffer number
---@param source_file string|nil Source file path
---@param completion_callback function|nil Callback to run when injection is complete
function M.inject_code(chat_bufnr, source_bufnr, source_file, completion_callback)
  local bufnr, lines

  -- First try to find the Augment response buffer
  bufnr, lines = M.find_augment_response_buffer()

  if not bufnr then
    -- Fallback to current buffer or provided buffer
    bufnr = chat_bufnr or state.response_info.bufnr or vim.api.nvim_get_current_buf()
    lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  end

  local code_blocks = M.find_code_blocks(lines)

  if #code_blocks == 0 then
    vim.notify("No code blocks found in any buffer", vim.log.levels.ERROR)
    if completion_callback then completion_callback() end
    return
  end

  local target_info = M.determine_target_file(lines, source_bufnr, source_file)

  -- Handle selection asynchronously
  M.select_code_block(code_blocks, function(selected_block)
    if not selected_block then
      vim.notify("No code block selected for injection", vim.log.levels.ERROR)
      if completion_callback then completion_callback() end
      return
    end

    local target_bufnr = M.open_target_file(target_info.bufnr, target_info.file)
    M.insert_and_format_code(selected_block.content, target_bufnr)
    vim.notify("Code injected successfully", vim.log.levels.INFO)

    -- Call completion callback after injection is done
    if completion_callback then completion_callback() end
  end)
end

---Find and parse code blocks from buffer lines
---@param lines string[] Lines to search for code blocks
---@return CodeBlock[] code_blocks List of found code blocks
function M.find_code_blocks(lines)
  local code_blocks = {}
  local in_code_block = false
  local start_line = nil
  local language = nil
  local current_block = {}

  for i, line in ipairs(lines) do
    -- Match opening: ````lua path=file.lua mode=EDIT or ```lua or ````lua
    local block_start = line:match("^%s*````?%s*(%w*)")
    if block_start and not in_code_block then
      in_code_block = true
      start_line = i
      language = block_start ~= "" and block_start or "text"
      current_block = {}
    -- Match closing: ```` or ```
    elseif line:match("^%s*````?%s*$") and in_code_block then
      in_code_block = false
      -- Only add blocks that have proper closing markers
      if #current_block > 0 then
        table.insert(code_blocks, {
          start = start_line,
          finish = i,
          lang = language,
          content = current_block,
        })
        state.add_code_block(language, current_block)
      end
    elseif in_code_block then
      table.insert(current_block, line)
    end
  end

  -- Don't add unclosed code blocks - they're likely incomplete or malformed
  -- This prevents injecting explanatory text that comes after code blocks

  return code_blocks
end

-- Determine target file for code injections
function M.determine_target_file(lines, source_bufnr, source_file)
  local target_bufnr = source_bufnr
  local target_file = source_file

  if not target_bufnr or not vim.api.nvim_buf_is_valid(target_bufnr) then
    for i, line in ipairs(lines) do
      local path = line:match("File Path: (.+)")
      if path then
        target_file = path
        break
      end
    end
    if not target_file or target_file == "" then
      for _, buf in ipairs(state.recent_buffers.items) do
        if buf.name ~= "augment-chat" and buf.name ~= "augment-response" then
          target_bufnr = buf.bufnr
          target_file = buf.path
          break
        end
      end
    end
    if not target_bufnr or not vim.api.nvim_buf_is_valid(target_bufnr) then
      vim.notify("Could not determine target file, using previous buffer", vim.log.levels.WARN)
      vim.cmd("wincmd p")
      target_bufnr = vim.api.nvim_get_current_buf()
      target_file = vim.api.nvim_buf_get_name(target_bufnr)
    end
  end

  return { bufnr = target_bufnr, file = target_file }
end

-- Select code block to inject (now with callback support)
function M.select_code_block(code_blocks, callback)
  if #code_blocks == 0 then
    callback(nil)
    return
  end

  if #code_blocks == 1 then
    callback(code_blocks[1])
    return
  end

  -- Multiple blocks - show selection UI with better preview
  local options = {}
  for i, block in ipairs(code_blocks) do
    -- Create a better preview - show first few lines
    local preview_lines = {}
    for j = 1, math.min(3, #block.content) do
      table.insert(preview_lines, block.content[j])
    end
    local preview = table.concat(preview_lines, " | ")
    if #block.content > 3 then
      preview = preview .. " | ..."
    end
    -- Limit total length
    if #preview > 80 then
      preview = preview:sub(1, 77) .. "..."
    end
    table.insert(options, string.format("Block %d (%s): %s", i, block.lang, preview))
  end

  vim.ui.select(options, {
    prompt = "Select code block to inject:",
    format_item = function(item)
      return item
    end,
  }, function(choice, idx)
    if idx then
      callback(code_blocks[idx])
    else
      callback(nil)  -- User cancelled selection
    end
  end)
end

-- open target file
function M.open_target_file(target_bufnr, target_file)
  if target_bufnr and vim.api.nvim_buf_is_valid(target_bufnr) then
    local win_id = vim.fn.bufwinid(target_bufnr)
    if win_id ~= -1 then
      vim.api.nvim_set_current_win(win_id)
    else
      vim.cmd("wincmd p")
      vim.cmd("buffer " .. target_bufnr)
    end
  elseif target_file and target_file ~= "" then
    vim.cmd("wincmd p")
    vim.cmd("edit " .. target_file)
    target_bufnr = vim.api.nvim_get_current_buf()
  else
    vim.cmd("wincmd p")
    target_bufnr = vim.api.nvim_get_current_buf()
  end
  return target_bufnr
end

-- Insert and format code
function M.insert_and_format_code(code_lines, target_bufnr)
  -- Use provided target buffer or current buffer
  local bufnr = target_bufnr or vim.api.nvim_get_current_buf()

  -- Get cursor position from the target buffer's window
  local target_win = vim.fn.bufwinid(bufnr)
  local row
  if target_win ~= -1 then
    row = vim.api.nvim_win_get_cursor(target_win)[1]
  else
    row = 1 -- Default to first line if window not found
  end

  -- Try to use inline suggestions first
  local inline = require("m_augment.inline")
  if inline.inject_as_suggestion(bufnr, row, code_lines) then
    return -- Handled by inline suggestions
  end

  -- Fallback to direct injection
  vim.api.nvim_buf_set_lines(bufnr, row - 1, row - 1, false, code_lines)

  -- Format only if the buffer is modifiable
  if vim.api.nvim_buf_get_option(bufnr, "modifiable") then
    require("conform").format({ formatters = { "injected" } })
  end
end

-- inject selected code
function M.inject_selected_code(chat_bufnr, source_bufnr, source_file)
  local start_line, start_col = unpack(vim.api.nvim_buf_get_mark(0, "<"))
  local end_line, end_col = unpack(vim.api.nvim_buf_get_mark(0, ">"))

  start_line = start_line - 1
  end_line = end_line - 1
  end_col = end_col + 1

  local lines = vim.api.nvim_buf_get_text(0, start_line, start_col, end_line, end_col, {})
  local target_info = M.determine_target_file(lines, source_bufnr, source_file)
  M.open_target_file(target_info.bufnr, target_info.file)
  M.insert_and_format_code(lines)

  vim.notify("Selected code injected successfully", vim.log.levels.INFO)
end

return M

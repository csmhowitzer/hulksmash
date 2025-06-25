local M = {}
local state = require("m_augment.state")

-- may not keep this or is subject to change
function M.inject_code(chat_bufnr, source_bufnr, source_file)
  local bufnr = chat_bufnr or state.response_info.bufnr or vim.api.nvim_get_current_buf()

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local code_blocks = M.find_code_blocks(lines)
  local target_info = M.determine_target_file(lines, source_bufnr, source_file)
  local selected_block = M.select_code_block(code_blocks)

  if not selected_block then
    vim.notify("No code block selected for injection", vim.log.levels.ERROR)
    return
  end

  M.open_target_file(target_info.bufnr, target_info.file)
  M.insert_and_format_code(selected_block.content)
  vim.notify("Code injected successfully", vim.log.levels.INFO)
end

function M.find_code_blocks(lines)
  local code_blocks = {}
  local in_code_block = false
  local start_line = nil
  local language = nil
  local current_block = {}

  for i, line in ipairs(lines) do
    local block_start = line:match("^%s*```%s*(%w*)")
    if block_start and not in_code_block then
      in_code_block = true
      start_line = i
      language = block_start ~= "" and block_start or "text"
      current_block = {}
    elseif line:match("^%s*```%s*$") and in_code_block then
      in_code_block = false
      table.insert(code_blocks, {
        start = start_line,
        finish = i,
        lang = language,
        content = current_block,
      })
      state.add_code_block(language, current_block)
    elseif in_code_block then
      table.insert(current_block, line)
    end
  end

  if in_code_block and #current_block > 0 then
    table.insert(code_blocks, {
      start = start_line,
      finish = #lines,
      lang = language,
      content = current_block,
    })
    state.add_code_block(language, current_block)
  end

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

-- Select jcode block to inject
function M.select_code_block(code_blocks)
  local selected_block

  if #code_blocks > 1 then
    local options = {}
    for i, block in ipairs(code_blocks) do
      local preview = table.concat(block.content, "\n"):sub(1, 50)
      if #preview == 50 then
        preview = preview .. "..."
      end
      table.insert(options, string.format("%d: %s (%s)", i, preview, block.lang))
    end
    vim.ui.select(options, {
      prompt = "Select code block to inject:",
      format_item = function(item)
        return item
      end,
    }, function(choice, idx)
      if idx then
        selected_block = code_blocks[idx]
      end
    end)
  else
    selected_block = code_blocks[1]
  end

  return selected_block
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
function M.insert_and_format_code(code_lines)
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local row = cursor_pos[1] - 1
  vim.api.nvim_buf_set_lines(0, row, row, false, code_lines)
  require("conform").format({ formatters = { "injected" } })
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

local M = {}

M.response_info = {
  bufnr = nil,
  winid = nil,
  filetype = nil,
  last_updated = nil,
}

M.recent_buffers = {
  max_size = 4,
  items = {},
}

M.recent_code_blocks = {
  max_size = 10,
  items = {},
}

M.config = {
  workspace_path = "~/.augment/workspaces.json",
  max_recent_buffers = 4,
  max_code_blocks = 10,
}

M.buffer_content = {}
M.message_history = {}
M.history_index = 0

M.source_bufnr = nil
M.source_file = nil

-- Initialize state
function M.init(opts)
  opts = opts or {}
  M.config.workspace_path = opts.workspace_path or M.config.workspace_path
  M.config.max_recent_buffers = opts.max_recent_buffers or M.config.max_recent_buffers
  M.config.max_code_blocks = opts.max_code_blocks or M.config.max_code_blocks

  M.recent_buffers.max_size = M.config.max_recent_buffers
  M.recent_code_blocks.max_size = M.config.max_code_blocks

  if opts.max_recent_buffers then
    M.recent_buffers.max_size = opts.max_recent_buffers
  end
  if opts.max_code_blocks then
    M.recent_code_blocks.max_size = opts.max_code_blocks
  end
end

-- Get source buffer
function M.get_source_buffer()
  return M.source_bufnr
end

-- Get source file
function M.get_source_file()
  return M.source_file
end

-- Set source buffer and size
function M.set_source(bufnr, file)
  M.source_bufnr = bufnr
  M.source_file = file
end

-- Update recent buffers list
function M.update_recent_buffers()
  local current_bufnr = vim.api.nvim_get_current_buf()
  local bufname = vim.api.nvim_buf_get_name(current_bufnr)

  -- skip special buffers
  if bufname == "" or bufname:match("^%[.*%]$") then
    return
  end

  for i, buf in ipairs(M.recent_buffers.items) do
    if buf.bufnr == current_bufnr then
      table.remove(M.recent_buffers.items, i)
      break
    end
  end

  table.insert(M.recent_buffers.items, 1, {
    bufnr = current_bufnr,
    name = vim.fn.fnamemodify(bufname, ":t"),
    path = bufname,
    filetype = vim.bo[current_bufnr].filetype,
  })

  if #M.recent_buffers.items > M.recent_buffers.max_size then
    table.remove(M.recent_buffers.items)
  end
end

function M.debug_recent_buffers()
  if #M.recent_buffers.items == 0 then
    vim.notify("No recent buffers tracked", vim.log.levels.INFO)
    return
  end

  local buffers_info =
    "\n┌─────┬────────┬──────────────┬───────────┬─────────────────────────────────────┐\n"
  buffers_info = buffers_info
    .. "│ Idx │ Buffer │ Name         │ Filetype  │ Path                                │\n"
  buffers_info = buffers_info
    .. "├─────┼────────┼──────────────┼───────────┼─────────────────────────────────────┤\n"

  for i, buf in ipairs(M.recent_buffers.items) do
    local idx = string.format("%-3d", i)
    local bufnr = string.format("%-6d", buf.bufnr)
    local name = string.sub(buf.name or "", 1, 12)
    name = string.format("%-12s", name)
    local ft = string.sub(buf.filetype or "", 1, 9)
    ft = string.format("%-9s", ft)
    local path = string.sub(buf.path or "", 1, 35)
    path = string.format("%-35s", path)

    buffers_info = buffers_info .. string.format("│ %s │ %s │ %s │ %s │ %s │\n", idx, bufnr, name, ft, path)
  end

  buffers_info = buffers_info
    .. "└─────┴────────┴──────────────┴───────────┴─────────────────────────────────────┘\n"

  vim.notify(buffers_info, vim.log.levels.INFO)
end

-- Add code blocks to recent list
function M.add_code_block(language, content)
  table.insert(M.recent_code_blocks.items, 1, {
    language = language,
    content = content,
    timestamp = os.time(),
  })

  if #M.recent_code_blocks.items > M.recent_code_blocks.max_size then
    table.remove(M.recent_code_blocks.items, M.recent_code_blocks.max_size)
  end
end

-- Update response info
function M.update_response_info(bufnr, winid)
  M.response_info.bufnr = bufnr
  M.response_info.winid = winid
  M.response_info.filetype = vim.bo[bufnr].filetype
  M.response_info.last_updated = os.time()
end

-- Save to message history
function M.save_to_history(message)
  table.insert(M.message_history, 1, message)
  M.history_index = #M.message_history
end

-- Navigate message history
function M.navigate_history(direction)
  if #M.message_history == 0 then
    print("nothing in the history books!")
    return nil
  end

  if direction == "fwd" then
    M.history_index = math.min(M.history_index + 1, #M.message_history)
    print(M.history_index)
  else
    M.history_index = math.max(M.history_index - 1, 1)
    print(M.history_index)
  end

  return M.message_history[M.history_index]
end

return M

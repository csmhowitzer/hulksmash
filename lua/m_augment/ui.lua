local M = {}
local state = require("m_augment.state")

function M.setup(opts)
  M.define_highlights()
end

function M.define_highlights()
  vim.api.nvim_set_hl(0, "AugmentChatBorder", { fg = "#cba6f7", bold = true })
  vim.api.nvim_set_hl(0, "AugmentChatTitle", { fg = "#a6d189", bold = true })
  vim.api.nvim_set_hl(0, "AugmentChatFooter", { fg = "#74c7ec", italic = true })
end

function M.open_chat_buffer()
  local source_bufnr = vim.api.nvim_get_current_buf()
  local source_file = vim.api.nvim_buf_get_name(source_bufnr)
  state.set_source(source_bufnr, source_file)

  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value("bufhidden", "hide", { buf = bufnr })
  vim.api.nvim_set_option_value("filetype", "markdown", { buf = bufnr })

  local height = math.floor(vim.o.lines / 4)
  local width = math.floor(vim.o.columns / 3)
  local max_width = 100
  width = width < max_width and width or max_width

  local row = 2
  local col = math.floor((vim.o.columns - width) / 2)

  local win_id = vim.api.nvim_open_win(bufnr, true, {
    relative = "editor",
    row = row,
    col = col,
    width = width,
    height = height,
    style = "minimal",
    border = "rounded",
    title = " 󰚩 Augment Chat 󰚩 ",
    title_pos = "center",
    footer = " q close; <CR> send; <C-n>, <C-p>, nav history ",
    footer_pos = "center",
  })

  state.update_response_info(bufnr, win_id)

  vim.api.nvim_set_option_value("wrap", true, { win = win_id })
  vim.api.nvim_set_option_value("linebreak", true, { win = win_id })
  vim.api.nvim_set_option_value(
    "winhighlight",
    "FloatBorder:AugmentChatBorder,FloatTitle:AugmentChatTitle,FloatFooter:AugmentChatFooter",
    { win = win_id }
  )
  M.define_highlights()

  if state.buffer_content and #state.buffer_content > 0 then
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, state.buffer_content)
  end

  M.setup_chat_buffer_keymaps(bufnr, source_bufnr, source_file)

  vim.cmd("startinsert")
end

function M.setup_chat_buffer_keymaps(bufnr, source_bufnr, source_file)
  local code = require("m_augment.code")

  local send_to_augment = function()
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local content = table.concat(lines, " ")

    state.buffer_content = {}
    state.save_to_history(table.concat(lines, "\n"))

    vim.cmd("Augment chat " .. vim.fn.escape(content, '"\\'))
    vim.api.nvim_win_close(state.response_info.winid, true)
  end

  local close_window = function()
    state.buffer_content = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    vim.cmd("stopinsert")
    vim.api.nvim_win_close(state.response_info.winid, true)
  end

  local navigate_history = function(direction)
    local message = state.navigate_history(direction)
    if message then
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(message, "\n"))
    end
  end

  vim.keymap.set({ "n", "i" }, "<C-y>", function()
    send_to_augment()
  end, { buffer = bufnr, desc = "Send to Augment" })
  vim.keymap.set("n", "<CR>", function()
    send_to_augment()
  end, { buffer = bufnr, desc = "Send to Augment" })
  vim.keymap.set("n", "q", function()
    close_window()
  end, { buffer = bufnr, desc = "Close Augment Chat" })
  vim.keymap.set("n", "<C-n>", function()
    navigate_history("fwd")
  end, { buffer = bufnr, desc = "Navigate history up" })
  vim.keymap.set("n", "<C-p>", function()
    navigate_history("back")
  end, { buffer = bufnr, desc = "Navigate history down" })
  -- -- Code injection keymap
  -- vim.keymap.set("n", "<leader>ai", function()
  --   code.inject_code(bufnr, source_bufnr, source_file)
  -- end, { buffer = bufnr, desc = "[A]ugment [I]nject code to original file" })
  --
  -- -- Visual selection code injection
  -- vim.keymap.set("v", "<leader>ai", function()
  --   code.inject_selected_code(bufnr, source_bufnr, source_file)
  -- end, { buffer = bufnr, desc = "[A]ugment [I]nject selected code to original file" })
end

function M.send_selection_to_chat()
  local source_bufnr = vim.api.nvim_get_current_buf()
  local source_file = vim.api.nvim_buf_get_name(source_bufnr)
  state.set_source(source_bufnr, source_file)

  local mode = vim.fn.mode()
  if mode ~= "v" and mode ~= "V" and mode ~= "" then
    vim.cmd("normal! gv")
  end

  local old_reg = vim.fn.getreg('"')
  local old_regtype = vim.fn.getregtype('"')

  vim.cmd("normal! y")

  local selected_text = vim.fn.getreg('"')

  vim.fn.setreg('"', old_reg, old_regtype)

  local absolute_path = vim.fn.expand("%:p")
  local filetype = vim.bo.filetype

  local message = string.format("```%s\n%s\n```\n\nFile Path: %s\n\n", filetype, selected_text, absolute_path)

  state.buffer_content = vim.split(message, "\n")
  M.open_chat_buffer()
end

return M

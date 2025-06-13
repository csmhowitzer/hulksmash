-- Helper class with useful utility functions
---@module 'utils'
local M = {}

-- Get the current buffer's file name without extension
---@return string
function M.get_current_filename()
  local bufnr = vim.api.nvim_get_current_buf()
  return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":t:r")
end

-- Gets the parent directory of the current buffer's path
---@return string
function M.get_parent_dir()
  local path = M.get_full_path()
  local dir = vim.fn.fnamemodify(path, ":h")
  local pathSplit = vim.split(dir, "/")
  return pathSplit[#pathSplit]
end

-- Get the current buffer's full path
---@return string
function M.get_full_path()
  local bufnr = vim.api.nvim_get_current_buf()
  return vim.api.nvim_buf_get_name(bufnr)
end

-- Check if a file exists
---@param path string: path to the file
---@return boolean
function M.file_exists(path)
  local f = io.open(path, "r")
  if f then
    io.close(f)
    return true
  end
  return false
end

-- Find project root based on pattern
---@param pattern string: pattern to match (e.g., "%.git$", "%.sln$")
---@return string?
function M.find_root(pattern)
  local path = M.get_full_path()
  local dir = vim.fn.fnamemodify(path, ":h")
  return vim.fs.root(dir, function(name)
    return name:match(pattern) ~= nil
  end)
end

-- Check if current file is of specific type
---@param filetype string: filetype to check
---@return boolean
function M.is_filetype(filetype)
  return vim.bo.filetype == filetype
end

---Get path returns the current buffer's absolute folder path
---@return string
function M.get_path()
  local bufnr = vim.api.nvim_get_current_buf()
  return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":h")
end

---Find the .csproj root folder for the given file the buffer resides in
---@param path string? : path to find proj root for
---@return string?
function M.find_proj_root(path)
  path = path or M.get_path()
  assert(path ~= nil, "invalid path provided")
  vim.api.nvim_set_current_dir(path)
  return vim.fs.root(path, function(name)
    return name:match("%.csproj$") ~= nil
  end)
end

---Find the .sln root folder for the given C# buffer
---@param path string? : path to find sln root for
---@return string?
function M.find_sln_root(path)
  path = path or M.get_path()
  assert(path ~= nil, "invalid path provided")
  return vim.fs.root(path, function(name)
    return name:match("%.sln$") ~= nil
  end)
end

---Sets the current working directory to the current buffer
---@param path string? : path to set cwd to
function M.set_cwd(path)
  path = path or M.get_path()
  assert(path ~= nil, "invalid path provided")
  vim.api.nvim_set_current_dir(path)
end

---Reads the content of a file.
---@param path string : path to the file
---@return string?
function M.read_file_content(path)
  local f = io.open(path, "r")
  if not f then
    return
  end
  local content = f:read("*all")
  f:close()
  return content
end

---Create a file on the home path if it doens't exist
---@param path string : path to the file
---@return boolean
---@return string?
---@Usage create_home_dir_if_not_exists('.config/nvim/init.lua')
function M.create_home_dir_if_not_exists(path)
  if not M.file_exists(path) then
    assert(path ~= nil, "invalid path provided")
    if path == nil then
      return false, "no path provided"
    end

    local home = vim.fn.expand("~")
    if path:sub(1, #home) == home then
      path = path:sub(#home + 2)
    end

    local full_path = vim.fn.expand("~") .. "/" .. path
    local home_path = vim.fn.fnamemodify(full_path, ":h")

    vim.fn.mkdir(home_path, "p")

    return true
  end
  return false, "file already exists"
end

--- Execute a command and display the output
--- @param cmd table The command to execute
function M.execute_cmd(cmd)
  local command_str = table.concat(cmd, " ")
  vim.notify("Executing: " .. command_str, vim.log.levels.INFO)

  vim.fn.jobstart(cmd, {
    on_exit = function(_, exit_code)
      if exit_code == 0 then
        vim.notify("Command completed successfully", vim.log.levels.INFO)
      else
        vim.notify("Command failed with exit code: " .. exit_code, vim.log.levels.ERROR)
      end
    end,
    on_stdout = function(_, data)
      if data and #data > 0 then
        local output = table.concat(data, "\n")
        if output ~= "" then
          print(output)
        end
      end
    end,
    on_stderr = function(_, data)
      if data and #data > 0 then
        local error_msg = table.concat(data, "\n")
        if error_msg ~= "" then
          vim.notify(error_msg, vim.log.levels.ERROR)
        end
      end
    end,
    stdout_buffered = true,
    stderr_buffered = true,
  })
end

-- Create a floating confirmation dialog
---@param message string: message to display in the dialog
---@param callback function: function to call with the result (boolean)
---@diagnostic disable-next-line: duplicate-set-field
function M.confirm_dialog_basic(message, callback)
  M.confirm_dialog(message, " Confirm? ", "", callback)
end
---@param message string: message to display in the dialog
---@param title string: title to display in the dialog
---@param callback function: function to call with the result (boolean)
---@diagnostic disable-next-line: duplicate-set-field
function M.confirm_dialog_title(message, title, callback)
  M.confirm_dialog(message, title, "", callback)
end
---@param message string: message to display in the dialog
---@param footer string: footer to display in the dialog
---@param callback function: function to call with the result (boolean)
---@diagnostic disable-next-line: duplicate-set-field
function M.confirm_dialog_footer(message, footer, callback)
  M.confirm_dialog(message, " Confirm? ", footer, callback)
end
-- Create a floating confirmation dialog
---@param message string: message to display in the dialog
---@param title string: title to display in the dialog
---@param footer string: footer to display in the dialog
---@param callback function: function to call with the result (boolean)
---@diagnostic disable-next-line: duplicate-set-field
function M.confirm_dialog(message, title, footer, callback)
  local width = 20 + #message
  local height = 3
  local bufnr = vim.api.nvim_create_buf(false, true)

  -- Calculate centered position
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  -- Set buffer content
  local content = {
    message,
    "",
    "[Y]es   [N]o",
  }
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, content)

  -- Set buffer options
  vim.api.nvim_set_option_value("bufhidden", "hide", { buf = bufnr })
  vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = bufnr })

  -- Create window
  local winnr = vim.api.nvim_open_win(bufnr, true, {
    relative = "editor",
    row = row,
    col = col,
    width = width,
    height = height,
    style = "minimal",
    border = "rounded",
    title = title,
    title_pos = "center",
    footer = footer,
    footer_pos = "center",
  })

  vim.api.nvim_set_option_value(
    "winhighlight",
    "FloatBorder:UtilsBorder,FloatTitle:UtilsTitle,FloatFooter:UtilsFooter",
    { win = winnr }
  )

  vim.api.nvim_set_hl(0, "UtilsBorder", { fg = "#f9e2af", bold = true })
  vim.api.nvim_set_hl(0, "UtilsTitle", { fg = "#89dceb", bold = true })
  vim.api.nvim_set_hl(0, "UtilsFooter", { fg = "#a6d189", italic = true })

  -- Handle keypress
  local close_window = function()
    vim.api.nvim_win_close(winnr, true)
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end

  vim.keymap.set("n", "y", function()
    close_window()
    callback(true)
  end, { buffer = bufnr, nowait = true })

  vim.keymap.set("n", "Y", function()
    close_window()
    callback(true)
  end, { buffer = bufnr, nowait = true })

  vim.keymap.set("n", "n", function()
    close_window()
    callback(false)
  end, { buffer = bufnr, nowait = true })

  vim.keymap.set("n", "N", function()
    close_window()
    callback(false)
  end, { buffer = bufnr, nowait = true })

  vim.keymap.set("n", "<Esc>", function()
    close_window()
    callback(false)
  end, { buffer = bufnr, nowait = true })
end

return M

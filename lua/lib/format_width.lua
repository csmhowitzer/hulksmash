---@class FormatWidth
---@field setup function Setup format width rules for different file types
local M = {}

---@class FormatWidthConfig
---@field width number Column width for visual indicator
---@field textwidth? number Text width for automatic wrapping
---@field conceallevel? number Concealment level for the buffer
---@field tabstop? number Tab stop width
---@field softtabstop? number Soft tab stop width
---@field shiftwidth? number Shift width for indentation
---@field toggleable? boolean Whether width enforcement can be toggled (default: false)
---@field default_enabled? boolean Whether enforcement starts enabled (default: true)
---@field format_on_save? boolean Whether to auto-format on save (default: false)

---Default configuration for different file types
---@type table<string, FormatWidthConfig>
local default_configs = {
  markdown = {
    width = 80,
    textwidth = 80,
    conceallevel = 2,
    toggleable = false,
    default_enabled = true,
    format_on_save = false,
  },
  cs = {
    width = 120,
    tabstop = 4,
    softtabstop = 4,
    shiftwidth = 4,
    toggleable = false,
    default_enabled = true,
    format_on_save = false,
  },
  lua = {
    width = 120,
    tabstop = 2,
    softtabstop = 2,
    shiftwidth = 2,
    toggleable = false,
    default_enabled = true,
    format_on_save = false,
  },
}

---Current active configuration (merged defaults + user config)
---@type table<string, FormatWidthConfig>
local format_configs = {}

---Runtime toggle state per filetype
---@type table<string, boolean>
local toggle_state = {}

---Runtime toggle state per buffer
---@type table<number, boolean>
local buffer_toggle_state = {}

---Validate a configuration table
---@param config table Configuration to validate
---@param filetype string Filetype name for error messages
---@return boolean success, string? error_message
local function validate_config(config, filetype)
  if type(config) ~= "table" then
    return false, "Configuration for '" .. filetype .. "' must be a table"
  end

  if not config.width or type(config.width) ~= "number" or config.width <= 0 then
    return false, "Configuration for '" .. filetype .. "' must have a positive 'width' number"
  end

  -- Validate optional numeric fields
  local numeric_fields = { "textwidth", "conceallevel", "tabstop", "softtabstop", "shiftwidth" }
  for _, field in ipairs(numeric_fields) do
    if config[field] and (type(config[field]) ~= "number" or config[field] < 0) then
      return false, "Configuration field '" .. field .. "' for '" .. filetype .. "' must be a non-negative number"
    end
  end

  -- Validate optional boolean fields
  local boolean_fields = { "toggleable", "default_enabled", "format_on_save" }
  for _, field in ipairs(boolean_fields) do
    if config[field] ~= nil and type(config[field]) ~= "boolean" then
      return false, "Configuration field '" .. field .. "' for '" .. filetype .. "' must be a boolean"
    end
  end

  return true
end

---Merge user configuration with defaults
---@param user_config table|nil User configuration
---@return table merged_config
local function merge_configs(user_config)
  local merged = {}

  -- Start with defaults
  for filetype, default_config in pairs(default_configs) do
    merged[filetype] = vim.tbl_deep_extend("force", {}, default_config)
  end

  -- Merge user config if provided
  if user_config then
    for filetype, config in pairs(user_config) do
      local success, error_msg = validate_config(config, filetype)
      if not success then
        vim.notify("FormatWidth: " .. error_msg, vim.log.levels.ERROR)
      else
        if merged[filetype] then
          -- Merge with existing filetype
          merged[filetype] = vim.tbl_deep_extend("force", merged[filetype], config)
        else
          -- New filetype - merge with minimal defaults
          merged[filetype] = vim.tbl_deep_extend("force", {
            toggleable = false,
            default_enabled = true,
            format_on_save = false,
          }, config)
        end
      end
    end
  end

  return merged
end

---Apply format settings to a buffer
---@param bufnr number Buffer number
---@param config FormatWidthConfig Configuration settings
local function apply_format_settings(bufnr, config)
  -- Check if width enforcement is enabled for this buffer
  if not M.is_buffer_enabled(bufnr) then
    return
  end

  -- Set color column for visual width indicator
  vim.api.nvim_buf_set_option(bufnr, "colorcolumn", tostring(config.width))

  -- Set text width if specified (for automatic wrapping)
  if config.textwidth then
    vim.api.nvim_buf_set_option(bufnr, "textwidth", config.textwidth)
  end

  -- Set concealment level if specified
  if config.conceallevel then
    vim.opt.conceallevel = config.conceallevel
  end

  -- Set tab settings if specified
  if config.tabstop then
    vim.opt.tabstop = config.tabstop
  end
  if config.softtabstop then
    vim.opt.softtabstop = config.softtabstop
  end
  if config.shiftwidth then
    vim.opt.shiftwidth = config.shiftwidth
  end
end

---Setup format width autocmds for all configured file types
---@param user_config? table<string, FormatWidthConfig> User configuration to override defaults
function M.setup(user_config)
  -- Merge user config with defaults
  format_configs = merge_configs(user_config)

  -- Initialize toggle states
  for filetype, config in pairs(format_configs) do
    toggle_state[filetype] = config.default_enabled
  end
  -- Markdown format settings
  vim.api.nvim_create_autocmd({ "BufEnter" }, {
    group = vim.api.nvim_create_augroup("FormatWidth_Markdown", {
      clear = true,
    }),
    pattern = "*.md",
    callback = function()
      local bufnr = vim.api.nvim_get_current_buf()
      apply_format_settings(bufnr, format_configs.markdown)
    end,
    desc = "Set markdown format width and settings"
  })

  -- C# format settings
  vim.api.nvim_create_autocmd({ "BufEnter" }, {
    group = vim.api.nvim_create_augroup("FormatWidth_CSharp", {
      clear = true,
    }),
    pattern = "*.cs",
    callback = function()
      local bufnr = vim.api.nvim_get_current_buf()
      apply_format_settings(bufnr, format_configs.cs)
    end,
    desc = "Set C# format width and tab settings"
  })

  -- Lua format settings
  vim.api.nvim_create_autocmd({ "BufEnter" }, {
    group = vim.api.nvim_create_augroup("FormatWidth_Lua", {
      clear = true,
    }),
    pattern = "*.lua",
    callback = function()
      local bufnr = vim.api.nvim_get_current_buf()
      apply_format_settings(bufnr, format_configs.lua)
    end,
    desc = "Set Lua format width and tab settings"
  })

  -- Setup format-on-save autocmd
  vim.api.nvim_create_autocmd("BufWritePre", {
    group = vim.api.nvim_create_augroup("FormatWidth_AutoFormat", {
      clear = true,
    }),
    callback = function()
      local bufnr = vim.api.nvim_get_current_buf()
      local filetype = vim.api.nvim_buf_get_option(bufnr, "filetype")
      local config = format_configs[filetype]

      -- Only auto-format if:
      -- 1. We have a config for this filetype
      -- 2. format_on_save is enabled for this filetype
      -- 3. Width enforcement is currently enabled for this buffer
      if config and config.format_on_save and M.is_buffer_enabled(bufnr) then
        M.format_buffer(bufnr, config.width)
      end
    end,
    desc = "Auto-format buffer on save if format_on_save is enabled"
  })

  -- Create user commands
  vim.api.nvim_create_user_command("FormatWidthToggle", function(opts)
    local args = opts.fargs
    if #args == 0 then
      -- Toggle current buffer
      M.toggle_buffer()
    elseif #args == 1 then
      -- Toggle specific filetype
      M.toggle_filetype(args[1])
    else
      vim.notify("FormatWidth: Usage: :FormatWidthToggle [filetype]", vim.log.levels.ERROR)
    end
  end, {
    nargs = "?",
    complete = function()
      return M.get_filetypes()
    end,
    desc = "Toggle format width enforcement for current buffer or filetype"
  })

  vim.api.nvim_create_user_command("FormatWidth", function(opts)
    local args = opts.fargs
    local bufnr = vim.api.nvim_get_current_buf()

    if #args == 0 then
      -- Use current filetype default width
      local filetype = vim.api.nvim_buf_get_option(bufnr, "filetype")
      local config = format_configs[filetype]
      if config then
        M.format_buffer(bufnr, config.width)
      else
        vim.notify("FormatWidth: No configuration found for filetype '" .. filetype .. "'", vim.log.levels.ERROR)
      end
    elseif #args == 1 then
      -- Use custom width
      local width = tonumber(args[1])
      if width then
        M.format_buffer(bufnr, width)
      else
        vim.notify("FormatWidth: Width must be a number", vim.log.levels.ERROR)
      end
    else
      vim.notify("FormatWidth: Usage: :FormatWidth [width]", vim.log.levels.ERROR)
    end
  end, {
    nargs = "?",
    range = true,
    desc = "Format current buffer or selection to respect width limit"
  })

  -- Create help command
  vim.api.nvim_create_user_command("FormatWidthHelp", function()
    print("=== FormatWidth Help ===")
    print("")
    print("# Commands:")
    print("  :FormatWidthToggle          - Toggle width enforcement for current buffer")
    print("  :FormatWidthToggle <type>   - Toggle width enforcement for filetype")
    print("  :FormatWidth                - Format buffer with filetype default width")
    print("  :FormatWidth <number>       - Format buffer with custom width")
    print("  :FormatWidthReset           - Reset current buffer to filetype defaults")
    print("  :FormatWidthHelp            - Show this help")
    print("")
    print("# Configured Filetypes:")
    for _, filetype in ipairs(M.get_filetypes()) do
      local config = format_configs[filetype]
      local toggleable = config.toggleable and "toggleable" or "always on"
      local format_on_save = config.format_on_save and "auto-format" or "manual only"
      print("  " .. filetype .. ": " .. config.width .. " chars (" .. toggleable .. ", " .. format_on_save .. ")")
    end
    print("")
    print("# Current Status:")
    local bufnr = vim.api.nvim_get_current_buf()
    local filetype = vim.api.nvim_buf_get_option(bufnr, "filetype")
    local enabled = M.is_buffer_enabled(bufnr)
    print("  Current buffer: " .. filetype .. " (" .. (enabled and "enabled" or "disabled") .. ")")
  end, {
    desc = "Show FormatWidth help and current status"
  })

  vim.api.nvim_create_user_command("FormatWidthReset", function()
    M.reset()
  end, {
    desc = "Reset current buffer format width to filetype defaults"
  })
end

---Get current format configuration for a file type
---@param filetype string File type (e.g., "markdown", "cs", "lua")
---@return FormatWidthConfig|nil Configuration table or nil if not found
function M.get_config(filetype)
  return format_configs[filetype]
end

---Check if width enforcement is currently enabled for a filetype
---@param filetype string File type to check
---@return boolean enabled
function M.is_enabled(filetype)
  return toggle_state[filetype] ~= false
end

---Check if width enforcement is enabled for a specific buffer
---@param bufnr number Buffer number
---@return boolean enabled
function M.is_buffer_enabled(bufnr)
  -- Buffer-specific override takes precedence
  if buffer_toggle_state[bufnr] ~= nil then
    return buffer_toggle_state[bufnr]
  end

  -- Fall back to filetype setting
  local filetype = vim.api.nvim_buf_get_option(bufnr, "filetype")
  return M.is_enabled(filetype)
end

---Get all configured filetypes
---@return string[] List of configured filetypes
function M.get_filetypes()
  local filetypes = {}
  for filetype, _ in pairs(format_configs) do
    table.insert(filetypes, filetype)
  end
  table.sort(filetypes)
  return filetypes
end

---Update format configuration for a file type
---@param filetype string File type to update
---@param config FormatWidthConfig New configuration settings
function M.set_config(filetype, config)
  local success, error_msg = validate_config(config, filetype)
  if not success then
    vim.notify("FormatWidth: " .. error_msg, vim.log.levels.ERROR)
    return false
  end

  format_configs[filetype] = config

  -- Initialize toggle state if not set
  if toggle_state[filetype] == nil then
    toggle_state[filetype] = config.default_enabled ~= false
  end

  return true
end

---Get current runtime state for debugging
---@return table Current state information
function M.get_state()
  return {
    configs = format_configs,
    toggle_state = toggle_state,
    buffer_toggle_state = buffer_toggle_state,
  }
end

---Add a new file type configuration
---@param filetype string File type name
---@param pattern string File pattern (e.g., "*.py")
---@param config table Configuration settings
function M.add_filetype(filetype, pattern, config)
  format_configs[filetype] = config
  
  -- Create autocmd for the new file type
  vim.api.nvim_create_autocmd({ "BufEnter" }, {
    group = vim.api.nvim_create_augroup("FormatWidth_" .. filetype:gsub("^%l", string.upper), {
      clear = true,
    }),
    pattern = pattern,
    callback = function()
      local bufnr = vim.api.nvim_get_current_buf()
      apply_format_settings(bufnr, config)
    end,
    desc = "Set " .. filetype .. " format width and settings"
  })
end

---Toggle width enforcement for current buffer
---@return boolean new_state
function M.toggle_buffer()
  local bufnr = vim.api.nvim_get_current_buf()
  local current_state = M.is_buffer_enabled(bufnr)
  local new_state = not current_state

  buffer_toggle_state[bufnr] = new_state

  -- Apply or remove format settings immediately
  local filetype = vim.api.nvim_buf_get_option(bufnr, "filetype")
  local config = format_configs[filetype]

  if config then
    if new_state then
      apply_format_settings(bufnr, config)
      vim.notify("Format width enabled for current buffer (" .. config.width .. " chars)", vim.log.levels.INFO)
    else
      -- Clear format settings
      vim.api.nvim_buf_set_option(bufnr, "colorcolumn", "")
      if config.textwidth then
        vim.api.nvim_buf_set_option(bufnr, "textwidth", 0)
      end
      vim.notify("Format width disabled for current buffer", vim.log.levels.INFO)
    end
  end

  return new_state
end

---Toggle width enforcement for a filetype globally
---@param filetype string Filetype to toggle
---@return boolean new_state
function M.toggle_filetype(filetype)
  if not format_configs[filetype] then
    vim.notify("FormatWidth: Unknown filetype '" .. filetype .. "'", vim.log.levels.ERROR)
    return false
  end

  if not format_configs[filetype].toggleable then
    vim.notify("FormatWidth: Filetype '" .. filetype .. "' is not toggleable", vim.log.levels.WARN)
    return toggle_state[filetype]
  end

  local new_state = not toggle_state[filetype]
  toggle_state[filetype] = new_state

  -- Apply to all buffers of this filetype
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      local buf_filetype = vim.api.nvim_buf_get_option(bufnr, "filetype")
      if buf_filetype == filetype and buffer_toggle_state[bufnr] == nil then
        local config = format_configs[filetype]
        if new_state then
          apply_format_settings(bufnr, config)
        else
          vim.api.nvim_buf_set_option(bufnr, "colorcolumn", "")
          if config.textwidth then
            vim.api.nvim_buf_set_option(bufnr, "textwidth", 0)
          end
        end
      end
    end
  end

  local state_text = new_state and "enabled" or "disabled"
  vim.notify("Format width " .. state_text .. " for all " .. filetype .. " files", vim.log.levels.INFO)

  return new_state
end

---Reset current buffer to filetype defaults
function M.reset()
  local bufnr = vim.api.nvim_get_current_buf()
  local filetype = vim.api.nvim_buf_get_option(bufnr, "filetype")
  local config = format_configs[filetype]

  if config then
    -- Clear any buffer-specific toggle state (fall back to filetype default)
    buffer_toggle_state[bufnr] = nil

    -- Reapply default settings
    apply_format_settings(bufnr, config)

    vim.notify("Format width reset to defaults (" .. config.width .. " chars) for current buffer", vim.log.levels.INFO)
  else
    vim.notify("FormatWidth: No configuration found for filetype '" .. filetype .. "'", vim.log.levels.WARN)
  end
end

---Format a single line to respect width limit
---@param line string Line to format
---@param width number Width limit
---@return string[] Array of formatted lines
local function format_line(line, width)
  if #line <= width then
    return { line }
  end

  local result = {}
  local remaining = line

  while #remaining > width do
    -- Find the best break point (prefer spaces)
    local break_point = width

    -- Look for a space near the width limit
    for i = width, math.max(1, width - 20), -1 do
      if remaining:sub(i, i) == " " then
        break_point = i - 1  -- Don't include the space
        break
      end
    end

    -- Extract the line segment
    local segment = remaining:sub(1, break_point)
    table.insert(result, segment)

    -- Remove the processed part (and any leading space)
    remaining = remaining:sub(break_point + 1):gsub("^%s+", "")
  end

  -- Add the remaining part
  if #remaining > 0 then
    table.insert(result, remaining)
  end

  return result
end

---Format lines in a buffer to respect width limit
---@param bufnr number Buffer number
---@param width number Width limit for formatting
---@param start_line? number Start line (1-based, default: 1)
---@param end_line? number End line (1-based, default: last line)
function M.format_buffer(bufnr, width, start_line, end_line)
  if width <= 0 then
    vim.notify("FormatWidth: Width must be a positive number", vim.log.levels.ERROR)
    return false
  end

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local total_lines = #lines

  -- Performance check for large files
  if total_lines > 10000 then
    local choice = vim.fn.confirm(
      "Large file detected (" .. total_lines .. " lines). Format anyway?",
      "&Yes\n&No",
      2
    )
    if choice ~= 1 then
      vim.notify("FormatWidth: Formatting cancelled", vim.log.levels.INFO)
      return false
    end
  end

  start_line = start_line or 1
  end_line = end_line or total_lines

  -- Validate line ranges
  if start_line < 1 or start_line > total_lines or end_line < start_line or end_line > total_lines then
    vim.notify("FormatWidth: Invalid line range", vim.log.levels.ERROR)
    return false
  end

  local formatted_lines = {}
  local changes_made = false

  for i = start_line, end_line do
    local line = lines[i]
    if #line > width then
      -- Format this line
      local formatted = format_line(line, width)
      for _, formatted_line in ipairs(formatted) do
        table.insert(formatted_lines, formatted_line)
      end
      changes_made = true
    else
      table.insert(formatted_lines, line)
    end
  end

  if changes_made then
    -- Replace the lines in the buffer
    vim.api.nvim_buf_set_lines(bufnr, start_line - 1, end_line, false, formatted_lines)
    local lines_affected = end_line - start_line + 1
    local new_line_count = #formatted_lines
    vim.notify("FormatWidth: Formatted " .. lines_affected .. " lines (now " .. new_line_count .. " lines)", vim.log.levels.INFO)
  else
    vim.notify("FormatWidth: No lines needed formatting", vim.log.levels.INFO)
  end

  return true
end

return M

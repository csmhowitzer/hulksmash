---@diagnostic disable: missing-fields

-- INFO: adjustments made to folke-snacks.nvim plugin
-- Changes:
--    - Border Style
--      - changed color
--    - Window Style
--      - the title of the scratch pad
--        - now includes file name (for list selection)
--      - shift to right side of window
--    - Re-loading Scratch Pads
--      - When you open any file that already has had a Scratch Pad this will open up the old one.
--      - You will never have a "new" one each time you open one up if one exists

local Snacks = require("snacks")

---@class ScratchPadConfig
---@field width number
---@field height number
---@field path string
---@field name string
---@field fmtName string
---@field ft string
---@field icon string
---@field file string|nil

---@class ScratchPadManager
local M = {}

-- Constants
local DEFAULT_FILETYPE = "markdown"
local BORDER_HIGHLIGHT = "SnacksInputBorder"
local BORDER_COLOR = "#F7DC6F"
local DASHBOARD_COLOR = "#a6d189"

-- Private functions
---@private
function get_window_options(width, height)
  return {
    row = 1,
    col = vim.o.columns - width,
    width = width,
    height = height - 3,
    wo = { winhighlight = "FloatBorder:SnacksInputBorder," },
  }
end

---@private
function format_buffer_name(name)
  return "Scratch Pad (" .. name .. ")"
end

---@private
function get_scratch_filename(win_name)
  return win_name:gsub("Scratch Pad %(", ""):gsub("%)", "")
end

---@private
function get_buffer_config(bufnr)
  local slice_width = math.floor(vim.o.columns / 3)
  local max_width = 100

  local path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":h")
  local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":t")
  local ft = vim.filetype.match({ filename = name }) or DEFAULT_FILETYPE
  local icon = Snacks.util.icon(ft, "filetype")

  path = path and vim.fn.fnamemodify(path, ":p:~")

  return {
    width = slice_width < max_width and slice_width or max_width,
    height = vim.api.nvim_win_get_height(0) - 3,
    path = path,
    name = name,
    fmtName = format_buffer_name(name),
    ft = ft,
    icon = icon,
    file = nil,
  }
end

-- Public functions
-- opens a new scratch pad
--- @param config any
function M.open_new_scratch_pad(config)
  Snacks.scratch({
    ft = config.ft,
    name = config.fmtName,
    win = get_window_options(config.width, config.height),
  })
  vim.api.nvim_set_hl(0, BORDER_HIGHLIGHT, { fg = BORDER_COLOR })
end

-- opens an existing scratch pad
---@param config {} : the buffer configuration options
function M.open_scratch(config)
  Snacks.scratch.open({
    icon = config.icon,
    file = config.file,
    name = config.fmtName,
    ft = config.ft,
    win = get_window_options(config.width, config.height),
  })
  vim.api.nvim_set_hl(0, BORDER_HIGHLIGHT, { fg = BORDER_COLOR })
end

-- finds an existing scratch pad
---@param buffers {} : list of buffers known
---@param config {} : the buffer configuration options
---@return {} | nil
function M.find_existing_scratch_pad(buffers, config)
  assert(config.path, "no path provided")
  assert(config.name, "no filename provided")

  for _, item in ipairs(buffers) do
    local wd = item.cwd and vim.fn.fnamemodify(item.cwd, ":p:~") or ""
    local fileName = get_scratch_filename(item.name)

    if fileName == config.name and wd == config.path then
      return {
        name = item.name,
        icon = item.icon or Snacks.util.icon(item.ft, "filetype"),
        file = item.file,
        ft = item.ft,
      }
    end
  end
  return nil
end

-- deletes an existing scratch pad
function M.delete_current_scratch_pad()
  local buffers = Snacks.scratch.list()
  local config = get_buffer_config(vim.api.nvim_get_current_buf())

  for _, item in ipairs(buffers) do
    local wd = item.cwd and vim.fn.fnamemodify(item.cwd, ":p:~") or ""
    local fileName = get_scratch_filename(item.name)

    if fileName == config.name and wd == config.path and item.file and vim.fn.filereadable(item.file) == 1 then
      vim.fn.delete(item.file)
      break
    end
  end
end

-- toggles the scratch pad
---@param file_type string | nil : the file type to open the scratch pad as
function M.toggle_scratch_pad(file_type)
  local buffers = Snacks.scratch.list()
  local config = get_buffer_config(vim.api.nvim_get_current_buf())

  local existing_pad = #buffers > 0 and M.find_existing_scratch_pad(buffers, config)
  if existing_pad then
    if file_type then
      existing_pad.ft = file_type
      existing_pad.icon = Snacks.util.icon(file_type, "filetype")
    end
    config.fmtName = existing_pad.name
    config.ft = existing_pad.ft
    config.file = existing_pad.file
    config.icon = existing_pad.icon
    M.open_scratch(config)
  else
    if file_type then
      config.ft = file_type
    end
    M.open_new_scratch_pad(config)
  end
end

-- Setup keymaps and highlights
function M.setup()
  vim.api.nvim_create_user_command("ScratchPadDisplay", function()
    M.toggle_scratch_pad()
  end, { desc = "Toggle Scratch Buffer" })
  -- Keymaps
  vim.keymap.set("n", "==", function()
    M.toggle_scratch_pad("markdown")
  end, { desc = "Toggle Scratch Buffer (Markdown)" })

  vim.keymap.set("n", "=c", function()
    M.toggle_scratch_pad()
  end, { desc = "Toggle Scratch Buffer (Lang)" })

  vim.keymap.set("n", "=s", function()
    Snacks.scratch.select()
  end, { desc = "Select Scratch Buffer" })

  vim.keymap.set("n", "=d", function()
    M.delete_current_scratch_pad()
  end, { desc = "Delete Scratch Buffer" })

  -- Highlights
  vim.api.nvim_set_hl(0, "SnacksDashboardHeader", { fg = DASHBOARD_COLOR })
end

-- Initialize
M.setup()

return M

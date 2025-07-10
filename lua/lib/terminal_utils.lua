---@class TerminalUtils
---@field setup function
---@field open_horizontal function
---@field open_vertical function
---@field open_tab function
local M = {}

--- Open terminal in new horizontal window
---@return nil
function M.open_horizontal()
  vim.cmd.vnew()
  vim.cmd.term()
  vim.cmd.wincmd("J")
  vim.api.nvim_win_set_height(0, 15)
end

--- Open terminal in new vertical window
---@return nil
function M.open_vertical()
  vim.cmd.vnew()
  vim.cmd.term()
end

--- Open terminal in new tab
---@return nil
function M.open_tab()
  vim.cmd.tabnew()
  vim.cmd.term()
end

--- Setup terminal utilities with keymaps and autocmds
---@param opts? table Optional configuration table
---@return nil
function M.setup(opts)
  opts = opts or {}
  
  -- Configure terminal when opened
  vim.api.nvim_create_autocmd("TermOpen", {
    desc = "Configuration of terminal when we open it",
    group = vim.api.nvim_create_augroup("custom-term-open", { clear = true }),
    callback = function()
      vim.opt.number = false -- gutter line numbers
      vim.opt.relativenumber = false -- gutter
    end,
  })

  -- Terminal keymaps
  vim.keymap.set("n", "<leader>`h", M.open_horizontal, { desc = "Open terminal in new horizontal window" })
  vim.keymap.set("n", "<leader>`v", M.open_vertical, { desc = "Open terminal in new vertical window" })
  vim.keymap.set("n", "<leader>`t", M.open_tab, { desc = "Open terminal in new tab" })
end

return M

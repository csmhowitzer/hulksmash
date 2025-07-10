---@class ThemeUtils
---@field setup function
---@field toggle_transparent function
---@field toggle_dark function
---@field apply_default_settings function
local M = {}

--- Toggle to transparent background theme
---@return nil
function M.toggle_transparent()
  vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
  vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
  vim.api.nvim_set_hl(0, "TelescopeNormal", { bg = "none" })
  vim.api.nvim_set_hl(0, "LineNrAbove", { fg = "#6078A0" })
  vim.api.nvim_set_hl(0, "LineNrBelow", { fg = "#6078A0" })
  vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#638860" })
end

--- Toggle to dark background theme
---@return nil
function M.toggle_dark()
  -- catppuccin palette original bg color #1e1e2e
  vim.api.nvim_set_hl(0, "Normal", { bg = "#060609" })
  vim.api.nvim_set_hl(0, "NormalFloat", { bg = "#060609" })
  vim.api.nvim_set_hl(0, "TelescopeNormal", { bg = "#060609" })
  vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#638860" })
end

--- Apply default scheme settings with transparent background and custom highlights
---@return nil
function M.apply_default_settings()
  vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
  vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
  vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
  vim.api.nvim_set_hl(0, "NeoTreeNormal", { bg = "none" })
  vim.api.nvim_set_hl(0, "NeoTreeNormalNC", { bg = "none" })
  vim.api.nvim_set_hl(0, "TelescopeNormal", { bg = "none" })
  vim.api.nvim_set_hl(0, "SignColumn", { fg = "#CB444A" }) -- a pinkish color
  vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#638860" })

  -- Configure diagnostics hover window with border (matches LSP hover style)
  vim.diagnostic.config({
    float = {
      border = "rounded",
      source = "always",
      header = "",
      prefix = "",
      format = function(diagnostic)
        local code = diagnostic.code and string.format(" [%s]", diagnostic.code) or ""
        return string.format("%s%s", diagnostic.message, code)
      end,
    },
    -- Show diagnostics automatically when cursor is on a line with diagnostics
    virtual_text = true,
    signs = true,
    underline = true,
    update_in_insert = false,
    severity_sort = true,
  })

  -- Auto-show diagnostics hover when navigating to errors (like quickfix navigation)
  vim.api.nvim_create_autocmd("CursorHold", {
    group = vim.api.nvim_create_augroup("DiagnosticsHover", { clear = true }),
    callback = function()
      local opts = {
        focusable = false,
        close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
        border = "rounded",
        source = "always",
        prefix = "",
        scope = "cursor",
      }
      vim.diagnostic.open_float(nil, opts)
    end
  })

  -- You can configure highlights by doing something like
  vim.cmd.hi("Comment gui=italic")
end

--- Setup theme utilities with keymaps
---@param opts? table Optional configuration table
---@return nil
function M.setup(opts)
  opts = opts or {}
  
  -- Set up keymaps
  vim.keymap.set("n", "<leader>tt", function()
    M.toggle_transparent()
  end, { desc = "Toggle Transparent background (transparent)" })
  
  vim.keymap.set("n", "<leader>td", function()
    M.toggle_dark()
  end, { desc = "Toggle Transparent background (dark color)" })
  
  -- Apply default settings if requested
  if opts.apply_defaults ~= false then
    M.apply_default_settings()
  end
end

return M

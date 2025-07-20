-- M_Roslyn: Modular enhancements for roslyn.nvim
-- Following the established m_augment pattern for extensible LSP enhancements

local M = {}

---Setup roslyn.nvim enhancements with configurable options
---@param opts table? Configuration options for roslyn enhancements
---@field auto_insert_docs boolean|table? Enable documentation auto-insert (default: true)
function M.setup(opts)
  opts = opts or {}
  
  -- Documentation auto-insert enhancement
  if opts.auto_insert_docs ~= false then
    local docs_opts = type(opts.auto_insert_docs) == "table" and opts.auto_insert_docs or {}
    require("m_roslyn.auto_insert_docs").setup(docs_opts)
  end

  -- Create user commands
  vim.api.nvim_create_user_command('MRoslynEnable', function()
    require('m_roslyn.auto_insert_docs').enable()
  end, {
    desc = 'Enable C# documentation auto-insert functionality'
  })

  vim.api.nvim_create_user_command('MRoslynDisable', function()
    require('m_roslyn.auto_insert_docs').disable()
  end, {
    desc = 'Disable C# documentation auto-insert functionality'
  })

  vim.api.nvim_create_user_command('MRoslynToggle', function()
    require('m_roslyn.auto_insert_docs').toggle()
  end, {
    desc = 'Toggle C# documentation auto-insert functionality'
  })

  vim.api.nvim_create_user_command('MRoslynStatus', function()
    local config = require('m_roslyn.auto_insert_docs').get_config()
    local status = config.enabled and "enabled" or "disabled"
    vim.notify("M_Roslyn auto-insert documentation: " .. status, vim.log.levels.INFO, {
      title = "M_Roslyn Status"
    })
  end, {
    desc = 'Show current status of m_roslyn enhancements'
  })

  vim.api.nvim_create_user_command('MRoslynDebug', function()
    local config = require('m_roslyn.auto_insert_docs').get_config()
    local new_debug = not config.debug
    require('m_roslyn.auto_insert_docs').setup({debug = new_debug})
    local status = new_debug and "enabled" or "disabled"
    vim.notify("M_Roslyn debug mode: " .. status, vim.log.levels.INFO, {
      title = "M_Roslyn Debug"
    })
  end, {
    desc = 'Toggle debug mode for m_roslyn enhancements'
  })
end

return M

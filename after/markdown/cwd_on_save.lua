-- INFO: Auto-Switch cwd when entering a new file on BufEnter.

local utils = require("user.utils")

-- autocommand .md files
vim.api.nvim_create_autocmd({ "BufEnter" }, {
  group = vim.api.nvim_create_augroup("MD_Cwd_Switch", {
    clear = true,
  }),
  pattern = "*.md",
  callback = function()
    utils.set_cwd()
  end,
})

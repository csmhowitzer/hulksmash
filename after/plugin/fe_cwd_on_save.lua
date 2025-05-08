-- INFO: Auto-Switch cwd when entering a new file on BufEnter.

local utils = require("user.utils")

-- autocommand front-end files
vim.api.nvim_create_autocmd({ "BufEnter" }, {
  group = vim.api.nvim_create_augroup("FE_Cwd_Switch", {
    clear = true,
  }),
  pattern = "*.js, *.jsx, *.ts, *.tsx, *.vue",
  callback = function()
    utils.set_cwd()
  end,
})

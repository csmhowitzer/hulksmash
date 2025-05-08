-- INFO: Auto-Switch cwd when entering a new file on BufEnter.
-- C#
--    switch the cwd to the .sln root path

local utils = require("user.utils")

-- autocommand .cs files
vim.api.nvim_create_autocmd({ "BufEnter" }, {
  group = vim.api.nvim_create_augroup("CS_Cwd_Switch", {
    clear = true,
  }),
  pattern = "*.cs",
  callback = function()
    local slnPath = utils.find_sln_root()
    if slnPath ~= nil and slnPath ~= "" then
      utils.set_cwd(slnPath)
    end
  end,
})

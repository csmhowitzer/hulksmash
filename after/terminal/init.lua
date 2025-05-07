vim.api.nvim_create_autocmd("TermOpen", {
  desc = "Configuration of terminal when we open it",
  group = vim.api.nvim_create_augroup("custom-term-open", { clear = true }),
  callback = function()
    vim.opt.number = false -- gutter line numbers
    vim.opt.relativenumber = false -- gutter
  end,
})

-- INFO: New Terminal Buffers
-- Horizontal Window
-- Vertical Window
-- New Tab
vim.keymap.set("n", "<leader>`h", function()
  vim.cmd.vnew()
  vim.cmd.term()
  vim.cmd.wincmd("J")
  vim.api.nvim_win_set_height(0, 15)
end)
vim.keymap.set("n", "<leader>`v", function()
  vim.cmd.vnew()
  vim.cmd.term()
end)
-- TODO: We want to make one that opens a new term in a new tab
vim.keymap.set("n", "<leader>`t", function()
  vim.cmd.tabnew()
  vim.cmd.term()
end)

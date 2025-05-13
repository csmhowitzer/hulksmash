-- autocommand
-- Markdown format:
-- Sets line wrapping to 80 chars
vim.api.nvim_create_autocmd({ "BufEnter" }, {
  group = vim.api.nvim_create_augroup("MDFmt", {
    clear = true,
  }),
  pattern = "*.md",
  callback = function()
    local width = 80
    local bufnr = vim.api.nvim_get_current_buf()
    vim.opt.conceallevel = 2
    --print('Markdown file bufnr: ' .. bufnr .. ' cw: ' .. width)
    vim.api.nvim_buf_set_option(bufnr, "colorcolumn", tostring(width))
    vim.api.nvim_buf_set_option(bufnr, "textwidth", width)
  end,
})

---autocommand
vim.api.nvim_create_autocmd({ "BufEnter" }, {
  group = vim.api.nvim_create_augroup("CSFmtWidth", {
    clear = true,
  }),
  pattern = "*.cs",
  callback = function()
    local width = 120
    local bufnr = vim.api.nvim_get_current_buf()
    vim.opt.tabstop = 4
    vim.opt.softtabstop = 4
    vim.opt.shiftwidth = 4
    vim.api.nvim_buf_set_option(bufnr, "colorcolumn", tostring(width))
  end,
})

---autocommand
vim.api.nvim_create_autocmd({ "BufEnter" }, {
  group = vim.api.nvim_create_augroup("CSFmtWidth", {
    clear = true,
  }),
  pattern = "*.lua",
  callback = function()
    local width = 120
    local bufnr = vim.api.nvim_get_current_buf()
    vim.opt.tabstop = 2
    vim.opt.softtabstop = 2
    vim.opt.shiftwidth = 2
    vim.api.nvim_buf_set_option(bufnr, "colorcolumn", tostring(width))
  end,
})

-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
require("user.utils")

vim.cmd.colorscheme("catppuccin")
vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
vim.api.nvim_set_hl(0, "NeoTreeNormal", { bg = "none" })
vim.api.nvim_set_hl(0, "NeoTreeNormalNC", { bg = "none" })
vim.api.nvim_set_hl(0, "TelescopeNormal", { bg = "none" })
vim.api.nvim_set_hl(0, "SignColumn", { fg = "#CB444A" }) -- a pinkish color
vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#638860" })

-- You can configure highlights by doing something like
vim.cmd.hi("Comment gui=italic")

vim.cmd([[hi @lsp.type.constant.cs guifg=#fab387]])

local DASHBOARD_COLOR = "#a6d189"
vim.api.nvim_set_hl(0, "SnacksDashboardHeader", { fg = DASHBOARD_COLOR })

vim.opt.fileformats = { "unix", "dos" }
vim.opt.fileformats = "unix,dos"

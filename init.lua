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

-- You can configure highlights by doing something like
vim.cmd.hi("Comment gui=italic")

local DASHBOARD_COLOR = "#a6d189"
vim.api.nvim_set_hl(0, "SnacksDashboardHeader", { fg = DASHBOARD_COLOR })

vim.opt.fileformat = { "dos" }

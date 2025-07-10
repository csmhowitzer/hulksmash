-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
require("lib.utils")

-- Setup theme utilities and apply default settings
vim.cmd.colorscheme("catppuccin")
require("lib.theme_utils").setup()

vim.cmd([[hi @lsp.type.constant.cs guifg=#fab387]])

local DASHBOARD_COLOR = "#a6d189"
vim.api.nvim_set_hl(0, "SnacksDashboardHeader", { fg = DASHBOARD_COLOR })

vim.opt.fileformats = { "unix", "dos" }
vim.opt.fileformats = "unix,dos"

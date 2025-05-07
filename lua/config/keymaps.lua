-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Set highlight on search, but clear on pressing <Esc> in normal mode
vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Diagnostic keymaps
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Go to previous [D]iagnostic message" })
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Go to next [D]iagnostic message" })
-- vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Show diagnostic [E]rror messages' })
-- vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- TIP: Disable arrow keys in normal mode
vim.keymap.set("n", "<left>", '<cmd>echo "Use h to move!!"<CR>')
vim.keymap.set("n", "<right>", '<cmd>echo "Use l to move!!"<CR>')
vim.keymap.set("n", "<up>", '<cmd>echo "Use k to move!!"<CR>')
vim.keymap.set("n", "<down>", '<cmd>echo "Use j to move!!"<CR>')

--vim.keymap.set('n', '<leader>pv', vim.cmd.Ex) -- netrw, overwritten by oil.nvim
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv") -- ALT move down selected text
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv") -- ALT move up selected text

vim.keymap.set("n", "J", "mzJ`z") -- keeps cursor centered after copy+replace
vim.keymap.set("n", "<C-d>", "<C-d>zz") -- half page jump down but keep cursor pos
vim.keymap.set("n", "<C-u>", "<C-u>zz") -- half page jump up but keep cursor pos

vim.keymap.set("n", "n", "nzzzv") -- keep search terms cursor position (replaces n)
vim.keymap.set("n", "N", "Nzzzv") -- keep search terms cursor position (replaces N)

-- great remap!
vim.keymap.set("x", "<leader>p", '"_dP') -- overwrite highlighted word from buffer

vim.keymap.set({ "i", "v" }, "<C-c>", "<Esc>")

-- faster searching if you have the cursor over the search word
vim.keymap.set(
  "n",
  "<leader>s",
  [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
  { desc = "[S]earch for cursor word" }
)
--vim.keymap.set('n', '<leader>x', '<cmd>!chmod +x %<CR>', { silent = true })

vim.keymap.set("n", "<leader><leader>x", "<cmd>source %<CR>", { desc = "[S]ource file" })
-- vim.keymap.set('n', '<leader>x', '.lua<CR>', { desc = 'Run Lua Command' })
-- vim.keymap.set('v', '<leader>x', ':lua<CR>', { desc = 'Run Lua Command' })
-- :bN is the next buffer command
--vim.keymap.set('n', '<leader>hb', '<cmd>bp<CR>', { desc = '[P]revious [B]uffer' })

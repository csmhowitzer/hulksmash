-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- CONFIG: Deleted default keymaps go first
vim.keymap.del("n", "<leader>l", { desc = "Lazy" })
vim.keymap.del("n", "<leader>`", { desc = "Switch to other buffer" })
vim.keymap.del("n", "<C-s>", { desc = "Save File" })
vim.keymap.del("n", "<leader>.", { desc = "Toggle Scratch Buffer" })
vim.keymap.del("n", "<leader>qq", { desc = "Quit All" })
vim.keymap.del("n", "<leader>qs", { desc = "Restore Session" })
vim.keymap.del("n", "<leader>qS", { desc = "Select Session" })
vim.keymap.del("n", "<leader>ql", { desc = "Restore Last Session" })
vim.keymap.del("n", "<leader>qd", { desc = "Don't Save Current Session" })

-- Treesitter
vim.keymap.set("n", "<leader>ii", "<cmd>Inspect<CR>", { desc = "Inspect Treesitter Node" })

-- Set highlight on search, but clear on pressing <Esc> in normal mode
vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- quickfix list
vim.keymap.set("n", "<leader>q", function()
  local success, err = pcall(vim.fn.getqflist({ winid = 0 }).winid ~= 0 and vim.cmd.cclose or vim.cmd.copen)
  if not success and err then
    vim.notify(err, vim.log.levels.ERROR)
  end
end, { desc = "Quickfix List" })
-- location list (traditional quickfix locations)
vim.keymap.set("n", "<leader>l", function()
  local success, err = pcall(vim.fn.getloclist(0, { winid = 0 }).winid ~= 0 and vim.cmd.lclose or vim.cmd.lopen)
  if not success and err then
    vim.notify(err, vim.log.levels.ERROR)
  end
end, { desc = "Location List" })

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
  "<leader>h",
  [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
  { desc = "[S]earch for cursor word" }
)

vim.keymap.set("n", "<leader><leader>x", "<cmd>source %<CR>", { desc = "[S]ource file" })

-- -- Move to window using the <ctrl> hjkl keys
vim.keymap.set("n", "<S-h>", "<C-w>h", { desc = "Go to Left Window" })
vim.keymap.set("n", "<S-j>", "<C-w>j", { desc = "Go to Lower Window" })
vim.keymap.set("n", "<S-k>", "<C-w>k", { desc = "Go to Upper Window" })
vim.keymap.set("n", "<S-l>", "<C-w>l", { desc = "Go to Right Window" })

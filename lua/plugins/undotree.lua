return {
  {
    "mbbill/undotree",
    config = function()
      -- general keymaps
      vim.keymap.set("n", "<leader>ut", vim.cmd.UndotreeToggle, { desc = "[U]ndotree [T]oggle" })
    end,
  },
}

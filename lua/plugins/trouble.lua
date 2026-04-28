return {
  {
    "folke/trouble.nvim",
    keys = {
      -- Remap xQ -> Q (fewer keys, distinct from <leader>q regular quickfix)
      { "<leader>xQ", false },
      { "<leader>Q", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix List (Trouble)" },
    },
  },
}

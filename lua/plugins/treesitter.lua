return {
  { "nvim-treesitter/playground", dependencies = { "nvim-treesitter/nvim-treesitter" } },
  {
    "nvim-treesitter/nvim-treesitter",
    pin = true,
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        "yaml",
      })
    end,
  },
}

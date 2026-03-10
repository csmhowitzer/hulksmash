return {
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      {
        "<leader><leader>a",
        function()
          require("harpoon"):list():add()
        end,
        desc = "Harpoon: Add file",
      },
      {
        "<C-e>",
        function()
          local harpoon = require("harpoon")
          harpoon.ui:toggle_quick_menu(harpoon:list())
        end,
        desc = "Harpoon: Toggle menu",
      },
      {
        "<C-h>",
        function()
          require("harpoon"):list():select(1)
        end,
        desc = "Harpoon: Select 1",
      },
      {
        "<C-j>",
        function()
          require("harpoon"):list():select(2)
        end,
        desc = "Harpoon: Select 2",
      },
      {
        "<C-k>",
        function()
          require("harpoon"):list():select(3)
        end,
        desc = "Harpoon: Select 3",
      },
      {
        "<C-l>",
        function()
          require("harpoon"):list():select(4)
        end,
        desc = "Harpoon: Select 4",
      },
      {
        "<C-P>",
        function()
          require("harpoon"):list():prev()
        end,
        desc = "Harpoon: Previous",
      },
      {
        "<C-N>",
        function()
          require("harpoon"):list():next()
        end,
        desc = "Harpoon: Next",
      },
      {
        "<M-r>",
        function()
          require("harpoon"):list():remove()
        end,
        desc = "Harpoon: Remove file",
      },
      {
        "<M-c>",
        function()
          require("harpoon"):list():clear()
        end,
        desc = "Harpoon: Clear list",
      },
    },
    config = function()
      require("harpoon"):setup()
    end,
  },
}

-- CONFIG: M1 chip on MAC-mini needs a differnt config
-- uncomment the first github plugin
-- comment out the next one

-- INFO: The copy of netcoredbg present on both the laptop and mac-mini is the
-- version that will work correctly for debugging. Not exactly sure what makes
-- it the version that works. New build, and repo clone build from the Samsung
-- repo did not work.
--

-- Credit for setup
-- https://aaronbos.dev/posts/debugging-csharp-neovim-nvim-dap
-- https://github.com/Samsung/netcoredbg
-- https://blog.coderscoffeehouse.com/tech/2022-10-26-dotnet-debugging-in-vim-using-apple-silicon/
-- Also TJ's video

--not needed for laptop, maybe make this a choice?
return {
  {
    -- Mac Mini only
    -- 'Cliffback/netcoredbg-macOS-arm64.nvim',
    -- All other Linux based
    "mfussenegger/nvim-dap",
    dependencies = {
      "mfussenegger/nvim-dap",
      "leoluz/nvim-dap-go",
      "rcarriga/nvim-dap-ui",
      "theHamsta/nvim-dap-virtual-text",
      "nvim-neotest/nvim-nio",
      "mason-org/mason.nvim",
      "folke/neodev.nvim",
    },

    config = function()
      local dap = require("dap")
      local ui = require("dapui")

      require("dapui").setup({
        icons = { expanded = "▾", collapsed = "▸", current_frame = "▸" },

        mappings = {
          -- Use a table to apply multiple mappings
          expand = { "<CR>", "<2-LeftMouse>" },
          open = "o",
          remove = "d",
          edit = "e",
          repl = "r",
          toggle = "t",
        },
        element_mappings = {},
        expand_lines = vim.fn.has("nvim-0.7") == 1,
        force_buffers = true,
        layouts = {
          {
            -- You can change the order of elements in the sidebar
            elements = {
              -- Provide IDs as strings or tables with "id" and "size" keys
              {
                id = "scopes",
                size = 0.25, -- Can be float or integer > 1
              },
              { id = "breakpoints", size = 0.25 },
              { id = "stacks", size = 0.25 },
              { id = "watches", size = 0.25 },
            },
            size = 40,
            position = "left", -- Can be "left" or "right"
          },
          {
            elements = {
              "repl",
              "console",
            },
            size = 10,
            position = "bottom", -- Can be "bottom" or "top"
          },
        },
        floating = {
          max_height = nil,
          max_width = nil,
          border = "single",
          mappings = {
            ["close"] = { "q", "<Esc>" },
          },
        },
        controls = {
          -- Requires Neovim nightly (or 0.8 when released)
          enabled = vim.fn.exists("+winbar") == 1,
          -- Display controls in this element
          element = "repl",
          icons = {
            pause = "",
            play = "",
            step_into = "", --'',
            step_over = "󰆷", --''
            step_out = "", --''
            step_back = "",
            run_last = "󰜉",
            terminate = "□",
            disconnect = "󰅛", --'󰿅',
          },
        },
        render = {
          max_type_length = nil, -- Can be integer or nil.
          max_value_lines = 100, -- Can be integer or nil.
          indent = 1,
        },
      })

      require("dap-go").setup()
      require("nvim-dap-virtual-text").setup({ enabled = true })

      -- Handled by nvim-dap-go
      -- dap.adapters.go = {
      --  type = "server",
      --  port = "${port}",
      --  executable = {
      --    command = "dlv",
      --    args = { "dap", "-l", "127.0.0.1:${port}" },
      --  },
      --}

      local coreclr = vim.fn.exepath("netcoredbg")
      --print(coreclr)
      local dotnet = vim.fn.exepath("dotnet")

      -- find the .sln root folder for the given file that the buffer resides in
      local find_sln_root = function()
        local bufnr = vim.api.nvim_get_current_buf()
        local bufPath = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":h")
        vim.api.nvim_set_current_dir(bufPath)
        return vim.fs.root(bufPath, function(name)
          return name:match("%.sln$") ~= nil
        end)
      end

      -- find the .csproj root folder for the given file the buffer resides in
      local find_proj_root = function()
        local bufnr = vim.api.nvim_get_current_buf()
        local bufPath = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":h")
        vim.api.nvim_set_current_dir(bufPath)
        return vim.fs.root(bufPath, function(name)
          return name:match("%.csproj$") ~= nil
        end)
      end

      -- find the project's .dll that netcoredbg will run off of
      local find_dap_dll = function()
        local path = find_proj_root()
        local dllName = vim.fn.fnamemodify(path, ":t") .. ".dll"
        local result = vim.fs.find({ dllName }, { limit = 1, path = path })
        return result[1]
      end

      local find_workspace_root = function()
        local slnRoot = find_sln_root()
        if slnRoot ~= nil and slnRoot ~= "" then
          return slnRoot
        end
        return find_proj_root()
      end

      if coreclr ~= "" and dotnet ~= "" then
        dap.adapters.coreclr = {
          type = "executable",
          command = coreclr,
          args = { "--interpreter=vscode" },
        }
        dap.configurations.cs = {
          {
            type = "coreclr",
            justMyCode = false,
            stopatEntry = false,
            name = "launch - netcoredbg",
            request = "launch",
            --this may be needed for api type of configuration
            --args = { '/p:EnvironmentName=Development', '--urls=http://localhost:5004', '--environment=Development' },
            program = function()
              return find_dap_dll()
            end,
            env = {
              ASPNETCORE_ENVIRONMENT = function()
                return "Development"
              end,
            },
            cwd = function()
              return find_workspace_root()
            end,
          },
        }
      else
        print("couldn't find executable")
      end

      -- keymaps
      vim.keymap.set("n", "<leader>b", dap.toggle_breakpoint, { desc = "Set [b]reakpoint" })
      vim.keymap.set("n", "<leader>gb", dap.run_to_cursor, { desc = "Run to cursor" })

      vim.keymap.set("n", "<leader>?", function()
        require("dapui").eval(nil, { enter = true })
      end, { desc = "Evaluate under cursor (inspect)" })

      vim.keymap.set("n", "<F5>", dap.continue, { desc = "Dap Continue" })
      vim.keymap.set("n", "<F10>", dap.step_over, { desc = "Dap Step Over" })
      vim.keymap.set("n", "<F11>", dap.step_into, { desc = "Dap Step Into" })
      vim.keymap.set("n", "<F12>", dap.step_out, { desc = "Dap Step Out" })
      vim.keymap.set("n", "<F9>", dap.step_back, { desc = "Dap Step Back" })
      vim.keymap.set("n", "<F6>", dap.close, { desc = "Dap Stop" })
      vim.keymap.set("n", "<F7>", dap.restart, { desc = "Dap Restart" })

      -- Open/Close Dap UI configuration
      dap.listeners.before.attach.dapui_config = function()
        ui.open()
      end
      dap.listeners.before.launch.dapui_config = function()
        ui.open()
      end
      dap.listeners.before.event_terminated.dapui_config = function()
        ui.close()
      end
      dap.listeners.before.event_exited.dapui_config = function()
        ui.close()
      end
    end,
  },
}

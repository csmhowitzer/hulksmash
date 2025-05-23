return {
  {
    "augmentcode/augment.vim",
    dependencies = { "hrsh7th/nvim-cmp" },
    config = function()
      vim.g.augment_disable_completions = true

      local utils = require("user.utils")
      local workspace_path = "~/.augment/workspaces.json"

      --- Reads the workspaces from the config file.
      --- @return any
      local read_workspaces = function()
        local config_path = vim.fn.expand(workspace_path)
        if not utils.file_exists(config_path) then
          utils.create_home_dir_if_not_exists(config_path)
        end
        local content = utils.read_file_content(config_path)

        local ok, decoded = pcall(vim.json.decode, content)
        return ok and decoded or {}
      end

      --- Adds a workspace folder.
      --- @param path string?
      --- @return any
      local add_workspace_folder = function(path)
        local name = vim.fn.input("Workspace Name: ")
        if name == "" then
          return
        end

        local add_path = function(wksp)
          wksp = wksp:gsub("\\", "")
          local workspaces = read_workspaces()
          if workspaces.workspaces == nil then
            workspaces.workspaces = {}
          end
          table.insert(workspaces.workspaces, {
            name = name,
            path = vim.fn.resolve(wksp),
          })
          local json = vim.json.encode(workspaces)
          local file = io.open(vim.fn.expand(workspace_path), "w")
          if file then
            file:write(json)
            file:close()
            vim.notify("Workspace added successfully", vim.log.levels.INFO)
          end
        end

        if path == nil or path == "" then
          path = vim.fn.input("Workspace Path: ")
          if path == "" then
            return
          end
        else
          path = vim.fn.fnamemodify(path, ":p:~")
          utils.confirm_dialog(string.format("Add (%s) as a workspace path?", path), function(choice)
            if choice then
              add_path(path)
            else
              return
            end
          end)
        end
      end

      --- Lists the workspaces.
      --- @return any
      local list_workspaces = function()
        local workspaces = read_workspaces()
        if workspaces.workspaces then
          local workspace_list = "Current Workspaces:\n"
          for _, workspace in ipairs(workspaces.workspaces) do
            workspace_list = workspace_list .. "- " .. workspace.name .. ": " .. workspace.path .. "\n"
          end
          vim.notify(workspace_list, vim.log.levels.INFO)
        else
          vim.notify("No workspaces configured", vim.log.levels.INFO)
        end
      end

      --- Ingests the workspaces.
      --- @return any
      local ingest_workspaces = function()
        local workspaces = read_workspaces() or {}

        if workspaces == nil or workspaces.workspaces == nil then
          print("No Augment workspaces configured")
          return
        end

        local folders = {}
        for _, workspace in ipairs(workspaces.workspaces) do
          table.insert(folders, workspace.path)
        end
        if #folders <= 0 then
          vim.notify("No workspaces configured", vim.log.levels.INFO)
        end
        return folders
      end
      vim.g.augment_workspace_folders = ingest_workspaces()

      --- Custom function to check nvim-cmp menu visibility
      local Augment_Accept = function()
        -- Check if nvim-cmp menu is visible
        if require("cmp").visible() then
          require("cmp").confirm({ select = true })
        else
          -- Call Augment's accept function
          vim.cmd([[call augment#Accept('N/A')]])
        end
      end

      vim.keymap.set({ "n", "v" }, "<leader>ac", "<CMD>Augment chat<CR>", { desc = "[A]ugment [C]hat" })
      vim.keymap.set("n", "<leader>an", "<CMD>Augment chat new<CR>", { desc = "[A]ugment Chat [N]ew" })
      vim.keymap.set("n", "<leader>aw", "<CMD>Augment chat-toggle<CR>", { desc = "[A]ugment Chat Toggle [W]indow" })
      vim.keymap.set("n", "<leader>asi", "<CMD>Augment signin<CR>", { desc = "[A]ugment [S]ign[I]n" })
      vim.keymap.set("n", "<leader>aso", "<CMD>Augment signout<CR>", { desc = "[A]ugment [S]ign[O]ut" })
      vim.keymap.set("n", "<leader>ast", "<CMD>Augment status<CR>", { desc = "[A]ugment [S]tatus" })

      vim.keymap.set("n", "<leader>atog", function()
        if vim.g.augment_disable_completions == false then
          vim.g.augment_disable_completions = true
          vim.notify("Augment disabled", vim.log.levels.INFO)
        else
          vim.g.augment_disable_completions = false
          vim.notify("Augment enabled", vim.log.levels.INFO)
        end
      end, { desc = "[A]ugment [T]oggle" })

      vim.keymap.set("n", "<leader>atab", function()
        if vim.g.augment_disable_tab_mapping == false then
          vim.g.augment_disable_tab_mapping = true
          vim.notify("Augment <Tab> disabled", vim.log.levels.INFO)
        else
          vim.g.augment_disable_tab_mapping = false
          vim.notify("Augment <Tab> enabled", vim.log.levels.INFO)
        end
      end, { desc = "[A]ugment Toggle [T]ab completion" })

      vim.keymap.set("n", "<leader>alw", function()
        list_workspaces()
      end, { desc = "[A]ugment [L]ist [W]orkspaces" })

      vim.keymap.set("n", "<leader>aacw", function()
        add_workspace_folder()
      end, { desc = "[A]ugment [A]dd [C]ustom [W]orkspace" })
      vim.keymap.set("n", "<leader>aaw", function()
        print(vim.fn.getcwd())
        utils.confirm_dialog("Do you want to add this path: " .. vim.fn.getcwd(), function(answer)
          if answer == true then
            add_workspace_folder(vim.fn.getcwd())
          end
        end)
      end, { desc = "[A]ugment [A]dd [W]orkspace Path" })

      vim.keymap.set("i", "<C-y>", function()
        Augment_Accept()
      end, { desc = "Accept completion or Augment suggestion" })
    end,

    -- vim.api.nvim_create_autocmd('ColorScheme', {
    --   pattern = 'peachpuff',
    --   callback = function()
    --     vim.api.nvim_set_hl(0, 'AugmentSuggestionHighlight', {
    --       fg = '#888888',
    --       ctermfg = 8,
    --       force = true,
    --     })
    --   end,
    -- }),
  },
}

return {
  {
    "augmentcode/augment.vim",
    dependencies = { "hrsh7th/nvim-cmp" },
    config = function()
      vim.g.augment_disable_completions = true

      local utils = require("user.utils")
      local workspace_path = "~/.augment/workspaces.json"

      local augment_buffer_content = {}
      local augment_message_history = {}
      local history_index = 0

      local function navigate_history(direction)
        if #augment_message_history == 0 then
          return
        end

        if direction == "up" then
          history_index = math.min(history_index + 1, #augment_message_history)
        else
          history_index = math.max(history_index - 1, 0)
        end

        if history_index > 0 then
          local historic_message = augment_message_history[#augment_message_history - history_index + 1]
          vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(historic_message, "\n"))
        else
          vim.api.nvim_buf_set_lines(0, 0, -1, false, {})
        end
      end

      local function save_to_history(message)
        table.insert(augment_message_history, message)
        history_index = 0
      end

      local function open_augment_chat_buffer()
        -- Create a new buffer
        local bufnr = vim.api.nvim_create_buf(false, true)

        -- Set buffer options
        vim.api.nvim_set_option_value("bufhidden", "hide", { buf = bufnr })
        vim.api.nvim_set_option_value("filetype", "markdown", { buf = bufnr })

        -- Calculate window dimensions
        local height = math.floor(vim.o.lines / 4)
        local width = math.floor(vim.o.columns / 3)
        local max_width = 100
        width = width < max_width and width or max_width

        local row = 2
        local col = math.floor((vim.o.columns - width) / 2)

        -- Create window
        local win_id = vim.api.nvim_open_win(bufnr, true, {
          relative = "editor",
          row = row,
          col = col,
          width = width,
          height = height,
          style = "minimal",
          border = "rounded",
          title = " 󰚩 Augment Chat 󰚩 ",
          title_pos = "center",
          footer = " q close; <CR> send; <C-n>, <C-p>, nav history ",
          footer_pos = "center",
        })

        -- Set window options
        vim.api.nvim_set_option_value("wrap", true, { win = win_id })
        vim.api.nvim_set_option_value("linebreak", true, { win = win_id })
        vim.api.nvim_set_option_value(
          "winhighlight",
          "FloatBorder:AugmentChatBorder,FloatTitle:AugmentChatTitle,FloatFooter:AugmentChatFooter",
          { win = win_id }
        )
        vim.api.nvim_set_hl(0, "AugmentChatBorder", { fg = "#a6d189", bold = true })
        vim.api.nvim_set_hl(0, "AugmentChatTitle", { fg = "#74c7ec", bold = true })
        vim.api.nvim_set_hl(0, "AugmentChatFooter", { fg = "#74c7ec", bold = true })

        if augment_buffer_content and #augment_buffer_content > 0 then
          vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, augment_buffer_content)
        end

        -- Add keymapping to send content to Augment
        local function send_to_augment()
          local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
          local content = table.concat(lines, " ")

          -- Clear the buffer content storage
          augment_buffer_content = {}

          -- Send to Augment
          vim.cmd("Augment chat " .. vim.fn.escape(content, '"\\'))
          vim.api.nvim_win_close(win_id, true)
        end

        local function close_window()
          augment_buffer_content = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
          vim.api.nvim_win_close(win_id, true)
        end

        vim.cmd("startinsert")

        vim.keymap.set("n", "<C-y>", function()
          save_to_history(table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n"))
          send_to_augment()
        end, { buffer = bufnr, desc = "Send to Augment" })
        vim.keymap.set("n", "<CR>", function()
          save_to_history(table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n"))
          send_to_augment()
        end, { buffer = bufnr, desc = "Send to Augment" })
        vim.keymap.set("n", "<Esc>", function()
          close_window()
        end, { buffer = bufnr, desc = "Close Augment Chat" })
        vim.keymap.set("n", "q", function()
          close_window()
        end, { buffer = bufnr, desc = "Close Augment Chat" })
        vim.keymap.set("n", "<C-n>", function()
          navigate_history("up")
        end, { buffer = bufnr, desc = "Navigate history up" })
        vim.keymap.set("n", "<C-p>", function()
          navigate_history("down")
        end, { buffer = bufnr, desc = "Navigate history down" })
      end

      vim.keymap.set("n", "<leader>ab", function()
        open_augment_chat_buffer()
      end, { desc = "[A]ugment [B]uffer" })

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

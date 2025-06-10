---@diagnostic disable: missing-fields
return {
  "obsidian-nvim/obsidian.nvim",
  version = "*",
  lazy = true,
  event = "VeryLazy",
  ft = "markdown",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  config = function()
    local opt = vim.opt
    local obsidian = require("obsidian")

    local worksapces = {
      {
        name = "work",
        path = "~/vaults/work",
      },
      {
        name = "TheAbyss",
        path = "~/vaults/TheAbyss",
      },
      {
        name = "personal",
        path = "~/vaults/personal",
      },
    }
    obsidian.setup({
      workspaces = worksapces, -- Optional, by default when you use `:ObsidianFollowLink` on a link to an external
      -- URL it will be ignored but you can customize this behavior here.
      ---@param url string
      follow_url_func = function(url)
        -- Open the URL in the default web browser.
        vim.fn.jobstart({ "open", url }) -- Mac OS
        -- vim.fn.jobstart({"xdg-open", url})  -- linux
        -- vim.cmd(':silent exec "!start ' .. url .. '"') -- Windows
        -- vim.ui.open(url) -- need Neovim 0.10.0+
      end,

      -- Optional, by default when you use `:ObsidianFollowLink` on a link to an image
      -- file it will be ignored but you can customize this behavior here.
      ---@param img string
      follow_img_func = function(img)
        vim.fn.jobstart({ "qlmanage", "-p", img }) -- Mac OS quick look preview
        -- vim.fn.jobstart({"xdg-open", url})  -- linux
        -- vim.cmd(':silent exec "!start ' .. url .. '"') -- Windows
      end,
      templates = {
        folder = "Templates",
        substitutions = {
          IterNum = function()
            return tonumber(require("os").date("%U")) / 2
          end,
        },
      },
      -- see below for full list of options 👇
    })

    opt.conceallevel = 2

    local iter_offset = 1
    local iteration_year = os.date("%Y")
    local current_week = tonumber(os.date("%U"))
    local iteration_num = math.floor(current_week / 2) + iter_offset
    local prior_num = iteration_num - 1
    local retro_filename = "Iter_" .. iteration_num .. "_" .. iteration_year .. ".md"
    local prior_filename = "Iter_" .. prior_num .. "_" .. iteration_year .. ".md"

    vim.keymap.set("n", "-r", function()
      local client = obsidian.get_client()
      local workspace = client.current_workspace

      if not client then
        vim.notify("No active Obsidian workspace", vim.log.levels.WARN)
        return
      end
      if not workspace or not workspace.path then
        vim.notify("Cannot determine current workspce path", vim.log.levels.WARN)
        return
      end

      local full_path = vim.fn.expand(workspace.path.filename .. "/" .. retro_filename)
      local note_exists = vim.fn.filereadable(full_path) == 1

      if note_exists then
        client:open_note(retro_filename)
        vim.notify("Opened existing retrospective for Iteration " .. iteration_num, vim.log.levels.INFO)
      else
        local templates_dir = workspace.path.filename .. "/Templates"
        local retro_template_path = templates_dir .. "/RetroNotes.md"
        local template_exists = vim.fn.filereadable(retro_template_path) == 1

        if template_exists then
          vim.cmd("ObsidianNewFromTemplate " .. retro_filename .. " RetroNotes")
          vim.notify("Created new retrospective for Iteration " .. iteration_num, vim.log.levels.INFO)
        else
          vim.notify(
            'Template for Retrospectives notes not found. Please create a template named "RetroNotes.md" in your templates directory.',
            vim.log.levels.INFO
          )
        end
      end
    end, { desc = "Create/Open Note for current iteration" })

    vim.keymap.set("n", "-R", function()
      local client = obsidian.get_client()
      local workspace = client.current_workspace

      if not client then
        vim.notify("No active Obsidian workspace", vim.log.levels.WARN)
        return
      end
      if not workspace or not workspace.path then
        vim.notify("Cannot determine current workspce path", vim.log.levels.WARN)
        return
      end

      -- Construcvt the full path to the note
      local full_path = vim.fn.expand(workspace.path.filename .. "/" .. prior_filename)
      local note_exists = vim.fn.filereadable(full_path) == 1

      if note_exists then
        client:open_note(prior_filename)
        vim.notify("Opened existing retrospective for Iteration " .. prior_num, vim.log.levels.INFO)
      else
        vim.notify("No note found for previous iteration (" .. prior_num .. ")")
      end
    end, { desc = "Open note for previous iteration" })

    vim.keymap.set("n", "--", "<CMD>ObsidianNew<CR>", { desc = "Open [N]ew Obsidian note" })
    vim.keymap.set("n", "-t", "<CMD>ObsidianToday<CR>", { desc = "Opens a new Obsidian daily for [T]oday" })
    vim.keymap.set("n", "-y", "<CMD>ObsidianYesterday<CR>", { desc = "Opens/Creates a Obsidian daily for [Y]esterday" })
    vim.keymap.set("n", "-/", "<CMD>ObsidianSearch<CR>", { desc = "Obsidian Notes Grep" })
    vim.keymap.set("n", "-w", "<CMD>ObsidianWorkspace<CR>", { desc = "Obsidian Select [W]orkspace" })
    vim.keymap.set("n", "-p", "<CMD>ObsidianNewFromTemplate<CR>", { desc = "Creates a new templated note" })

    -- INFO: Pressing <CR> on any line with text will insert an loop through the checkbox options (As long as you're in a Obsidian workspace)
    vim.keymap.set("n", "-c", "<CMD>ObsidianToggleCheckbox<CR>", { desc = "Obsidian Toggle [C]heckbox" })

    vim.keymap.set("n", "-fl", "<CMD>ObsidianFollowLink<CR>", { desc = "Obsidian [F]ollow [L]ink" })
    vim.keymap.set("v", "<leader>l", "<CMD>ObsidianLink<CR>", { desc = "Obsidian [L]ink" })
    vim.keymap.set("v", "<leader>ln", "<CMD>ObsidianLinkNew<CR>", { desc = "Obsidian [L]ink [N]ew" })
    vim.keymap.set("v", "<leader>e", "<CMD>ObsidianExtractNote<CR>", { desc = "Obsidian [E]xtract Note" })
  end,
}

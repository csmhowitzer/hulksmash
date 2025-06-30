---@class AugmentOpts
---@field inline table|nil Configuration for inline suggestions

local M = {}

local m_utils = require("lib.utils")
local state = require("m_augment.state")
local utils = require("m_augment.utils")
local ui = require("m_augment.ui")
local code = require("m_augment.code")
local inline = require("m_augment.inline")

---Setup the Augment plugin
---@param opts AugmentOpts|nil Configuration options
function M.setup(opts)
  opts = opts or {}
  state.init(opts)
  ui.setup(opts)
  inline.setup(opts.inline or {})
  M.setup_keymaps(opts)
  M.setup_autocmds()
  M.setup_commands()
  vim.g.augment_workspace_folders = utils.ingest_workspaces()
end

---Helper function for setting keymaps
---@param keys string Key combination
---@param func function Function to execute
---@param desc string Description for the keymap
---@param mode string|nil Mode for the keymap (default: "n")
local map = function(keys, func, desc, mode)
  mode = mode or "n"
  vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
end

---Setup keymaps for the Augment plugin
---@param opts AugmentOpts Configuration options
function M.setup_keymaps(opts)
  vim.keymap.set({ "n", "v" }, "<leader>ac", function()
    ui.open_chat_buffer()
  end, { desc = "[A]ugment [C]hat" })
  vim.keymap.set("n", "<leader>an", "<CMD>Augment chat new<CR>", { desc = "[A]ugment Chat [N]ew" })
  vim.keymap.set("n", "<leader>aw", "<CMD>Augment chat-toggle<CR>", { desc = "[A]ugment Chat Toggle [W]indow" })

  -- auth keymaps
  vim.keymap.set("n", "<leader>asi", "<CMD>Augment signin<CR>", { desc = "[A]ugment [S]ign[I]n" })
  vim.keymap.set("n", "<leader>aso", "<CMD>Augment signout<CR>", { desc = "[A]ugment [S]ign[O]ut" })
  vim.keymap.set("n", "<leader>ast", "<CMD>Augment status<CR>", { desc = "[A]ugment [S]tatus" })

  -- Code injection keymap
  -- INFO: will change with new version
  vim.keymap.set("n", "<leader>ai", function()
    code.inject_code(nil, state.get_source_buffer(), state.get_source_file())
  end, { desc = "[A]ugment [I]nject code to original file" })

  -- Force inline suggestion keymap
  vim.keymap.set("n", "<leader>az", function()
    vim.g.augment_force_inline_suggestion = true
    code.inject_code(nil, state.get_source_buffer(), state.get_source_file(), function()
      -- Reset flag after injection is complete
      vim.g.augment_force_inline_suggestion = false
    end)
  end, { desc = "[A]ugment [Z] inline suggestion preview" })

  -- Selection to chat keymap
  vim.keymap.set("v", "<leader>aw", function()
    ui.send_selection_to_chat()
  end, { desc = "[A]ugment [W]ith selection" })

  -- Toggle keymaps
  vim.keymap.set("n", "<leader>atog", function()
    if vim.g.augment_disable_completions == false then
      vim.g.augment_disable_completions = true
      vim.notify("Augment disabled", vim.log.levels.INFO)
    else
      vim.g.augment_disable_completions = false
      vim.notify("Augment enabled", vim.log.levels.INFO)
    end
  end, { desc = "[A]ugment [T]oggle" })

  -- Workspace keymaps
  vim.keymap.set("n", "<leader>alw", function()
    utils.list_workspaces()
  end, { desc = "[A]ugment [L]ist [W]orkspaces" })

  vim.keymap.set("n", "<leader>aaw", function()
    m_utils.confirm_dialog_basic("Do you want to add this path: " .. vim.fn.getcwd(), function(answer)
      if answer == true then
        utils.add_workspace_folder(vim.fn.getcwd())
      end
    end)
  end, { desc = "[A]ugment [A]dd [W]orkspace Path" })

  vim.keymap.set("n", "<leader>aacw", function()
    utils.add_workspace_folder()
  end, { desc = "[A]ugment [A]dd [C]ustom [W]orkspace" })
end

-- Setup autocommands
function M.setup_autocmds()
  vim.api.nvim_create_autocmd("BufEnter", {
    group = vim.api.nvim_create_augroup("AugmentBufferTracking", { clear = true }),
    callback = function()
      state.update_recent_buffers()
    end,
  })
end

function M.setup_commands()
  vim.api.nvim_create_user_command("AugmentDebugBuffers", function()
    state.debug_recent_buffers()
  end, { desc = "Debug Augment recent buffers" })
end

return M

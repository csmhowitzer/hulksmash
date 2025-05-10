local telescope_builtin = require("telescope.builtin")

---@module "omnisharp_ext_utils"
local M = {}

---Checks if OmniSharp LSP is active for the current buffer
---@return boolean True if OmniSharp is active, false otherwise
function M.check_if_omnisharp_is_active()
  local lsp_clients = vim.lsp.get_clients({ bufnr = vim.api.nvim_get_current_buf() })
  for _, c in pairs(lsp_clients) do
    if c.name == "omnisharp" then
      return true
    end
  end
  return false
end

---Checks if OmniSharp LSP is active for the current buffer (local helper function)
---@return boolean True if OmniSharp is active, false otherwise
local function is_omnisharp_active_in_buffer()
  local lsp_clients = vim.lsp.get_clients({ bufnr = vim.api.nvim_get_current_buf() })
  for _, c in pairs(lsp_clients) do
    if c.name == "omnisharp" then
      return true
    end
  end
  return false
end

---Go to definition using either OmniSharp exteneded or standard LSP
---Uses telescope to display results
function M.lsp_definitions()
  if is_omnisharp_active_in_buffer() then
    require("omnisharp_extended").telescope_lsp_definition()
  else
    telescope_builtin.lsp_definitions()
  end
end

---Find references using either OmniSharp extended or standard LSP
---Uses telescope to display results with custom confiuguration when using OmniSharp
function M.lsp_references()
  if is_omnisharp_active_in_buffer() then
    require("omnisharp_extended").telescope_lsp_references(require("telescope.themes").get_ivy({
      excludeDefinition = true,
      show_line = false,
      initial_mode = "normal",
    }))
  else
    telescope_builtin.lsp_references()
  end
end

---Go to type definition using either OmniSharp or standard LSP
---Uses telescope to display results
function M.lsp_type_definitions()
  if is_omnisharp_active_in_buffer() then
    require("omnisharp_extended").telescope_lsp_type_definition()
  else
    telescope_builtin.lsp_type_definitions()
  end
end

---Go to implementaiton using either OmniSharp or standard LSP
---Uses telescope to display results
function M.lsp_implementations()
  if is_omnisharp_active_in_buffer() then
    require("omnisharp_extended").telescope_lsp_implementation()
  else
    telescope_builtin.lsp_implementations()
  end
end

return M

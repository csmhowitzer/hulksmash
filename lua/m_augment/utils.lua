local M = {}
local state = require("m_augment.state")
local utils = require("user.utils")

function M.read_file_content(path)
  local file = io.open(path, "r")
  if not file then
    return ""
  end

  local content = file:read("*all")
  file:close()
  return content
end

function M.file_exists(path)
  local file = io.open(path, "r")
  if file then
    file:close()
    return true
  end
  return false
end

function M.read_workspaces(workspace_path)
  workspace_path = workspace_path or state.config.workspace_path
  local config_path = vim.fn.expand(workspace_path)
  if not M.file_exists(config_path) then
    utils.create_home_dir_if_not_exists(config_path)
  end
  local content = M.read_file_content(config_path)

  local ok, decoded = pcall(vim.json.decode, content)
  return ok and decoded or {}
end

function M.add_workspace_folder(path)
  if path == nil or path == "" then
    path = vim.fn.input("Workspace Path: ")
    if path == "" then
      return
    end
  end

  local name = vim.fn.input("Workspace Name: ")
  if name == "" then
    return
  end

  local add_path = function(wksp)
    wksp = wksp:gsub("\\", "")
    local workspaces = M.read_workspaces()
    if workspaces.workspaces == nil then
      workspaces.workspaces = {}
    end
    table.insert(workspaces.workspaces, {
      name = name,
      path = vim.fn.resolve(wksp),
    })
    local json = vim.json.encode(workspaces)
    local file = io.open(vim.fn.expand(state.config.workspace_path), "w")
    if file then
      file:write(json)
      file:close()
      vim.notify("Workspace added successfully", vim.log.levels.INFO)
    end
  end

  if path ~= nil and path ~= "" then
    path = vim.fn.fnamemodify(path, ":p:~")
    utils.confirm_dialog_basic(string.format("Add (%s) as a workspace path?", path), function(choice)
      if choice then
        add_path(path)
      else
        return
      end
    end)
  end
end

function M.list_workspaces(workspace_path)
  workspace_path = workspace_path or state.config.workspace_path
  local workspaces = M.read_workspaces(workspace_path)
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

function M.ingest_workspaces(workspace_path)
  workspace_path = workspace_path or state.config.workspace_path
  local workspaces = M.read_workspaces(workspace_path) or {}

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

return M

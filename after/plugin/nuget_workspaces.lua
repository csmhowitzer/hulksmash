local utils = require("user.utils")
local nuget_sources_path = "~/.config/nuget/sources.json"

--- Reads the workspaces from the config file.
--- @return any
local read_sources = function()
  local config_path = vim.fn.expand(nuget_sources_path)
  if not utils.file_exists(config_path) then
    utils.create_home_dir_if_not_exists(config_path)

    local default_sources = { sources = {} }
    local file = io.open(config_path, "w")
    if file then
      file:write(vim.json.encode(default_sources))
      file:close()

      add_source("nuget.org", "https://api.nuget.org/v3/index.json")
    end
  end

  local content = utils.read_file_content(config_path)
  local ok, decoded = pcall(vim.json.decode, content)
  return ok and decoded or {}
end

--- Adds a workspace folder.
--- @param url string?
--- @return any
local add_source = function(name, url)
  if name == nil or name == "" then
    name = vim.fn.input("Source Name: ")
  end

  local add_source_internal = function(new_src)
    new_src = new_src:gsub("\\", "")
    local sources = read_sources()
    if sources.sources == nil then
      sources.sources = {}
    end
    table.insert(sources.sources, {
      name = name,
      url = url,
    })
    local json = vim.json.encode(sources)
    local file = io.open(vim.fn.expand(nuget_sources_path), "w")
    if file then
      file:write(json)
      file:close()
      vim.notify("Added new NuGet source: " .. name, vim.log.levels.INFO, { title = "Nuget Soruces Updated" })
    else
      vim.notify("Could not write to source file", vim.log.levels.ERROR)
    end
  end

  if url == nil or url == "" then
    url = vim.fn.input("Source Path: ")
    if url == "" then
      return
    end
  else
    url = vim.fn.fnamemodify(url, ":p:~")
    utils.confirm_dialog(string.format("Add (%s) as a workspace path?", url), function(choice)
      if choice then
        add_source_internal(url)
      else
        return
      end
    end)
  end
end

--- Lists the workspaces.
--- @return any
local list_sources = function()
  local sources = read_sources()
  if sources.sources and #sources.sources > 0 then
    local sources_list = "NuGet Sources:\n"
    for _, source in ipairs(sources.sources) do
      sources_list = sources_list .. "- " .. source.name .. ": " .. source.url .. "\n"
    end
    vim.notify(sources_list, vim.log.levels.INFO, { title = "NuGet Sources" })
  else
    vim.notify("No NuGet sources configured", vim.log.levels.INFO, { title = "NuGet Sources" })
  end
end

vim.keymap.set("n", "<leader>nas", function()
  add_source()
end, { desc = "[N]uget [A]dd [S]ource" })

vim.keymap.set("n", "<leader>nls", function()
  list_sources()
end, { desc = "[N]uget [L]ist [S]ources" })

vim.api.nvim_create_user_command("NugetAddSource", function()
  add_source()
end, { desc = "Add a new NuGet source" })

vim.api.nvim_create_user_command("NugetListSources", function()
  list_sources()
end, { desc = "List all NuGet sources" })

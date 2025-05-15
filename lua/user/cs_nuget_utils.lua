local M = {}

local utils = require("user.utils")
local nuget_sources_path = "~/.config/nuget/sources.json"

--- Reads the NuGet sources from the config file.
--- @return table
function M.read_sources()
  local config_path = vim.fn.expand(nuget_sources_path)

  -- If file doesn't exist, create it with empty structure
  if not utils.file_exists(config_path) then
    utils.create_home_dir_if_not_exists(config_path)

    -- Create empty sources structure
    local default_sources = { sources = {} }
    local file = io.open(config_path, "w")
    if file then
      file:write(vim.json.encode(default_sources))
      file:close()
    end

    return default_sources
  end

  -- Read existing file content
  local content = utils.read_file_content(config_path)
  local ok, decoded = pcall(vim.json.decode, content)
  return ok and decoded or { sources = {} }
end

--- Adds a new NuGet source to the configuration
--- @param name string? Optional name parameter
--- @param url string? Optional URL parameter
--- @return boolean Success status
function M.add_source(name, url)
  -- If name is not provided, prompt for it
  if name == nil or name == "" then
    name = vim.fn.input("Source Name: ")
    if name == "" then
      return false
    end
  end

  -- If URL is not provided, prompt for it
  if url == nil or url == "" then
    url = vim.fn.input("Source URL: ")
    if url == "" then
      return false
    end
  end

  -- Add the source to the configuration
  local sources = M.read_sources()
  if sources.sources == nil then
    sources.sources = {}
  end

  -- Check if source already exists
  for _, source in ipairs(sources.sources) do
    if source.name == name then
      vim.notify("Source with name '" .. name .. "' already exists", vim.log.levels.WARN, { title = "NuGet Sources" })
      return false
    end
  end

  -- Add the new source
  table.insert(sources.sources, {
    name = name,
    url = url,
  })

  -- Write updated sources back to file
  local json = vim.json.encode(sources)
  local file = io.open(vim.fn.expand(nuget_sources_path), "w")
  if file then
    file:write(json)
    file:close()
    vim.notify("Added new NuGet source: " .. name, vim.log.levels.INFO, { title = "NuGet Sources Updated" })
    return true
  else
    vim.notify("Could not write to sources file", vim.log.levels.ERROR)
    return false
  end
end

--- Lists the NuGet sources
--- @return nil
function M.list_sources()
  local sources = M.read_sources()
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

--- Initialize default sources if none exist
local function initialize_default_source()
  local sources = M.read_sources()
  if not sources.sources or #sources.sources == 0 then
    M.add_source("nuget.org", "https://api.nuget.org/v3/index.json")
  end
end

--- Selects a NuGet source and then prompts for a package to add with optional version
--- @return nil
function M.select_source_and_add_package()
  local sources = M.read_sources()
  if not sources.sources or #sources.sources == 0 then
    vim.notify("No NuGet sources configured. Add one first.", vim.log.levels.WARN, {
      title = "NuGet Package Manager",
    })
    return
  end

  -- Add "Default" as the first option
  local source_names = { "Default (nuget.org)" }
  for _, source in ipairs(sources.sources) do
    table.insert(source_names, source.name)
  end

  vim.ui.select(source_names, {
    prompt = "Select NuGet Source",
  }, function(selected_source)
    if not selected_source then
      return
    end

    -- Get package name
    vim.ui.input({ prompt = "Package name: " }, function(package_name)
      if not package_name or package_name == "" then
        return
      end

      -- Ask if user wants to specify a version
      vim.ui.select({ "Latest version", "Specify version" }, {
        prompt = "Version selection",
      }, function(version_choice)
        if not version_choice then
          return
        end

        local cmd = { "dotnet", "add", utils.find_proj_root(), "package", package_name }

        -- Add version if specified
        if version_choice == "Specify version" then
          vim.ui.input({ prompt = "Package version: " }, function(version)
            if not version or version == "" then
              return
            end

            table.insert(cmd, "--version")
            table.insert(cmd, version)

            -- Add source if not default
            if selected_source ~= "Default (nuget.org)" then
              local source_url = ""
              for _, source in ipairs(sources.sources) do
                if source.name == selected_source then
                  source_url = source.url
                  break
                end
              end

              table.insert(cmd, "--source")
              table.insert(cmd, source_url)
            end

            utils.execute_cmd(cmd)
          end)
        else
          -- No version specified, just add source if not default
          if selected_source ~= "Default (nuget.org)" then
            local source_url = ""
            for _, source in ipairs(sources.sources) do
              if source.name == selected_source then
                source_url = source.url
                break
              end
            end

            table.insert(cmd, "--source")
            table.insert(cmd, source_url)
          end

          utils.execute_cmd(cmd)
        end
      end)
    end)
  end)
end

-- Setup function to create keymaps and commands
function M.setup()
  -- Initialize default sources
  initialize_default_source()

  -- Add keymaps for source management
  vim.keymap.set("n", "<leader>dnas", function()
    M.add_source()
  end, { desc = "[D]ot[N]et [A]dd Nuget [S]ource" })

  vim.keymap.set("n", "<leader>dnls", function()
    M.list_sources()
  end, { desc = "[D]ot[N]et [L]ist [N]uget [S]ources" })

  -- Add keymaps for package management
  vim.keymap.set("n", "<leader>dnap", function()
    M.select_source_and_add_package()
  end, { desc = "[D]ot[N]et [A]dd [P]ackage" })

  -- Add user commands for source management
  vim.api.nvim_create_user_command("CSAddNugetSource", function()
    M.add_source()
  end, { desc = "Add a new NuGet source" })

  vim.api.nvim_create_user_command("CSListNugetSources", function()
    M.list_sources()
  end, { desc = "List all NuGet sources" })

  -- Add user commands for package management
  vim.api.nvim_create_user_command("CSAddPackage", function()
    M.select_source_and_add_package()
  end, { desc = "Add a NuGet package with source and version options" })
end

return M

---@class CSKeymaps
---@field setup function Setup C# keymaps and commands
local M = {}

-- Dependencies
local utils = require("lib.utils")
local cs_build = require("lib.cs_build")

-- Delegate build functions to cs_build module
M.build_solution = cs_build.build_solution
M.rebuild_solution = cs_build.rebuild_solution
M.clean_solution = cs_build.clean_solution
M.build_project = cs_build.build_project
M.rebuild_project = cs_build.rebuild_project
M.clean_project = cs_build.clean_project
M.get_version_info = cs_build.get_version_info

---Formats the selected list item
---@param selected string The list item
---@return string
local function format_selection(selected)
  local list = vim.split(selected, "/")
  local updated = string.gsub(list[#list], ".csproj", "")
  return updated
end

---Opens a list of C# projects to add as a reference to the current project
local function select_cs_proj_ref()
  local root = utils.find_sln_root()
  if root == nil then
    return
  end
  local files = vim.fs.find(function(name)
    return name:match("%.csproj$") ~= nil
  end, { limit = math.huge, type = "file", path = root })
  vim.ui.select(files, {
    prompt = "Select C# Project",
    format_item = function(item)
      return format_selection(item)
    end,
  }, function(selected)
    if selected then
      local projName = format_selection(selected)
      utils.set_cwd()
      local addProjRefCmd = { "dotnet", "add", "reference", "../" .. projName .. "/" .. projName .. ".csproj" }
      -- Note: This would need executeCmd from cs_build, but keeping it simple for now
      vim.notify("Project reference functionality needs executeCmd from cs_build", vim.log.levels.INFO)
    end
  end)
end

---Setup C# keymaps and commands
---@param opts? table Optional configuration table
function M.setup(opts)
  opts = opts or {}
  
  -- Solution level keymaps (F4-F6: build, rebuild, clean)
  vim.keymap.set("n", "<F4>", M.build_solution, { desc = "Build Solution" })
  vim.keymap.set("n", "<F5>", M.rebuild_solution, { desc = "Rebuild Solution" })
  vim.keymap.set("n", "<F6>", M.clean_solution, { desc = "Clean Solution" })

  -- Project level keymaps (F7-F9: build, rebuild, clean)
  vim.keymap.set("n", "<F7>", M.build_project, { desc = "Build Project" })
  vim.keymap.set("n", "<F8>", M.rebuild_project, { desc = "Rebuild Project" })
  vim.keymap.set("n", "<F9>", M.clean_project, { desc = "Clean Project" })

  -- C#-specific keymaps (only active in .cs/.csproj/.sln files)
  vim.api.nvim_create_autocmd({ "BufEnter", "FileType" }, {
    group = vim.api.nvim_create_augroup("CS_Only_Keymaps", {
      clear = true,
    }),
    pattern = { "*.cs", "*.csproj", "*.sln" },
    callback = function()
      vim.keymap.set("n", "<leader>dbg", function()
        require("csharp").debug_project()
      end, { desc = "[D]e[b]u[g] project" })
      vim.keymap.set("n", "<leader>drp", function()
        select_cs_proj_ref()
      end, { desc = "[D]otnet [P]roject [R]eference" })
    end,
  })

  -- Solution level build commands
  vim.api.nvim_create_user_command("CSBuildSln", M.build_solution, { 
    desc = "Build solution" 
  })
  vim.api.nvim_create_user_command("CSRebuildSln", M.rebuild_solution, { 
    desc = "Rebuild solution" 
  })
  vim.api.nvim_create_user_command("CSCleanSln", M.clean_solution, { 
    desc = "Clean solution" 
  })

  -- Project level build commands
  vim.api.nvim_create_user_command("CSBuildProj", M.build_project, { 
    desc = "Build current project" 
  })
  vim.api.nvim_create_user_command("CSRebuildProj", M.rebuild_project, { 
    desc = "Rebuild current project" 
  })
  vim.api.nvim_create_user_command("CSCleanProj", M.clean_project, { 
    desc = "Clean current project" 
  })

  -- Quickfix list command
  vim.api.nvim_create_user_command("CSQuickfix", function()
    local qf_list = vim.fn.getqflist()
    if #qf_list > 0 then
      vim.cmd("copen")
      vim.notify("Opened quickfix list with " .. #qf_list .. " items", vim.log.levels.INFO, {
        title = "C# Quickfix",
        timeout = 3000,
      })
    else
      vim.notify("No build issues in quickfix list", vim.log.levels.INFO, {
        title = "C# Quickfix",
        timeout = 3000,
      })
    end
  end, { desc = "Open C# build quickfix list" })

  -- Build output toggle command
  vim.api.nvim_create_user_command("CSBuildOutput", function(opts)
    local arg = opts.args:lower()
    
    if arg == "on" then
      cs_build.show_build_output = true
      vim.notify("Build output notifications enabled", vim.log.levels.INFO, {
        title = "C# Build Output",
        timeout = 3000,
      })
    elseif arg == "off" then
      cs_build.show_build_output = false
      vim.notify("Build output notifications disabled", vim.log.levels.INFO, {
        title = "C# Build Output", 
        timeout = 3000,
      })
    else
      -- Toggle
      cs_build.show_build_output = not cs_build.show_build_output
      local status = cs_build.show_build_output and "enabled" or "disabled"
      vim.notify("Build output notifications " .. status, vim.log.levels.INFO, {
        title = "C# Build Output",
        timeout = 3000,
      })
    end
  end, { 
    desc = "Toggle build output notifications (on/off/toggle)",
    nargs = "?",
    complete = function() return {"on", "off"} end
  })

  -- Version info command
  vim.api.nvim_create_user_command("CSVersion", M.get_version_info, { 
    desc = "Show C# and .NET version information" 
  })

  -- Language-specific help command (pattern for other languages)
  vim.api.nvim_create_user_command("CSHelp", function()
    print("=== C# Development Tools ===")
    print("")
    print("# Build Keymaps (Logical grouping):")
    print("  Solution: F4=Build, F5=Rebuild, F6=Clean")
    print("  Project:  F7=Build, F8=Rebuild, F9=Clean")
    print("")
    print("  <F4>     - Build Solution")
    print("  <F5>     - Rebuild Solution")
    print("  <F6>     - Clean Solution")
    print("  <F7>     - Build Project")
    print("  <F8>     - Rebuild Project")
    print("  <F9>     - Clean Project")
    print("")
    print("# Refactoring Keymaps (LSP-based):")
    print("  <leader>crn  - Rename symbol")
    print("  <leader>crm  - Extract Method")
    print("  <leader>crc  - Extract Constant (shows error on escape, but works)")
    print("")
    print("# Build Commands:")
    print("  :CSBuildSln    - Build solution")
    print("  :CSRebuildSln  - Rebuild solution")
    print("  :CSCleanSln    - Clean solution")
    print("  :CSBuildProj   - Build current project")
    print("  :CSRebuildProj - Rebuild current project")
    print("  :CSCleanProj   - Clean current project")
    print("")
    print("# Utility Commands:")
    print("  :CSVersion     - Show C# and .NET version info")
    print("  :CSQuickfix    - Open build issues quickfix list")
    print("  :CSBuildOutput [on|off] - Toggle real-time build output notifications")
    print("  :CSHelp        - Show this help")
    print("")
    print("# Debug Commands:")
    print("  :CSDebug       - Test module functionality")
    print("")
    print("# Quickfix Integration:")
    print("  • Build errors/warnings automatically populate quickfix list")
    print("  • Errors auto-open quickfix, warnings show notification")
    print("  • Use your existing navigation keymaps for quickfix")
    
    vim.notify("C# development tools help displayed in command line", vim.log.levels.INFO, { 
      title = "C# Help",
      timeout = 3000
    })
  end, { desc = "Show C# development tools help" })

  -- Debug command (separate from help)
  vim.api.nvim_create_user_command("CSDebug", function()
    vim.notify("C# Keymaps module is loaded and working!", vim.log.levels.INFO, { 
      title = "CS Debug",
      timeout = 3000
    })
    M.build_solution() -- Test functionality
  end, { desc = "Debug C# keymaps functionality" })

  -- Debug quickfix command
  vim.api.nvim_create_user_command("CSDebugQuickfix", function()
    local qf_list = vim.fn.getqflist()
    print("=== Quickfix Debug ===")
    print("Total entries: " .. #qf_list)
    
    local seen_keys = {}
    local duplicates = 0
    
    for i, entry in ipairs(qf_list) do
      local file_basename = entry.filename and entry.filename:match("([^/]+)$") or "unknown"
      local key = string.format("%s:%s:%s", file_basename, entry.lnum, entry.col)
      
      if seen_keys[key] then
        duplicates = duplicates + 1
        print(string.format("DUPLICATE %d: %s", i, key))
      else
        seen_keys[key] = true
      end
    end
    
    print("Duplicates found: " .. duplicates)
    print("Unique entries: " .. (#qf_list - duplicates))
    print("===================")
  end, { desc = "Debug quickfix list for duplicates" })
end

return M

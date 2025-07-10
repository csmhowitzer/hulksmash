---@class CSKeymaps
---@field setup function
---@field build_solution function
---@field rebuild_solution function
---@field clean_solution function
---@field build_project function
---@field rebuild_project function
---@field clean_project function
---@field get_version_info function
local M = {}

-- Dependencies
local utils = require("lib.utils")

-- Module state
M.show_build_output = false -- Toggle for showing real-time build output

---Parse C# build output into quickfix entries
---@param lines table Array of output lines
---@return table Array of quickfix entries
local function parse_build_output_to_quickfix(lines)
  local quickfix_entries = {}
  local seen_entries = {} -- Track duplicates

  for _, line in ipairs(lines) do
    -- Parse C# compiler error/warning format:
    -- /path/to/file.cs(line,col): error/warning CODE: message [project.csproj]
    local file, line_num, col_num, type, code, message = line:match("^%s*(.-)%((%d+),(%d+)%):%s*(%w+)%s+([^:]+):%s*(.+)")

    if file and line_num and type and message then
      -- Clean up the file path (remove leading whitespace)
      file = file:gsub("^%s+", "")

      -- Remove project reference from end of message if present
      message = message:gsub("%s*%[.-%]%s*$", "")

      -- Determine if it's an error or warning
      local is_error = type:lower() == "error"
      local entry_type = is_error and "E" or "W"

      -- Create unique key to avoid duplicates using file basename, position, and error code
      local file_basename = file:match("([^/]+)$") or file -- Get just the filename
      local unique_key = string.format("%s:%s:%s:%s", file_basename, line_num, col_num, code or "")

      if not seen_entries[unique_key] then
        seen_entries[unique_key] = true

        table.insert(quickfix_entries, {
          filename = file,
          lnum = tonumber(line_num),
          col = tonumber(col_num) or 1,
          text = string.format("[%s%s] %s", entry_type, code or "", message),
          type = entry_type,
          valid = 1,
        })
      end
    end
  end

  return quickfix_entries
end

---Populate quickfix list with build errors and warnings
---@param stdout_lines table Array of stdout lines
---@param stderr_lines table Array of stderr lines
---@param operation_name string Name of the build operation
local function populate_quickfix_list(stdout_lines, stderr_lines, operation_name)
  -- Combine all output lines for parsing (with deduplication)
  local all_lines = {}

  -- Add stdout lines
  for _, line in ipairs(stdout_lines) do
    table.insert(all_lines, line)
  end

  -- Add stderr lines
  for _, line in ipairs(stderr_lines) do
    table.insert(all_lines, line)
  end

  -- Parse into quickfix entries (with built-in deduplication)
  local quickfix_entries = parse_build_output_to_quickfix(all_lines)

  local error_count = 0
  local warning_count = 0

  if #quickfix_entries > 0 then
    -- Set the quickfix list
    vim.fn.setqflist(quickfix_entries, 'r')

    -- Count errors vs warnings
    for _, entry in ipairs(quickfix_entries) do
      if entry.type == "E" then
        error_count = error_count + 1
      else
        warning_count = warning_count + 1
      end
    end

    -- Auto-open quickfix if there are errors
    if error_count > 0 then
      vim.cmd("copen")
    end
  else
    -- Clear quickfix list if no issues found
    vim.fn.setqflist({}, 'r')
  end

  -- Return counts for use in completion notification
  return error_count, warning_count
end

-- Dotnet CLI commands
local buildSlnCmd = { "dotnet", "build" }
local cleanSlnCmd = { "dotnet", "msbuild", "-t:clean" }
local rebuildSlnCmd = { "dotnet", "msbuild", "-t:rebuild" }
local addPackageCmd =
  { "dotnet", "add", "[PROJECT]", "package", "<package name>", "-s", "<source url>", "-v", "<version>" }
local addProjRefCmd = { "dotnet", "add", "reference", "[PROJECT_PATH]" }

-- NOTE: This is the dotnet sdk flavor of Clean/Rebuild as this command is not directly present in
-- the current dotnet sdk
--local rebuildSlnCmd = { 'dotnet', 'build', '--no-incremental' }

---Formats the text to be displayed by the notify popup
---@param data any Console output from the command
---@return string
local function formatText(data)
  local ret = ""
  for _, t in pairs(data) do
    ret = ret .. "\n" .. t
  end
  return ret
end

---Commands that will be run after the dotnet command is called
---@param reloadBuf boolean Whether to reload buffer and restart LSP
local function run_on_exit(reloadBuf)
  if reloadBuf then
    vim.cmd([[e]])
    vim.cmd([[LspRestart]])
  end
end

---Runs the specified dotnet sdk command with proper notification management
---@param command table Dotnet command as table of strings
---@param reloadBuf boolean Whether to reload buffer after command
---@param operation_name string Name of the operation for progress display
---@param on_complete? function Optional callback when operation completes
local function dotnetCmd(command, reloadBuf, operation_name, on_complete)
  operation_name = operation_name or "DotNet Operation"

  local start_time = vim.loop.hrtime()
  local all_stdout = {}
  local all_stderr = {}
  local has_shown_progress = false
  local progress_notif_id = "dotnet_build_" .. operation_name:gsub(" ", "_"):lower()

  -- Show start notification with unique ID
  vim.notify("🔄 " .. operation_name .. " starting...", vim.log.levels.INFO, {
    title = "DotNet CLI",
    timeout = false, -- Will be replaced by completion
    id = progress_notif_id,
  })

  vim.fn.jobstart(command, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if data and #data > 0 and data[1] ~= "" then
        -- Capture all stdout for potential quickfix use
        for _, line in ipairs(data) do
          if line ~= "" then
            table.insert(all_stdout, line)
          end
        end

        -- Show real-time output if enabled
        if M.show_build_output then
          vim.notify(formatText(data), vim.log.levels.INFO, {
            title = 'DotNet CLI Output',
            timeout = 5000,
          })
        end

        -- Update to progress notification (only once)
        if not has_shown_progress then
          has_shown_progress = true
          vim.notify("🔄 " .. operation_name .. " in progress...", vim.log.levels.INFO, {
            title = "DotNet CLI",
            timeout = false, -- Will be replaced by completion
            id = progress_notif_id,
          })
        end
      end
    end,
    on_stderr = function(_, data)
      if data and #data > 0 and data[1] ~= "" then
        -- Capture all stderr for potential quickfix use
        for _, line in ipairs(data) do
          if line ~= "" then
            table.insert(all_stderr, line)
          end
        end

        -- Show real-time errors if enabled
        if M.show_build_output then
          vim.notify(formatText(data), vim.log.levels.WARN, {
            title = 'DotNet CLI Errors',
            timeout = 8000,
          })
        end
      end
    end,
    on_exit = function(_, exit_code)
      local end_time = vim.loop.hrtime()
      local duration = math.floor((end_time - start_time) / 1000000) -- Convert to milliseconds
      local duration_str = string.format("%.1fs", duration / 1000)

      -- Prepare output summary
      local stdout_count = #all_stdout
      local stderr_count = #all_stderr
      local has_errors = stderr_count > 0 or exit_code ~= 0

      -- Store output for optional viewing (don't show as notification)
      -- Output is available via quickfix list and optional commands

      -- Populate quickfix list and get issue counts
      local error_count, warning_count = populate_quickfix_list(all_stdout, all_stderr, operation_name)

      -- Show final result with quickfix info (will replace any existing progress notification)
      local final_timeout = 4000
      if exit_code == 0 then
        local success_msg = "✅ " .. operation_name .. " completed successfully (" .. duration_str .. ")"
        if warning_count > 0 then
          success_msg = success_msg .. "\n📋 Quickfix: " .. warning_count .. " warnings"
        end
        vim.notify(success_msg, vim.log.levels.INFO, {
          title = "DotNet CLI Success",
          timeout = final_timeout,
          id = progress_notif_id, -- Replace progress notification
        })
      else
        local error_msg = "❌ " .. operation_name .. " failed (exit code: " .. exit_code .. ") (" .. duration_str .. ")"
        if error_count > 0 or warning_count > 0 then
          error_msg = error_msg .. "\n📋 Quickfix: " .. error_count .. " errors, " .. warning_count .. " warnings"
        end
        vim.notify(error_msg, vim.log.levels.ERROR, {
          title = "DotNet CLI Error",
          timeout = final_timeout,
          id = progress_notif_id, -- Replace progress notification
        })
      end

      -- Run completion callback with captured output
      if on_complete then
        on_complete(exit_code, duration_str, all_stdout, all_stderr)
      end

      run_on_exit(reloadBuf)
    end,
  })
end

---Executes the input command if in a C# file
---@param command table The dotnet command to run, each word is an item in the table
---@param reloadBuf? boolean Reloads the buffer after the command executes
---@param operation_name? string Name of the operation for progress display
---@param on_complete? function Optional callback when operation completes
local function executeCmd(command, reloadBuf, operation_name, on_complete)
  local bufnr = vim.api.nvim_get_current_buf()
  local type = vim.filetype.match({ buf = bufnr })

  if type == "cs" then
    dotnetCmd(command, reloadBuf, operation_name, on_complete)
  else
    vim.notify("Not in a C# file (current filetype: " .. (type or "unknown") .. ")", vim.log.levels.WARN, {
      title = "C# Command",
      timeout = 3000,
    })
  end
end

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
      addProjRefCmd[4] = "../" .. projName .. "/" .. projName .. ".csproj"
      executeCmd(addProjRefCmd)
    end
  end)
end

---Adds a line to the project file
---@param projPath string Path to the project file
---@param line string Line to add to the project file
local function add_to_proj_file(projPath, line)
  local f = utils.read_file_content(projPath)
  if not f then
    return
  end

  local itemGroupExists = f:match("<ItemGroup>")
  local newContent
  if itemGroupExists then
    newContent = f:gsub("</ItemGroup>", line .. "\n  </ItemGroup>", 1)
  else
    newContent = f:gsub("</Project>", "  <ItemGroup>\n    " .. line .. "\n  </ItemGroup>\n</Project>")
  end
  f = io.open(projPath, "w")
  if f then
    f:write(newContent)
    f:close()
    vim.notify("Added line to project file", vim.log.levels.INFO, {
      title = "Project File Updated",
    })
  end
end

---Adds a protobuf file to the project
---@param name string Name of the protobuf file
---@param service string Service type (Server, Client, Both)
local function add_proto_to_proj(name, service)
  local projPath = utils.find_proj_root()
  if projPath then
    add_to_proj_file(projPath, '<Protobuf Include="Protos\\' .. name .. '.proto" GrpcServices="' .. service .. '" />')
  end
end

-- Public API functions
---Build the solution
function M.build_solution()
  executeCmd(buildSlnCmd, false, "Solution Build", function(exit_code, duration, stdout_lines, stderr_lines)
    -- Additional callback logic can be added here if needed
    local total_output = #stdout_lines + #stderr_lines
    if exit_code == 0 and total_output > 10 then
      vim.notify("Build completed with " .. total_output .. " output lines", vim.log.levels.INFO, {
        title = "Build Summary",
        timeout = 3000,
      })
    end
  end)
end

---Rebuild the solution
function M.rebuild_solution()
  executeCmd(rebuildSlnCmd, false, "Solution Rebuild", function(exit_code, duration, stdout_lines, stderr_lines)
    -- Additional callback logic for rebuild
    if exit_code == 0 then
      vim.notify("Rebuild completed - all artifacts refreshed", vim.log.levels.INFO, {
        title = "Rebuild Summary",
        timeout = 3000,
      })
    end
  end)
end

---Clean the solution
function M.clean_solution()
  executeCmd(cleanSlnCmd, false, "Solution Clean", function(exit_code, duration, stdout_lines, stderr_lines)
    -- Additional callback logic for clean
    if exit_code == 0 then
      vim.notify("Clean completed - build artifacts removed", vim.log.levels.INFO, {
        title = "Clean Summary",
        timeout = 3000,
      })
    end
  end)
end

---Build the current project
function M.build_project()
  local projPath = utils.find_proj_root()
  if projPath then
    local projCmd = { "dotnet", "build", projPath }
    executeCmd(projCmd, false, "Project Build", function(exit_code, duration, stdout_lines, stderr_lines)
      if exit_code == 0 then
        local proj_name = vim.fn.fnamemodify(projPath, ":t:r") -- Get project name without extension
        vim.notify("Project '" .. proj_name .. "' built successfully", vim.log.levels.INFO, {
          title = "Project Build Summary",
          timeout = 3000,
        })
      end
    end)
  else
    vim.notify("No project file found", vim.log.levels.WARN, { title = "C# Build" })
  end
end

---Rebuild the current project
function M.rebuild_project()
  local projPath = utils.find_proj_root()
  if projPath then
    local projCmd = { "dotnet", "msbuild", "-t:rebuild", projPath }
    executeCmd(projCmd, false, "Project Rebuild", function(exit_code, duration, stdout_lines, stderr_lines)
      if exit_code == 0 then
        local proj_name = vim.fn.fnamemodify(projPath, ":t:r")
        vim.notify("Project '" .. proj_name .. "' rebuilt successfully", vim.log.levels.INFO, {
          title = "Project Rebuild Summary",
          timeout = 3000,
        })
      end
    end)
  else
    vim.notify("No project file found", vim.log.levels.WARN, { title = "C# Build" })
  end
end

---Clean the current project
function M.clean_project()
  local projPath = utils.find_proj_root()
  if projPath then
    local projCmd = { "dotnet", "msbuild", "-t:clean", projPath }
    executeCmd(projCmd, false, "Project Clean", function(exit_code, duration, stdout_lines, stderr_lines)
      if exit_code == 0 then
        local proj_name = vim.fn.fnamemodify(projPath, ":t:r")
        vim.notify("Project '" .. proj_name .. "' cleaned successfully", vim.log.levels.INFO, {
          title = "Project Clean Summary",
          timeout = 3000,
        })
      end
    end)
  else
    vim.notify("No project file found", vim.log.levels.WARN, { title = "C# Build" })
  end
end

---Get C# and .NET version information
function M.get_version_info()
  -- Get .NET version
  vim.fn.jobstart({ "dotnet", "--version" }, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      local dotnet_version = data[1] or "Unknown"

      -- Get C# version (requires checking project file or global.json)
      vim.fn.jobstart({ "dotnet", "--list-sdks" }, {
        stdout_buffered = true,
        on_stdout = function(_, sdk_data)
          local sdk_info = sdk_data[1] or "Unknown"
          local csharp_version = "Unknown"

          -- Parse C# version from SDK version (approximate mapping)
          if sdk_info:match("8%.") then
            csharp_version = "C# 12"
          elseif sdk_info:match("7%.") then
            csharp_version = "C# 11"
          elseif sdk_info:match("6%.") then
            csharp_version = "C# 10"
          else
            csharp_version = "C# (check project file)"
          end

          local version_info = string.format("%s | .NET %s", csharp_version, dotnet_version)
          vim.notify(version_info, vim.log.levels.INFO, {
            title = "C# & .NET Version",
            timeout = 5000
          })
        end,
      })
    end,
  })
end

---Setup C# keymaps and commands
---@param opts? table Optional configuration table
function M.setup(opts)
  opts = opts or {}



  -- Solution level keymaps (Visual Studio style)
  vim.keymap.set("n", "<F5>", M.build_solution, { desc = "Build Solution" })
  vim.keymap.set("n", "<S-F5>", M.rebuild_solution, { desc = "Rebuild Solution" })
  vim.keymap.set("n", "<C-F5>", M.clean_solution, { desc = "Clean Solution" })

  -- Project level keymaps
  vim.keymap.set("n", "<F6>", M.build_project, { desc = "Build Project" })
  vim.keymap.set("n", "<S-F6>", M.rebuild_project, { desc = "Rebuild Project" })
  vim.keymap.set("n", "<C-F6>", M.clean_project, { desc = "Clean Project" })

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

  -- User commands for protobuf management
  vim.api.nvim_create_user_command("CSAddProtoByName", function()
    vim.ui.input({ prompt = "Protobuf name: " }, function(input)
      vim.ui.select({ "Server", "Client", "Both" }, {
        prompt = "Select Service Type",
      }, function(selected)
        if selected then
          add_proto_to_proj(input, selected)
        end
      end)
    end)
  end, { desc = "Add a proto file to the C# project" })

  vim.api.nvim_create_user_command("CSAddProtoByBuf", function()
    local bufName = utils.get_current_filename()
    vim.ui.select({ "Server", "Client", "Both" }, {
      prompt = "Select Service Type",
    }, function(selected)
      if selected then
        add_proto_to_proj(bufName, selected)
      end
    end)
  end, { desc = "Add a proto file to the C# project" })

  vim.api.nvim_create_user_command("CSAddProtoByBufServer", function()
    local bufName = utils.get_current_filename()
    add_proto_to_proj(bufName, "Server")
  end, { desc = "Add a proto file to the C# project" })

  vim.api.nvim_create_user_command("CSAddProtoByBufClient", function()
    local bufName = utils.get_current_filename()
    add_proto_to_proj(bufName, "Client")
  end, { desc = "Add a proto file to the C# project" })

  vim.api.nvim_create_user_command("CSAddProtoByBufBoth", function()
    local bufName = utils.get_current_filename()
    add_proto_to_proj(bufName, "Both")
  end, { desc = "Add a proto file to the C# project" })

  -- Language-specific help command (pattern for other languages)
  vim.api.nvim_create_user_command("CSHelp", function()
    print("=== C# Development Tools ===")
    print("")
    print("🔧 Build Keymaps (Visual Studio style):")
    print("  <F5>     - Build Solution")
    print("  <S-F5>   - Rebuild Solution")
    print("  <C-F5>   - Clean Solution")
    print("  <F6>     - Build Project")
    print("  <S-F6>   - Rebuild Project")
    print("  <C-F6>   - Clean Project")
    print("")
    print("📋 Build Commands:")
    print("  :CSBuildSln    - Build solution")
    print("  :CSRebuildSln  - Rebuild solution")
    print("  :CSCleanSln    - Clean solution")
    print("  :CSBuildProj   - Build current project")
    print("  :CSRebuildProj - Rebuild current project")
    print("  :CSCleanProj   - Clean current project")
    print("")
    print("ℹ️  Utility Commands:")
    print("  :CSVersion     - Show C# and .NET version info")
    print("  :CSQuickfix    - Open build issues quickfix list")
    print("  :CSBuildOutput [on|off] - Toggle real-time build output notifications")
    print("  :CSHelp        - Show this help")
    print("")
    print("🧪 Debug Commands:")
    print("  :CSDebug       - Test module functionality")
    print("")
    print("📋 Quickfix Integration:")
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



  -- Version info command
  vim.api.nvim_create_user_command("CSVersion", M.get_version_info, {
    desc = "Show C# and .NET version information"
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

  -- Build output toggle command
  vim.api.nvim_create_user_command("CSBuildOutput", function(opts)
    local arg = opts.args:lower()

    if arg == "on" then
      M.show_build_output = true
      vim.notify("Build output notifications enabled", vim.log.levels.INFO, {
        title = "C# Build Output",
        timeout = 3000,
      })
    elseif arg == "off" then
      M.show_build_output = false
      vim.notify("Build output notifications disabled", vim.log.levels.INFO, {
        title = "C# Build Output",
        timeout = 3000,
      })
    else
      -- Toggle
      M.show_build_output = not M.show_build_output
      local status = M.show_build_output and "enabled" or "disabled"
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

  -- Setup nuget utilities
  local nuget_utils = require("lib.cs_nuget_utils")
  nuget_utils.setup()
end

return M

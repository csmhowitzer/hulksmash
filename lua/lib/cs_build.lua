---@class CSBuild
---@field show_build_output boolean Toggle for showing real-time build output
---@field build_solution function Build the solution
---@field rebuild_solution function Rebuild the solution
---@field clean_solution function Clean the solution
---@field build_project function Build the current project
---@field rebuild_project function Rebuild the current project
---@field clean_project function Clean the current project
---@field get_version_info function Get C# and .NET version information
local M = {}

-- Dependencies
local utils = require("lib.utils")

-- Module state
M.show_build_output = false -- Toggle for showing real-time build output

-- Spinner animation frames
local spinner_frames = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }

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
---@return number, number Error count, warning count
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

---Format text data from jobstart output
---@param data table Array of strings from stdout/stderr
---@return string Formatted text
local function formatText(data)
  if not data or #data == 0 then
    return ""
  end
  
  local result = {}
  for _, line in ipairs(data) do
    if line and line ~= "" then
      table.insert(result, line)
    end
  end
  
  return table.concat(result, "\n")
end

---Reload buffer after command execution
---@param reloadBuf boolean Whether to reload the buffer
local function run_on_exit(reloadBuf)
  if reloadBuf then
    vim.cmd("edit!")
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

  -- Spinner and timer state
  local spinner_index = 1
  local progress_timer = nil

  -- Show start notification with unique ID
  vim.notify(spinner_frames[1] .. " " .. operation_name .. " starting...", vim.log.levels.INFO, {
    title = "DotNet CLI",
    timeout = false, -- Will be replaced by completion
    id = progress_notif_id,
  })

  -- Start animated progress timer immediately
  progress_timer = vim.loop.new_timer()
  progress_timer:start(250, 50, vim.schedule_wrap(function() -- 250ms delay, then 50ms interval
    -- Update spinner frame
    spinner_index = (spinner_index % #spinner_frames) + 1

    -- Calculate elapsed time
    local current_time = vim.loop.hrtime()
    local elapsed_ms = (current_time - start_time) / 1000000
    local elapsed_str = string.format("%.1fs", elapsed_ms / 1000)

    -- Determine message based on progress state
    local message = has_shown_progress and " in progress... " or " starting... "

    -- Update notification with spinner and timer
    vim.notify(spinner_frames[spinner_index] .. " " .. operation_name .. message .. "(" .. elapsed_str .. ")", vim.log.levels.INFO, {
      title = "DotNet CLI",
      timeout = false, -- Will be replaced by completion
      id = progress_notif_id,
    })
  end))
  
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
        
        -- Mark that we've received output (changes message from "starting" to "in progress")
        if not has_shown_progress then
          has_shown_progress = true
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
      
      -- Output is captured for quickfix list - no verbose notifications needed
      
      -- Stop progress timer if running
      if progress_timer then
        progress_timer:stop()
        progress_timer:close()
        progress_timer = nil
      end

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

---Executes the input command if in a C# solution/project context
---@param command table The dotnet command to run, each word is an item in the table
---@param reloadBuf? boolean Reloads the buffer after the command executes
---@param operation_name? string Name of the operation for progress display
---@param on_complete? function Optional callback when operation completes
local function executeCmd(command, reloadBuf, operation_name, on_complete)
  -- Check if we're in a C# solution/project context
  local sln_root = utils.find_sln_root()
  local proj_root = utils.find_proj_root()

  if sln_root or proj_root then
    dotnetCmd(command, reloadBuf, operation_name, on_complete)
  else
    vim.notify("Not in a C# solution or project directory", vim.log.levels.WARN, {
      title = "C# Command",
      timeout = 3000,
    })
  end
end

-- Build commands are now constructed dynamically with specific solution/project files

---Build the solution
function M.build_solution()
  local slnPath = utils.find_sln_root()
  if slnPath then
    -- Find the .sln file in the solution directory
    local sln_files = vim.fs.find(function(name) return name:match("%.sln$") end, {
      limit = 1,
      type = "file",
      path = slnPath
    })

    if #sln_files > 0 then
      local sln_file = sln_files[1]
      local sln_name = vim.fn.fnamemodify(sln_file, ":t:r") -- Get solution name without extension
      local buildCmd = { "dotnet", "build", sln_file }

      executeCmd(buildCmd, false, "Solution Build (" .. sln_name .. ")", function(exit_code, duration, stdout_lines, stderr_lines)
        -- Additional callback logic can be added here if needed
        local total_output = #stdout_lines + #stderr_lines
        if exit_code == 0 and total_output > 10 then
          vim.notify("Build completed with " .. total_output .. " output lines", vim.log.levels.INFO, {
            title = "Build Summary",
            timeout = 3000,
          })
        end
      end)
    else
      vim.notify("No solution file found in " .. slnPath, vim.log.levels.WARN, { title = "C# Build" })
    end
  else
    vim.notify("No solution directory found", vim.log.levels.WARN, { title = "C# Build" })
  end
end

---Rebuild the solution
function M.rebuild_solution()
  local slnPath = utils.find_sln_root()
  if slnPath then
    -- Find the .sln file in the solution directory
    local sln_files = vim.fs.find(function(name) return name:match("%.sln$") end, {
      limit = 1,
      type = "file",
      path = slnPath
    })

    if #sln_files > 0 then
      local sln_file = sln_files[1]
      local sln_name = vim.fn.fnamemodify(sln_file, ":t:r") -- Get solution name without extension
      local rebuildCmd = { "dotnet", "build", "--no-incremental", sln_file }

      executeCmd(rebuildCmd, false, "Solution Rebuild (" .. sln_name .. ")", function(exit_code, duration, stdout_lines, stderr_lines)
        -- Additional callback logic for rebuild
        if exit_code == 0 then
          vim.notify("Rebuild completed - all artifacts refreshed", vim.log.levels.INFO, {
            title = "Rebuild Summary",
            timeout = 3000,
          })
        end
      end)
    else
      vim.notify("No solution file found in " .. slnPath, vim.log.levels.WARN, { title = "C# Build" })
    end
  else
    vim.notify("No solution directory found", vim.log.levels.WARN, { title = "C# Build" })
  end
end

---Clean the solution
function M.clean_solution()
  local slnPath = utils.find_sln_root()
  if slnPath then
    -- Find the .sln file in the solution directory
    local sln_files = vim.fs.find(function(name) return name:match("%.sln$") end, {
      limit = 1,
      type = "file",
      path = slnPath
    })

    if #sln_files > 0 then
      local sln_file = sln_files[1]
      local sln_name = vim.fn.fnamemodify(sln_file, ":t:r") -- Get solution name without extension
      local cleanCmd = { "dotnet", "clean", sln_file }

      executeCmd(cleanCmd, false, "Solution Clean (" .. sln_name .. ")", function(exit_code, duration, stdout_lines, stderr_lines)
        -- Additional callback logic for clean
        if exit_code == 0 then
          vim.notify("Clean completed - build artifacts removed", vim.log.levels.INFO, {
            title = "Clean Summary",
            timeout = 3000,
          })
        end
      end)
    else
      vim.notify("No solution file found in " .. slnPath, vim.log.levels.WARN, { title = "C# Build" })
    end
  else
    vim.notify("No solution directory found", vim.log.levels.WARN, { title = "C# Build" })
  end
end

---Build the current project
function M.build_project()
  local projPath = utils.find_proj_root()
  if projPath then
    local proj_name = vim.fn.fnamemodify(projPath, ":t:r") -- Get project name without extension
    local projCmd = { "dotnet", "build", projPath }
    executeCmd(projCmd, false, "Project Build (" .. proj_name .. ")", function(exit_code, duration, stdout_lines, stderr_lines)
      if exit_code == 0 then
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
    local proj_name = vim.fn.fnamemodify(projPath, ":t:r") -- Get project name without extension
    local projCmd = { "dotnet", "build", "--no-incremental", projPath }
    executeCmd(projCmd, false, "Project Rebuild (" .. proj_name .. ")", function(exit_code, duration, stdout_lines, stderr_lines)
      if exit_code == 0 then
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
    local proj_name = vim.fn.fnamemodify(projPath, ":t:r") -- Get project name without extension
    local projCmd = { "dotnet", "clean", projPath }
    executeCmd(projCmd, false, "Project Clean (" .. proj_name .. ")", function(exit_code, duration, stdout_lines, stderr_lines)
      if exit_code == 0 then
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
      if data and #data > 0 and data[1] ~= "" then
        local dotnet_version = data[1]

        -- Get C# version (requires a project context)
        vim.fn.jobstart({ "dotnet", "--list-sdks" }, {
          stdout_buffered = true,
          on_stdout = function(_, sdk_data)
            local version_info = "📋 .NET Version: " .. dotnet_version

            if sdk_data and #sdk_data > 0 then
              version_info = version_info .. "\n📦 Available SDKs:"
              for _, sdk in ipairs(sdk_data) do
                if sdk ~= "" then
                  version_info = version_info .. "\n  • " .. sdk
                end
              end
            end

            -- Show in floating window
            utils.execute_command_and_show_output("echo '" .. version_info .. "'", "C# Version Information")
          end,
        })
      end
    end,
  })
end

return M

-- Auto-retarget Roslyn when opening C# files to fix decompilation navigation issues
-- Enhanced for WSL2 environments with Windows project paths

---Detect if we're running in WSL2 environment
---@return boolean is_wsl2 True if running in WSL2, false otherwise
local function is_wsl2()
  local handle = io.popen("uname -r 2>/dev/null")
  if handle then
    local result = handle:read("*a")
    handle:close()
    return result:match("microsoft") ~= nil or result:match("WSL") ~= nil
  end
  return false
end

---Check if wslpath utility is available (required for WSL2 environments)
---@return boolean available True if wslpath is available or not needed, false if missing
local function check_wslpath_available()
  if not is_wsl2() then
    return true -- Not needed in non-WSL2 environments
  end

  local handle = io.popen("which wslpath 2>/dev/null")
  if handle then
    local result = handle:read("*a")
    handle:close()
    return result ~= ""
  end
  return false
end

---Check if the given path is located on a Windows mount point
---@param path string File path to check
---@return boolean is_windows True if path is on Windows mount (/mnt/[drive]/), false otherwise
local function is_windows_project(path)
  return path:match("^/mnt/[a-zA-Z]/") ~= nil
end

-- Module-level variable to track if retargeting has been done in this session
local has_retargeted = false

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("RoslynAutoTarget", { clear = true }),
  pattern = "cs",
  callback = function()
    -- Skip if retargeting has already been done in this session
    if has_retargeted then
      return
    end

    -- Mark as retargeted for this session
    has_retargeted = true

    -- Longer delay for WSL2 environments to ensure proper initialization
    local delay = is_wsl2() and 1000 or 500

    vim.defer_fn(function()
      -- Check WSL2 dependencies before proceeding
      if is_wsl2() and not check_wslpath_available() then
        vim.notify(
          "WSL2 detected but wslpath not available - some Roslyn features may not work properly",
          vim.log.levels.WARN,
          { title = "Roslyn Auto-Target" }
        )
      end

      local roslyn = require("roslyn")
      if roslyn and roslyn.get_targets then
        local targets = roslyn.get_targets()

        if targets and #targets > 0 then
          -- Find the .sln target if available
          local sln_target
          local current_file = vim.api.nvim_buf_get_name(0)

          -- For WSL2 Windows projects, prefer solutions in the same directory tree
          if is_wsl2() and is_windows_project(current_file) then
            for _, target in ipairs(targets) do
              if target:match("%.sln$") and target:match("^/mnt/") then
                sln_target = target
                break
              end
            end
          else
            -- Standard solution detection
            for _, target in ipairs(targets) do
              if target:match("%.sln$") then
                sln_target = target
                break
              end
            end
          end

          -- Target the solution or the first available target
          local selected_target = sln_target or targets[1]
          roslyn.target(selected_target)

          -- Enhanced notification for WSL2 (only in debug mode or .NET projects)
          local env_info = is_wsl2() and " (WSL2)" or ""
          -- Only notify if in debug mode or in a .NET project
          if vim.g.wsl2_roslyn_debug or vim.fn.glob("*.sln") ~= "" or vim.fn.glob("*.csproj") ~= "" then
            vim.notify("Roslyn auto-retargeted to " .. selected_target .. env_info, vim.log.levels.INFO, {
              title = "Roslyn Auto-Target",
            })
          end
        else
          vim.notify("No Roslyn targets found", vim.log.levels.WARN, {
            title = "Roslyn Auto-Target",
          })
        end
      end
    end, delay)
  end,
})

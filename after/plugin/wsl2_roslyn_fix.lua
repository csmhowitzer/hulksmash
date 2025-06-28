-- WSL2-specific fixes for Roslyn LSP decompilation navigation
-- This addresses the cross-filesystem boundary issues between Windows projects and WSL2
--
-- PERFORMANCE OPTIMIZATIONS APPLIED:
-- - Smart notifications (context-aware, debug mode support)
-- - Environment variable optimizations for faster .NET loading
-- - Timing diagnostics for performance monitoring
--
-- FEATURES:
-- - Cross-filesystem path translation with wslpath
-- - Enhanced LSP definition handlers for decompiled sources
-- - Automatic .NET environment configuration for WSL2
-- - Performance timing and diagnostics

local M = {}

-- Use the smart notification utility for context-aware notifications
local smart_notify_util = require('utils.smart_notify')
local smart_notify = smart_notify_util.dotnet

---Check if wslpath utility is available in the system PATH
---@return boolean available True if wslpath command is found and executable
local function check_wslpath_available()
  local handle = io.popen("which wslpath 2>/dev/null")
  if handle then
    local result = handle:read("*a")
    handle:close()
    return result ~= ""
  end
  return false
end

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

---Detect if project is on Windows filesystem in WSL2
---@param project_path string Path to check
---@return boolean is_windows_project True if project is on mounted Windows drive
local function is_windows_project_in_wsl2(project_path)
  if not is_wsl2() then
    return false
  end

  -- Check if path starts with /mnt/c/, /mnt/d/, etc.
  return project_path:match("^/mnt/[a-zA-Z]/") ~= nil
end

---Determine appropriate runtime ID based on project location
---@return string|nil runtime_id The runtime ID to use, or nil to let .NET decide
local function detect_appropriate_runtime()
  if not is_wsl2() then
    return nil -- Let .NET decide on non-WSL2 systems
  end

  -- Get current working directory or LSP root
  local cwd = vim.fn.getcwd()
  local lsp_clients = vim.lsp.get_active_clients()

  -- Prefer Roslyn LSP root directory if available
  for _, client in ipairs(lsp_clients) do
    if client.name == "roslyn" and client.config.root_dir then
      cwd = client.config.root_dir
      break
    end
  end

  if is_windows_project_in_wsl2(cwd) then
    return "win-x64"  -- Windows project in WSL2
  else
    return "linux-x64"  -- Native WSL2 project
  end
end

---Set WSL2-specific environment variables for .NET/NuGet compatibility
---Forces appropriate runtime behavior to avoid package dependency issues
local function setup_wsl2_dotnet_env()
  if not is_wsl2() then
    return -- Only apply in WSL2 environment
  end

  local runtime_id = detect_appropriate_runtime()
  if runtime_id then
    vim.env.DOTNET_RUNTIME_ID = runtime_id
    vim.env.NUGET_PACKAGES = "/home/" .. (vim.env.USER or "user") .. "/.nuget/packages"
    vim.env.NUGET_FALLBACK_PACKAGES = ""
    vim.env.DOTNET_NUGET_SIGNATURE_VERIFICATION = "false"

    -- NEW: Performance optimizations for faster project loading
    vim.env.DOTNET_SKIP_FIRST_TIME_EXPERIENCE = "true" -- Skip .NET first-time setup
    vim.env.DOTNET_CLI_TELEMETRY_OPTOUT = "true" -- Disable telemetry for speed
    vim.env.MSBUILD_DISABLE_SHARED_BUILD_PROCESS_LANGUAGE_SERVICE = "1" -- Disable shared build process

    -- NEW: WSL2 filesystem performance optimizations
    vim.env.DOTNET_USE_POLLING_FILE_WATCHER = "true" -- Use polling instead of inotify for WSL2
    vim.env.MSBUILD_CACHE_ENABLED = "true" -- Enable MSBuild caching
    vim.env.DOTNET_ReadyToRun = "0" -- Disable ReadyToRun for faster startup

    -- Notify about environment setup (only when appropriate)
    smart_notify(
      string.format("WSL2 .NET environment configured with runtime: %s", runtime_id),
      vim.log.levels.INFO
    )
  end
end

---Validate WSL2 environment and check for required dependencies
---@return boolean valid True if environment is valid or not WSL2, false if dependencies missing
local function validate_wsl2_environment()
  if not is_wsl2() then
    return true -- Not WSL2, no validation needed
  end

  if not check_wslpath_available() then
    vim.notify(
      "WSL2 Roslyn Fix: wslpath utility not found!\n" ..
      "Path conversion will not work properly.\n" ..
      "Please ensure WSL2 is properly configured with wslpath support.",
      vim.log.levels.ERROR,
      { title = "WSL2 Dependency Missing" }
    )
    return false
  end

  return true
end

-- Check if a path is a Windows mount point
local function is_windows_path(path)
  return path:match("^/mnt/[a-zA-Z]/") ~= nil
end

---Convert Windows-style paths to WSL paths using wslpath utility
---@param path string The file path to convert (Windows or WSL format)
---@return string converted_path The converted WSL path, or original path if conversion fails/not needed
local function convert_windows_path_to_wsl(path)
  -- Check if this looks like a Windows path
  if path:match("^[A-Za-z]:\\") or path:match("\\") then
    -- Verify wslpath is available before using it
    if not check_wslpath_available() then
      vim.notify(
        "Cannot convert Windows path: wslpath utility not available\n" ..
        "Path: " .. path,
        vim.log.levels.WARN,
        { title = "WSL2 Path Conversion Failed" }
      )
      return path
    end

    local handle = io.popen("wslpath -u '" .. path:gsub("'", "'\"'\"'") .. "' 2>/dev/null")
    if handle then
      local wsl_path = handle:read("*a"):gsub("\n$", "")
      handle:close()
      if wsl_path and wsl_path ~= "" then
        return wsl_path
      else
        vim.notify(
          "wslpath conversion failed for: " .. path,
          vim.log.levels.WARN,
          { title = "WSL2 Path Conversion" }
        )
      end
    end
  end
  return path
end

---Enhanced file opening for decompiled sources with path translation
---@param uri string LSP URI pointing to the file to open
---@return boolean success True if decompiled file was successfully opened, false otherwise
local function open_decompiled_file(uri)
  local path = vim.uri_to_fname(uri)

  -- Convert Windows paths to WSL paths if needed
  path = convert_windows_path_to_wsl(path)

  -- Check if this is a decompiled file (multiple possible patterns)
  local is_decompiled = path:match("/tmp/MetadataAsSource/") or
                       path:match("MetadataAsSource") or
                       path:match("DecompilationMetadataAsSourceFileProvider") or
                       uri:match("MetadataAsSource")

  if is_decompiled then
    -- Try to find the file if path conversion didn't work
    if not vim.loop.fs_stat(path) then
      -- Try common decompiled file locations
      local possible_paths = {
        path,
        path:gsub("^.*MetadataAsSource", "/tmp/MetadataAsSource"),
        "/tmp" .. path:match("MetadataAsSource.*") or "",
      }

      for _, test_path in ipairs(possible_paths) do
        if test_path ~= "" and vim.loop.fs_stat(test_path) then
          path = test_path
          break
        end
      end
    end

    -- Ensure the file exists and is readable
    local stat = vim.loop.fs_stat(path)
    if stat then
      -- Open the file in a new buffer
      vim.cmd("edit " .. vim.fn.fnameescape(path))
      -- Set buffer as readonly since it's decompiled source
      vim.bo.readonly = true
      vim.bo.modifiable = false
      vim.bo.filetype = "cs"
      -- Add helpful buffer-local mappings
      vim.keymap.set("n", "q", "<cmd>bdelete<cr>", { buffer = true, desc = "Close decompiled source" })
      smart_notify("Opened decompiled source: " .. vim.fn.fnamemodify(path, ":t"), vim.log.levels.INFO)
      return true
    else
      vim.notify("Decompiled file not accessible: " .. path, vim.log.levels.WARN)
      -- Debug info
      vim.notify("Original URI: " .. uri, vim.log.levels.DEBUG)
      return false
    end
  end

  return false
end

---Custom LSP handler for textDocument/definition that handles WSL2 paths
---@param err table|nil LSP error object if request failed
---@param result table|table[]|nil LSP definition result(s)
---@param ctx table LSP request context
---@param config table LSP handler configuration
local function enhanced_definition_handler(err, result, ctx, config)
  if err then
    vim.notify("LSP definition error: " .. tostring(err), vim.log.levels.ERROR)
    return
  end

  if not result or vim.tbl_isempty(result) then
    smart_notify("No definition found", vim.log.levels.INFO)
    return
  end

  -- Handle single result
  if result.uri then
    result = { result }
  end

  -- Process each result with enhanced path handling
  for _, location in ipairs(result) do
    if location.uri then
      local uri = location.uri
      local original_path = vim.uri_to_fname(uri)

      -- Debug logging
      vim.notify("LSP returned URI: " .. uri, vim.log.levels.DEBUG)
      vim.notify("Converted to path: " .. original_path, vim.log.levels.DEBUG)

      -- Special handling for decompiled sources
      if open_decompiled_file(uri) then
        -- Successfully opened decompiled file
        if location.range and location.range.start then
          -- Jump to the specific line/column
          local line = location.range.start.line + 1
          local col = location.range.start.character
          vim.api.nvim_win_set_cursor(0, { line, col })
        end
        return
      end

      -- If not a decompiled file, try path conversion for regular files
      local converted_path = convert_windows_path_to_wsl(original_path)
      if converted_path ~= original_path and vim.loop.fs_stat(converted_path) then
        vim.cmd("edit " .. vim.fn.fnameescape(converted_path))
        if location.range and location.range.start then
          local line = location.range.start.line + 1
          local col = location.range.start.character
          vim.api.nvim_win_set_cursor(0, { line, col })
        end
        return
      end
    end
  end

  -- Fall back to default handler if no files were handled
  vim.lsp.handlers["textDocument/definition"](err, result, ctx, config)
end

---Setup WSL2-specific fixes for Roslyn LSP
---Configures enhanced LSP handlers and autocmds for cross-filesystem navigation
local function setup_wsl2_fixes()
  if not is_wsl2() then
    return
  end

  -- Validate WSL2 environment and dependencies
  if not validate_wsl2_environment() then
    vim.notify(
      "WSL2 Roslyn fixes disabled due to missing dependencies",
      vim.log.levels.WARN,
      { title = "WSL2 Setup" }
    )
    return
  end

  -- Setup .NET environment for WSL2 compatibility
  setup_wsl2_dotnet_env()

  -- Override the definition handler for better WSL2 support
  vim.lsp.handlers["textDocument/definition"] = enhanced_definition_handler
  
  -- Also handle type definitions
  vim.lsp.handlers["textDocument/typeDefinition"] = enhanced_definition_handler
  
  -- Create autocmd to monitor decompiled file access
  vim.api.nvim_create_autocmd("BufReadPre", {
    group = vim.api.nvim_create_augroup("WSL2RoslynFix", { clear = true }),
    pattern = "/tmp/MetadataAsSource/*",
    callback = function(args)
      local path = args.file
      -- Ensure file is readable
      local stat = vim.loop.fs_stat(path)
      if not stat then
        vim.notify("Decompiled file not found: " .. path, vim.log.levels.WARN)
        return false
      end
      
      -- Set buffer options for decompiled files
      vim.defer_fn(function()
        if vim.api.nvim_buf_is_valid(args.buf) then
          vim.api.nvim_buf_set_option(args.buf, "readonly", true)
          vim.api.nvim_buf_set_option(args.buf, "modifiable", false)
          vim.api.nvim_buf_set_option(args.buf, "filetype", "cs")
        end
      end, 100)
    end,
  })

  smart_notify("WSL2 Roslyn fixes loaded successfully (wslpath available)", vim.log.levels.INFO)

  -- Add LSP attach timing diagnostic with better tracking
  local roslyn_timing = {
    start_time = nil,
    nvim_start = vim.loop.hrtime()
  }

  -- Track Neovim startup time (only in debug mode)
  if vim.g.wsl2_roslyn_debug then
    vim.notify("⏱️ Neovim started, waiting for Roslyn LSP...", vim.log.levels.INFO)
  end

  -- Track when any LSP starts
  vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if client then
        local total_time = (vim.loop.hrtime() - roslyn_timing.nvim_start) / 1e9
        if client.name == "roslyn" then
          -- Only show Roslyn timing in debug mode
          if vim.g.wsl2_roslyn_debug then
            vim.notify(string.format("🚀 Roslyn LSP attached in %.2f seconds from Neovim start", total_time), vim.log.levels.WARN)
          end
        else
          -- Only show other LSP timing in debug mode
          if vim.g.wsl2_roslyn_debug then
            vim.notify(string.format("📡 %s LSP attached in %.2f seconds", client.name, total_time), vim.log.levels.INFO)
          end
        end
      end
    end,
  })

  -- Also track LSP progress for more detailed timing
  vim.api.nvim_create_autocmd("LspProgress", {
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if client and client.name == "roslyn" then
        local elapsed = (vim.loop.hrtime() - roslyn_timing.nvim_start) / 1e9
        if args.data.value and args.data.value.message and vim.g.wsl2_roslyn_debug then
          vim.notify(string.format("⏳ Roslyn (%.1fs): %s", elapsed, args.data.value.message), vim.log.levels.INFO)
        end
      end
    end,
  })

  -- Add debug mode toggle command using utility
  smart_notify_util.create_debug_command("WSL2RoslynDebug", "wsl2_roslyn_debug", "WSL2 Roslyn")

  -- Add manual LSP timing check command
  vim.api.nvim_create_user_command("RoslynTiming", function()
    local clients = vim.lsp.get_active_clients({ name = "roslyn" })
    if #clients > 0 then
      local elapsed = (vim.loop.hrtime() - roslyn_timing.nvim_start) / 1e9
      vim.notify(string.format("✅ Roslyn LSP is active (%.2f seconds since Neovim start)", elapsed), vim.log.levels.INFO)
      for _, client in ipairs(clients) do
        vim.notify(string.format("📊 Client ID: %d, Root: %s", client.id, client.config.root_dir or "none"), vim.log.levels.INFO)
      end
    else
      local elapsed = (vim.loop.hrtime() - roslyn_timing.nvim_start) / 1e9
      vim.notify(string.format("❌ No Roslyn LSP clients active (%.2f seconds elapsed)", elapsed), vim.log.levels.WARN)
    end
  end, { desc = "Check Roslyn LSP timing and status" })

  -- Add test command for path conversion
  vim.api.nvim_create_user_command("TestWSLPath", function(opts)
    local path = opts.args
    if path == "" then
      path = vim.api.nvim_buf_get_name(0)
    end

    local converted = convert_windows_path_to_wsl(path)
    print("Original: " .. path)
    print("Converted: " .. converted)
    print("Windows equivalent: " .. (vim.fn.system("wslpath -w '" .. converted .. "'"):gsub("\n$", "")))
  end, {
    nargs = "?",
    desc = "Test WSL path conversion",
    complete = "file"
  })
end

-- Auto-setup when this file is loaded
setup_wsl2_fixes()

-- Expose local functions for testing
M._check_wslpath_available = check_wslpath_available
M._is_wsl2 = is_wsl2
M._validate_wsl2_environment = validate_wsl2_environment
M._convert_windows_path_to_wsl = convert_windows_path_to_wsl
M._open_decompiled_file = open_decompiled_file
M._enhanced_definition_handler = enhanced_definition_handler
M._is_windows_project_in_wsl2 = is_windows_project_in_wsl2
M._detect_appropriate_runtime = detect_appropriate_runtime
M._setup_wsl2_dotnet_env = setup_wsl2_dotnet_env

-- Expose functions globally for health check
_G._wsl2_is_wsl2 = is_wsl2
_G._wsl2_convert_path = convert_windows_path_to_wsl
_G._wsl2_check_wslpath = check_wslpath_available

return M

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
-- - Auto-recovery from Roslyn LSP crashes

local M = {}

-- Track Roslyn crash recovery state
local roslyn_crash_recovery = {
  last_detach_time = 0,
  auto_reload_enabled = true,
  crash_count = 0,
  roslyn_is_healthy = true, -- Track if Roslyn is in a good state
  planned_detachment = false, -- Track if detachment is intentional (not a crash)
  user_initiated_reload = false, -- Track if user manually ran :edit or :LspRestart
}

-- Track if we've shown inotify warning this session
local inotify_warning_shown = false

-- Use the smart notification utility for context-aware notifications
local smart_notify_util = require('lib.smart_notify')
local smart_notify = smart_notify_util.dotnet

---Sanitize CRLF line endings in a buffer
---This prevents Roslyn from seeing Windows-style line endings that cause crashes
---@param bufnr number Buffer number to sanitize
---@return boolean True if CRLF was found and removed
local function sanitize_crlf(bufnr)
  -- Check if buffer still exists and is valid
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return false
  end

  -- Check if buffer has CRLF line endings
  local has_crlf = false
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  for _, line in ipairs(lines) do
    if line:match("\r$") then
      has_crlf = true
      break
    end
  end

  if has_crlf then
    -- Save cursor position
    local cursor = vim.api.nvim_win_get_cursor(0)

    -- Remove all carriage returns (silently, in insert mode)
    vim.cmd([[silent! keepjumps %s/\r//ge]])

    -- Restore cursor position
    pcall(vim.api.nvim_win_set_cursor, 0, cursor)

    -- Ensure Unix line endings
    vim.bo[bufnr].fileformat = "unix"

    return true
  end

  return false
end

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

---Check current inotify limit and warn if too low
---Shows notification once per session if limit < 2048
local function check_inotify_limit()
  -- Only check once per session
  if inotify_warning_shown then
    return
  end

  -- Only check in WSL2
  if not is_wsl2() then
    return
  end

  -- Read current inotify limit
  local handle = io.popen("cat /proc/sys/fs/inotify/max_user_instances 2>/dev/null")
  if not handle then
    return
  end

  local result = handle:read("*a")
  handle:close()

  local current_limit = tonumber(result)
  if not current_limit then
    return
  end

  -- Warn if limit is below recommended threshold
  if current_limit < 2048 then
    inotify_warning_shown = true

    local message = string.format(
      "⚠️ WSL2 inotify limit too low: %d (recommended: 8192)\n\n" ..
      "This may cause Roslyn LSP to fail loading projects.\n\n" ..
      "Fix commands:\n" ..
      "  sudo sed -i '/fs.inotify.max_user_instances/d' /etc/sysctl.conf\n" ..
      "  echo \"fs.inotify.max_user_instances=8192\" | sudo tee /etc/sysctl.d/99-inotify.conf\n" ..
      "  sudo sysctl -p /etc/sysctl.d/99-inotify.conf\n\n" ..
      "Then restart Neovim.",
      current_limit
    )

    vim.notify(message, vim.log.levels.WARN, {
      title = "WSL2 Roslyn Fix",
      timeout = 10000, -- Show for 10 seconds
    })
  end
end

---Clean Windows-generated build artifacts that contain invalid WSL2 paths
---@param solution_path string Path to the solution file
local function clean_windows_build_artifacts(solution_path)
  if not solution_path or solution_path == "" then
    return
  end

  -- Get solution directory
  local solution_dir = vim.fn.fnamemodify(solution_path, ":h")

  -- Find all project.assets.json files in the solution
  local find_cmd = string.format(
    "find '%s' -type f -name 'project.assets.json' 2>/dev/null",
    solution_dir
  )

  local handle = io.popen(find_cmd)
  if not handle then
    return
  end

  local assets_files = {}
  for file in handle:lines() do
    table.insert(assets_files, file)
  end
  handle:close()

  -- Check if any assets files contain Windows fallback paths
  local needs_cleanup = false
  for _, file in ipairs(assets_files) do
    local f = io.open(file, "r")
    if f then
      local content = f:read("*all")
      f:close()
      if content:match("C:\\\\Program Files") then
        needs_cleanup = true
        break
      end
    end
  end

  if needs_cleanup then
    -- Only show detection message in debug mode
    if vim.g.wsl2_roslyn_debug then
      smart_notify(
        "Detected Windows build artifacts - running dotnet restore to regenerate with WSL2 paths...",
        vim.log.levels.INFO,
        { title = "WSL2 Roslyn Fix" }
      )
    end

    -- Try to use cs_build.restore_solution if available, otherwise fall back to system call
    local cs_build_ok, cs_build = pcall(require, "lib.cs_build")

    if cs_build_ok and cs_build.restore_solution then
      -- Use the cs_build module for consistent restore behavior
      cs_build.restore_solution()
    else
      -- Fallback: Run dotnet restore directly via system call
      -- This is the key - just deleting obj/bin isn't enough, we need NuGet to regenerate
      local restore_cmd = string.format("cd '%s' && dotnet restore --force-evaluate 2>&1", solution_dir)
      local result = vim.fn.system(restore_cmd)

      if vim.v.shell_error == 0 then
        smart_notify(
          "Successfully regenerated NuGet assets with WSL2 paths",
          vim.log.levels.INFO,
          { title = "WSL2 Roslyn Fix" }
        )
      else
        smart_notify(
          "dotnet restore failed - you may need to run it manually\n" .. result,
          vim.log.levels.WARN,
          { title = "WSL2 Roslyn Fix" }
        )
      end
    end
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

  -- Clean Windows build artifacts when Roslyn attaches
  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("wsl2_roslyn_cleanup", { clear = true }),
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if not client or client.name ~= "roslyn" then
        return
      end

      -- Get solution path from Roslyn's root_dir
      local root_dir = client.config.root_dir
      if not root_dir then
        return
      end

      -- Find solution file in root directory
      local handle = io.popen(string.format("find '%s' -maxdepth 1 -name '*.sln' 2>/dev/null", root_dir))
      if not handle then
        return
      end

      local solution_file = handle:read("*l")
      handle:close()

      if solution_file and solution_file ~= "" then
        clean_windows_build_artifacts(solution_file)
      end

      -- Check inotify limit on first Roslyn attach
      check_inotify_limit()
    end,
  })

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
---This handler intercepts definition requests BEFORE Telescope to handle decompiled sources
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

  -- Check if ANY result is a decompiled source - if so, handle it directly
  for _, location in ipairs(result) do
    if location.uri then
      local uri = location.uri

      -- Check if this is a decompiled source BEFORE any other processing
      local is_decompiled = uri:match("MetadataAsSource") or
                           uri:match("DecompilationMetadataAsSourceFileProvider") or
                           uri:match("/tmp/") and uri:match("%.cs$")

      if is_decompiled then
        -- Debug logging (only in debug mode)
        if vim.g.wsl2_roslyn_debug then
          vim.notify("🔍 Decompiled source detected: " .. uri, vim.log.levels.INFO)
        end

        -- Handle decompiled file directly, bypassing Telescope
        if open_decompiled_file(uri) then
          if location.range and location.range.start then
            local line = location.range.start.line + 1
            local col = location.range.start.character
            vim.api.nvim_win_set_cursor(0, { line, col })
          end
          return -- Don't pass to Telescope
        end
      end
    end
  end

  -- If no decompiled sources, check for Windows path conversion needs
  for _, location in ipairs(result) do
    if location.uri then
      local original_path = vim.uri_to_fname(location.uri)
      local converted_path = convert_windows_path_to_wsl(original_path)

      if converted_path ~= original_path and vim.loop.fs_stat(converted_path) then
        -- Update the URI in the result to use the converted path
        location.uri = vim.uri_from_fname(converted_path)
      end
    end
  end

  -- Fall back to default handler (which may be Telescope or built-in)
  -- This allows Telescope to handle regular (non-decompiled) definitions
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

---Setup auto-recovery for Roslyn LSP crashes
---Detects when Roslyn detaches unexpectedly and auto-reloads the buffer
local function setup_roslyn_crash_recovery()
  -- Create autocmd to detect Roslyn detachment
  vim.api.nvim_create_autocmd("LspDetach", {
    group = vim.api.nvim_create_augroup("roslyn_crash_recovery", { clear = true }),
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)

      -- Only handle Roslyn LSP
      if not client or client.name ~= "roslyn" then
        return
      end

      -- If this is a planned detachment (e.g., for line ending sanitization), don't treat as crash
      if roslyn_crash_recovery.planned_detachment then
        roslyn_crash_recovery.planned_detachment = false
        return
      end

      -- If user manually ran :edit or :LspRestart, don't treat as crash
      if roslyn_crash_recovery.user_initiated_reload then
        roslyn_crash_recovery.user_initiated_reload = false
        return
      end

      -- Mark Roslyn as unhealthy (actual crash)
      roslyn_crash_recovery.roslyn_is_healthy = false

      local current_time = vim.loop.now()
      local time_since_last_detach = current_time - roslyn_crash_recovery.last_detach_time

      -- If detachment happened within 5 seconds of last one, it's likely a crash
      -- (not a user-initiated restart)
      if time_since_last_detach < 5000 then
        roslyn_crash_recovery.crash_count = roslyn_crash_recovery.crash_count + 1

        -- SAFEGUARD: Stop after 5 crashes to prevent infinite loops
        if roslyn_crash_recovery.crash_count > 5 then
          smart_notify(
            "Roslyn crashed too many times. Auto-recovery disabled. Manually restart with :LspRestart roslyn",
            vim.log.levels.ERROR,
            { title = "Roslyn Crash Recovery" }
          )
          roslyn_crash_recovery.auto_reload_enabled = false
          return
        end

        if roslyn_crash_recovery.auto_reload_enabled then
          -- Validate buffer before attempting reload
          local bufnr = args.buf
          local bufname = vim.api.nvim_buf_get_name(bufnr)

          -- Skip if buffer is invalid, unnamed, or special
          if not vim.api.nvim_buf_is_valid(bufnr) or bufname == "" or bufname:match("^%[.*%]$") then
            return
          end

          smart_notify(
            string.format("Roslyn LSP crashed (count: %d). Auto-reloading buffer...", roslyn_crash_recovery.crash_count),
            vim.log.levels.WARN,
            { title = "Roslyn Crash Recovery" }
          )

          -- Reload buffer after a short delay to let LSP cleanup
          vim.defer_fn(function()
            -- Double-check buffer is still valid before reloading
            if vim.api.nvim_buf_is_valid(bufnr) then
              pcall(vim.cmd, "edit")
            end
          end, 500)
        end
      else
        -- Reset crash count if it's been more than 5 seconds
        roslyn_crash_recovery.crash_count = 0
        roslyn_crash_recovery.auto_reload_enabled = true -- Re-enable auto-recovery
      end

      roslyn_crash_recovery.last_detach_time = current_time
    end,
  })

  -- Mark Roslyn as healthy when it attaches
  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("roslyn_health_tracking", { clear = true }),
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)

      if client and client.name == "roslyn" then
        roslyn_crash_recovery.roslyn_is_healthy = true
        -- Clear planned_detachment flag when Roslyn successfully reattaches
        roslyn_crash_recovery.planned_detachment = false
        -- Clear user_initiated_reload flag when Roslyn successfully reattaches
        roslyn_crash_recovery.user_initiated_reload = false
      end
    end,
  })

  -- Intercept user-initiated :edit commands to prevent crash recovery loop
  vim.api.nvim_create_autocmd("BufReadPre", {
    group = vim.api.nvim_create_augroup("roslyn_user_reload_detection", { clear = true }),
    pattern = "*.cs",
    callback = function()
      -- Mark as user-initiated reload to prevent crash recovery from triggering
      roslyn_crash_recovery.user_initiated_reload = true
    end,
  })

  -- Sanitize IMMEDIATELY when entering insert mode
  -- This catches any existing CRLF before user starts typing
  vim.api.nvim_create_autocmd("InsertEnter", {
    group = vim.api.nvim_create_augroup("csharp_line_ending_fix", { clear = true }),
    pattern = "*.cs",
    callback = function(args)
      sanitize_crlf(args.buf)
    end,
  })

  -- Sanitize during typing with debounce to avoid running on every keystroke
  -- This catches CRLF introduced by Augment inline suggestions
  local sanitize_debounce_timer = nil
  vim.api.nvim_create_autocmd("TextChangedI", {
    group = vim.api.nvim_create_augroup("csharp_line_ending_fix", { clear = false }), -- Don't clear, InsertEnter already created it
    pattern = "*.cs",
    callback = function(args)
      -- Debounce to avoid running on every keystroke
      if sanitize_debounce_timer then
        vim.fn.timer_stop(sanitize_debounce_timer)
      end

      sanitize_debounce_timer = vim.fn.timer_start(100, function()
        sanitize_crlf(args.buf)
      end)
    end,
  })



  -- Prevent formatting when Roslyn is unhealthy
  vim.api.nvim_create_autocmd("BufWritePre", {
    group = vim.api.nvim_create_augroup("roslyn_safe_format", { clear = true }),
    pattern = "*.cs",
    callback = function()
      if not roslyn_crash_recovery.roslyn_is_healthy then
        smart_notify(
          "Roslyn is unhealthy - skipping format on save to prevent data loss",
          vim.log.levels.WARN,
          { title = "Format Skipped" }
        )
        return true -- Prevent default formatting
      end
    end,
  })
end

---Toggle auto-recovery for Roslyn crashes
---@param enabled boolean? If provided, sets the state; otherwise toggles
function M.toggle_crash_recovery(enabled)
  if enabled ~= nil then
    roslyn_crash_recovery.auto_reload_enabled = enabled
  else
    roslyn_crash_recovery.auto_reload_enabled = not roslyn_crash_recovery.auto_reload_enabled
  end

  smart_notify(
    string.format("Roslyn crash auto-recovery: %s", roslyn_crash_recovery.auto_reload_enabled and "enabled" or "disabled"),
    vim.log.levels.INFO,
    { title = "Roslyn Crash Recovery" }
  )
end

-- Auto-setup when this file is loaded
setup_wsl2_fixes()
setup_roslyn_crash_recovery()

---Resync Roslyn LSP buffer state without full LSP restart
---This is useful when Roslyn is in a degraded state (syntax highlighting broken, hover/goto def not working)
---
---Order of operations (critical for safety):
---1. Sanitize CRLF first (clean the buffer)
---2. Save the cleaned buffer (write clean content to disk)
---3. Reload buffer (resync Roslyn with clean content)
vim.api.nvim_create_user_command("RoslynResync", function()
  local bufnr = vim.api.nvim_get_current_buf()

  -- Check if buffer has a filename (not a scratch buffer)
  local bufname = vim.api.nvim_buf_get_name(bufnr)
  if bufname == "" then
    smart_notify("Cannot resync: buffer has no filename", vim.log.levels.ERROR, { title = "Roslyn Resync" })
    return
  end

  -- Check if buffer is modifiable
  if not vim.bo[bufnr].modifiable then
    smart_notify("Cannot resync: buffer is not modifiable", vim.log.levels.ERROR, { title = "Roslyn Resync" })
    return
  end

  -- Step 1: Sanitize CRLF first (before saving!)
  -- This ensures we save clean content, not corrupted content
  sanitize_crlf(bufnr)

  -- Step 2: Save the buffer (now with clean content)
  local save_ok, save_err = pcall(vim.cmd, "write")
  if not save_ok then
    smart_notify(
      string.format("Failed to save buffer: %s", save_err),
      vim.log.levels.ERROR,
      { title = "Roslyn Resync" }
    )
    return
  end

  -- Step 3: Reload buffer to resync Roslyn
  -- This sends textDocument/didClose + didOpen to Roslyn with full buffer content
  local reload_ok, reload_err = pcall(vim.cmd, "edit")
  if not reload_ok then
    smart_notify(
      string.format("Failed to reload buffer: %s", reload_err),
      vim.log.levels.ERROR,
      { title = "Roslyn Resync" }
    )
    return
  end

  smart_notify("Roslyn buffer state resynced", vim.log.levels.INFO, { title = "Roslyn Resync" })
end, { desc = "Resync Roslyn LSP buffer state (sanitize CRLF, save, reload)" })

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

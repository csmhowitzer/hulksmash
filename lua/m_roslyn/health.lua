-- Health check for m_roslyn enhancements
-- Provides diagnostics for roslyn.nvim enhancements and configuration

local M = {}

---Check if roslyn.nvim plugin is available and properly configured
local function check_roslyn_plugin()
  vim.health.start("Roslyn Plugin")
  
  -- Check if roslyn.nvim is installed
  local has_roslyn, roslyn = pcall(require, "roslyn")
  if not has_roslyn then
    vim.health.error("roslyn.nvim not found", {
      "Install roslyn.nvim: https://github.com/seblyng/roslyn.nvim",
      "Add to your plugin manager configuration"
    })
    return false
  end
  
  vim.health.ok("roslyn.nvim plugin found")
  
  -- Check if roslyn has required functions
  if type(roslyn.setup) ~= "function" then
    vim.health.error("roslyn.setup function not available", {
      "Update roslyn.nvim to latest version",
      "Check plugin configuration"
    })
    return false
  end
  
  vim.health.ok("roslyn.nvim API available")
  return true
end

---Check LSP client status for roslyn
local function check_roslyn_lsp()
  vim.health.start("Roslyn LSP Client")
  
  local clients = vim.lsp.get_active_clients({ name = "roslyn" })
  
  if #clients == 0 then
    vim.health.warn("No active roslyn LSP clients", {
      "Open a C# file to activate roslyn LSP",
      "Check roslyn.nvim configuration",
      "Ensure .NET SDK is installed and accessible"
    })
    return false
  end
  
  vim.health.ok(string.format("Found %d active roslyn LSP client(s)", #clients))
  
  -- Check client capabilities
  local client = clients[1]
  if client.server_capabilities and client.server_capabilities.textDocumentSync then
    vim.health.ok("Roslyn LSP supports text document synchronization")
  else
    vim.health.warn("Roslyn LSP text document sync capabilities unclear")
  end
  
  return true
end

---Check vim.snippet support for documentation templates
local function check_snippet_support()
  vim.health.start("Snippet Support")
  
  -- Check if vim.snippet is available (Neovim 0.10+)
  if vim.snippet and type(vim.snippet.expand) == "function" then
    vim.health.ok("vim.snippet.expand available for template insertion")
  else
    vim.health.error("vim.snippet.expand not available", {
      "Requires Neovim 0.10 or later",
      "Update Neovim to support documentation template expansion"
    })
    return false
  end
  
  return true
end

---Check m_roslyn configuration and status
local function check_m_roslyn_config()
  vim.health.start("M_Roslyn Configuration")
  
  -- Check if m_roslyn is loaded
  local has_m_roslyn, m_roslyn = pcall(require, "m_roslyn")
  if not has_m_roslyn then
    vim.health.warn("m_roslyn not loaded", {
      "Add require('m_roslyn').setup() to your configuration",
      "Or load m_roslyn when needed"
    })
    return false
  end
  
  vim.health.ok("m_roslyn module loaded")
  
  -- Check auto_insert_docs module
  local has_auto_insert, auto_insert = pcall(require, "m_roslyn.auto_insert_docs")
  if not has_auto_insert then
    vim.health.error("m_roslyn.auto_insert_docs module not found", {
      "Check m_roslyn installation",
      "Verify file structure: lua/m_roslyn/auto_insert_docs.lua"
    })
    return false
  end
  
  vim.health.ok("auto_insert_docs module available")
  
  -- Check configuration
  if type(auto_insert.get_config) == "function" then
    local config = auto_insert.get_config()
    if config.enabled then
      vim.health.ok("Documentation auto-insert is enabled")
    else
      vim.health.warn("Documentation auto-insert is disabled", {
        "Enable with require('m_roslyn.auto_insert_docs').enable()",
        "Or configure with enabled = true in setup options"
      })
    end
    
    if config.debug then
      vim.health.info("Debug mode is enabled - will show detailed notifications")
    end
  else
    vim.health.warn("Cannot check auto_insert_docs configuration")
  end
  
  return true
end

---Check .NET environment for roslyn LSP
local function check_dotnet_environment()
  vim.health.start(".NET Environment")
  
  -- Check if dotnet command is available
  local dotnet_path = vim.fn.exepath("dotnet")
  if dotnet_path == "" then
    vim.health.error("dotnet command not found in PATH", {
      "Install .NET SDK: https://dotnet.microsoft.com/download",
      "Ensure dotnet is in your PATH",
      "Restart Neovim after installing .NET"
    })
    return false
  end
  
  vim.health.ok("dotnet command found: " .. dotnet_path)
  
  -- Check .NET version
  local handle = io.popen("dotnet --version 2>/dev/null")
  if handle then
    local version = handle:read("*a"):gsub("%s+", "")
    handle:close()
    if version and version ~= "" then
      vim.health.ok(".NET version: " .. version)
    else
      vim.health.warn("Could not determine .NET version")
    end
  else
    vim.health.warn("Could not check .NET version")
  end
  
  return true
end

---Check current buffer context for C# development
local function check_current_buffer()
  vim.health.start("Current Buffer Context")
  
  local bufnr = vim.api.nvim_get_current_buf()
  local filetype = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
  
  if filetype == "cs" then
    vim.health.ok("Current buffer is a C# file")
    
    -- Check if roslyn LSP is attached to current buffer
    local clients = vim.lsp.get_active_clients({ bufnr = bufnr, name = "roslyn" })
    if #clients > 0 then
      vim.health.ok("Roslyn LSP is attached to current buffer")
    else
      vim.health.warn("Roslyn LSP not attached to current buffer", {
        "Wait for LSP initialization",
        "Check roslyn.nvim configuration",
        "Try :LspRestart if needed"
      })
    end
  else
    vim.health.info("Current buffer is not a C# file (filetype: " .. (filetype or "none") .. ")")
    vim.health.info("Open a .cs file to test roslyn enhancements")
  end
end

---Run all health checks for m_roslyn
function M.check()
  check_roslyn_plugin()
  check_roslyn_lsp()
  check_snippet_support()
  check_m_roslyn_config()
  check_dotnet_environment()
  check_current_buffer()
end

return M

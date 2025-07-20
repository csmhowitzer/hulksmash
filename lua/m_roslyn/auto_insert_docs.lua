-- C# Documentation Auto Insert for roslyn.nvim
-- Automatically expands /// to XML documentation template using LSP textDocument/_vs_onAutoInsert

local M = {}

---Default configuration for documentation auto-insert
---@class AutoInsertDocsConfig
---@field enabled boolean Enable documentation auto-insert (default: true)
---@field trigger_pattern string Pattern to trigger auto-insert (default: "///")
---@field debug boolean Enable debug notifications (default: false)
local default_config = {
  enabled = true,
  trigger_pattern = "///",
  debug = false,
}

---Current configuration
---@type AutoInsertDocsConfig
local config = {}

---Simple debounce to prevent double execution
local last_trigger_time = 0

---Check if current line matches the trigger pattern for documentation insertion
---@param line string Current line content
---@param col number Current cursor column (0-based)
---@param char string Character being inserted
---@return boolean should_trigger True if documentation should be auto-inserted
local function should_trigger_docs(line, col, char)
  if char ~= "/" then
    return false
  end

  -- Check if we're typing the third '/' in a row
  local before_cursor = line:sub(1, col)
  return before_cursor:match("//$") ~= nil
end

---Generate a basic C# documentation template based on context
---@param bufnr number Buffer number
---@param line_num number Line number where documentation should be inserted
---@return string template The documentation template to insert
local function generate_documentation_template(bufnr, line_num)
  -- Get the next line to analyze what we're documenting
  local lines = vim.api.nvim_buf_get_lines(bufnr, line_num, line_num + 5, false)
  local next_line = lines[1] or ""

  -- Basic template
  local template = "/// <summary>\n/// $1\n/// </summary>"

  -- Check if it's a method with parameters
  if next_line:match("%(.*%)") then
    local params = {}
    -- Extract parameter names (simple regex)
    for param in next_line:gmatch("(%w+)%s*[,)]") do
      if param ~= "void" and param ~= "public" and param ~= "private" and param ~= "protected" and param ~= "static" then
        table.insert(params, param)
      end
    end

    -- Add parameter documentation
    for _, param in ipairs(params) do
      template = template .. "\n/// <param name=\"" .. param .. "\">$" .. (#params + 2) .. "</param>"
    end

    -- Add return documentation if not void
    if not next_line:match("void%s+") and next_line:match("%)") then
      template = template .. "\n/// <returns>$" .. (#params + 3) .. "</returns>"
    end
  end

  return template
end

---Request documentation template from roslyn LSP using correct VS-specific parameters
---@param bufnr number Buffer number
---@param client table LSP client
---@param char string Character being inserted
local function request_documentation_template(bufnr, client, char)
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  row, col = row - 1, col + 1  -- Convert to 0-based indexing and account for character insertion
  local uri = vim.uri_from_bufnr(bufnr)

  local params = {
    _vs_textDocument = { uri = uri },
    _vs_position = { line = row, character = col },
    _vs_ch = char,
    _vs_options = {
      tabSize = vim.bo[bufnr].tabstop,
      insertSpaces = vim.bo[bufnr].expandtab,
    },
  }

  if config.debug then
    vim.notify("[M_ROSLYN] Requesting documentation template from roslyn LSP", vim.log.levels.DEBUG, {
      title = "M_Roslyn Auto Insert"
    })
  end

  -- NOTE: Send request after buffer has changed (from wiki)
  vim.defer_fn(function()
    -- Try the exact wiki pattern with explicit handler function
    local handler = function(err, result, _)
      if err then
        if config.debug then
          vim.notify("LSP request failed: " .. tostring(err), vim.log.levels.WARN, {
            title = "M_Roslyn Auto Insert"
          })
        end

        -- NO FALLBACK: Let the post-processor handle any malformed output
        -- The successful LSP response will be processed by the post-processor
        return
      end

      if not result or not result._vs_textEdit or not result._vs_textEdit.newText then
        if config.debug then
          vim.notify("No valid result from LSP, using fallback", vim.log.levels.DEBUG, {
            title = "M_Roslyn Auto Insert"
          })
        end

        -- Fallback: Generate our own template
        local template = generate_documentation_template(bufnr, row)
        vim.snippet.expand(template)
        return
      end

      if config.debug then
        vim.notify("Expanding LSP-provided template: " .. result._vs_textEdit.newText:gsub("\n", "\\n"), vim.log.levels.DEBUG, {
          title = "M_Roslyn Auto Insert"
        })
      end

      -- Use the VS-specific result format
      vim.snippet.expand(result._vs_textEdit.newText)
    end

    -- Try vim.lsp.buf_request with VS-specific parameters
    vim.lsp.buf_request(
      bufnr,
      "textDocument/_vs_onAutoInsert",
      params,
      handler
    )
  end, 1)  -- 1ms delay as per wiki
end

---Setup documentation auto-insert for a roslyn LSP buffer
---@param bufnr number Buffer number
---@param client table LSP client
local function setup_buffer_auto_insert(bufnr, client)
  if not config.enabled then
    return
  end

  -- Only setup for roslyn LSP clients (check both possible names)
  if not client or (client.name ~= "roslyn" and client.name ~= "roslyn_ls") then
    return
  end

  if config.debug then
    vim.notify("Setting up documentation auto-insert for buffer " .. bufnr .. " with client " .. client.name, vim.log.levels.DEBUG, {
      title = "M_Roslyn Auto Insert"
    })
  end

  -- Create buffer-local autocmd for character insertion (following wiki pattern)
  vim.api.nvim_create_autocmd("InsertCharPre", {
    desc = "M_Roslyn: Trigger documentation auto insert on '/'.",
    buffer = bufnr,
    group = vim.api.nvim_create_augroup("MRoslynAutoInsert_" .. bufnr, { clear = true }),
    callback = function()
      local char = vim.v.char

      if char ~= "/" then
        return
      end

      local line = vim.api.nvim_get_current_line()
      local col = vim.api.nvim_win_get_cursor(0)[2]

      if should_trigger_docs(line, col, char) then
        -- Check if disabled at runtime
        if not config.enabled then
          if config.debug then
            vim.notify("[M_ROSLYN] DISABLED - Skipping documentation auto-insert", vim.log.levels.DEBUG, {
              title = "M_Roslyn Auto Insert"
            })
          end
          return
        end

        -- Check if documentation was already inserted by another handler
        local row = vim.api.nvim_win_get_cursor(0)[1]
        local surrounding_lines = vim.api.nvim_buf_get_lines(bufnr, math.max(0, row - 3), row + 3, false)
        local has_documentation = false

        for _, check_line in ipairs(surrounding_lines) do
          if check_line:match("<summary>") then
            has_documentation = true
            break
          end
        end

        if has_documentation then
          if config.debug then
            vim.notify("[M_ROSLYN] Documentation already exists - skipping to avoid double insertion", vim.log.levels.DEBUG, {
              title = "M_Roslyn Auto Insert"
            })
          end
          return
        end

        -- Simple debounce to prevent double execution
        local current_time = vim.loop.hrtime()
        if current_time - last_trigger_time < 100000000 then -- 100ms debounce
          if config.debug then
            vim.notify("[M_ROSLYN] Debounced - skipping duplicate trigger", vim.log.levels.DEBUG, {
              title = "M_Roslyn Auto Insert"
            })
          end
          return
        end
        last_trigger_time = current_time

        if config.debug then
          vim.notify("[M_ROSLYN] Triggering documentation auto-insert for line: '" .. line .. "' at col: " .. col, vim.log.levels.DEBUG, {
            title = "M_Roslyn Auto Insert"
          })
        end

        request_documentation_template(bufnr, client, char)
      end
    end,
  })
end

---Setup documentation auto-insert enhancement
---@param opts AutoInsertDocsConfig? Configuration options
function M.setup(opts)
  config = vim.tbl_deep_extend("force", default_config, opts or {})

  if not config.enabled then
    return
  end

  -- WORKAROUND: The LSP handler produces malformed output with double-wrapped summary tags
  -- and missing /// prefixes. This post-processor fixes the malformed documentation.
  -- TODO: Find root cause of double execution and fix properly instead of post-processing
  vim.api.nvim_create_autocmd("TextChangedI", {
    group = vim.api.nvim_create_augroup("MRoslynDocsPostProcess", { clear = true }),
    callback = function()
      local bufnr = vim.api.nvim_get_current_buf()
      local filetype = vim.api.nvim_get_option_value("filetype", { buf = bufnr })

      if filetype ~= "cs" then
        return
      end

      -- Get current cursor position and surrounding lines
      local row = vim.api.nvim_win_get_cursor(0)[1]
      local lines = vim.api.nvim_buf_get_lines(bufnr, math.max(0, row - 10), row + 5, false)

      -- Detect and replace malformed documentation with clean format
      for i, line in ipairs(lines) do
        local line_num = math.max(0, row - 10) + i - 1

        -- Look for malformed documentation (extra spaces, double wrapping, etc.)
        local is_malformed = false

        if line:match("^%s*///%s*<summary>") then
          -- Check if it's actually malformed (extra spaces or double wrapping)
          if line:match("^%s*///%s%s+<summary>") then -- Extra spaces after ///
            is_malformed = true
          elseif lines[i + 1] and lines[i + 1]:match("<summary>") then -- Double wrapping
            is_malformed = true
          end

          if is_malformed then
            if config.debug then
              vim.notify("[M_ROSLYN] Found malformed documentation, replacing with clean format", vim.log.levels.DEBUG, {
                title = "M_Roslyn Post-Process"
              })
            end
          else
            -- Documentation is already clean, remove the autocmd to stop processing
            if config.debug then
              vim.notify("[M_ROSLYN] Documentation already clean, removing post-processor", vim.log.levels.DEBUG, {
                title = "M_Roslyn Post-Process"
              })
            end

            -- Remove the autocmd since we're done processing
            pcall(vim.api.nvim_del_augroup_by_name, "MRoslynDocsPostProcess")
            break
          end
        end

        if is_malformed then

          -- Get indentation
          local indent = line:match("^(%s*)")

          -- Find the end of the documentation block
          local end_line = line_num
          for j = i + 1, #lines do
            if lines[j] and lines[j]:match("</summary>") then
              end_line = math.max(0, row - 10) + j - 1
              break
            end
          end

          -- Replace entire block with clean format
          local clean_docs = {
            indent .. "/// <summary>",
            indent .. "/// ",
            indent .. "/// </summary>"
          }

          vim.api.nvim_buf_set_lines(bufnr, line_num, end_line + 1, false, clean_docs)

          -- Position cursor on the middle line for editing
          vim.api.nvim_win_set_cursor(0, {line_num + 2, #indent + 4})

          -- Remove the autocmd since we're done processing
          pcall(vim.api.nvim_del_augroup_by_name, "MRoslynDocsPostProcess")

          break
        end
      end
    end,
  })

  -- Re-enable our handler but remove the fallback that causes double content
  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("MRoslynAutoInsertSetup", { clear = true }),
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      setup_buffer_auto_insert(args.buf, client)
    end,
  })
end

---Enable documentation auto-insert
function M.enable()
  config.enabled = true
  vim.notify("C# documentation auto-insert enabled", vim.log.levels.INFO, {
    title = "M_Roslyn"
  })
end

---Disable documentation auto-insert
function M.disable()
  config.enabled = false

  -- Clear all existing autocmds
  pcall(vim.api.nvim_del_augroup_by_name, "MRoslynAutoInsertSetup")

  -- Clear buffer-specific autocmds for all buffers
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    pcall(vim.api.nvim_del_augroup_by_name, "MRoslynAutoInsert_" .. bufnr)
  end

  vim.notify("C# documentation auto-insert disabled", vim.log.levels.INFO, {
    title = "M_Roslyn"
  })
end

---Toggle documentation auto-insert
function M.toggle()
  if config.enabled then
    M.disable()
  else
    M.enable()
  end
end

---Get current configuration
---@return AutoInsertDocsConfig
function M.get_config()
  return vim.deepcopy(config)
end

-- Expose internal functions for testing
M._should_trigger_docs = should_trigger_docs
M._setup_buffer_auto_insert = setup_buffer_auto_insert
M._request_documentation_template = request_documentation_template
M._generate_documentation_template = generate_documentation_template

return M

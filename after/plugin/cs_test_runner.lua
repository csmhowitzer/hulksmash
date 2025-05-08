-- get a template for a test function via treesitter playground
local test_function_query_string = [[
    (
      (method_declaration 
        returns: (predefined_type) @ret
        name: (identifier) @methodname
        parameters: (parameter_list) 
      )
      (#eq? @ret "void")
      (#eq? @methodname "%s")
    )
]]

---Finds the line number of the test function, using treesitter
---@usage find_test_line(cs_bufnr, name)
---@param cs_bufnr number : the buffer number
---@param name string : the name of the test function
---@return number|nil : the line number or nothing
local find_test_line = function(cs_bufnr, name)
  local formatted = string.format(test_function_query_string, name)
  local query = vim.treesitter.query.parse("c_sharp", formatted)
  local parser = vim.treesitter.get_parser(cs_bufnr, "c_sharp", {})
  local tree = parser:parse()[1]
  local root = tree:root()

  for id, node in query:iter_captures(root, cs_bufnr, 0, -1) do
    if id == 1 then
      local range = { node:range() }
      return range[1]
    end
  end
end

---Makes a key for the test entry
---@usage make_key(entry)
---@param entry table : the test entry
---@return string
local make_key = function(entry)
  assert(entry.extra.method, "Must have name: " .. vim.inspect(entry))
  assert(entry.extra.type, "Must have type: " .. vim.inspect(entry))
  return string.format("%s/%s", entry.extra.method, entry.extra.type)
end

---Adds a test to the state of the buffer
---@usage add_csharp_test(state, entry)
---@param state table : the state of the buffer
---@param entry table : the test entry
local add_csharp_test = function(state, entry)
  state.tests[make_key(entry)] = {
    name = entry.extra.method,
    dur = entry.duration,
    line = find_test_line(state.bufnr, entry.extra.method),
    output = {},
  }
end

---Formats the message from the test runner
---@usage fmtMessage(msg)
---@param msg string : the message from the test runner
---@return string[]
local fmtMessage = function(msg)
  return vim.split(msg, "\\\\n")
end
---Formats the message for the stack trace from the test runner
---@usage fmtStackTrace(stackTrace)
---@param stackTrace string : the stack trace from the test runner
---@return string[]
local fmtStackTrace = function(stackTrace)
  return vim.split(string.gsub(stackTrace, " in ", " \\n--> in "), "\\n")
end

---Adds the output from the test runner to the test entry
---@param state table : the state of the buffer
---@param entry table : the test entry
local add_csharp_output = function(state, entry)
  assert(state.tests, "no tests loaded yet")
  if entry.status == "failed" then
    table.insert(state.tests[make_key(entry)].output, "------------")
    for _, i in ipairs(fmtMessage(entry.message)) do
      table.insert(state.tests[make_key(entry)].output, i)
    end
    table.insert(state.tests[make_key(entry)].output, "------------")
    for _, i in ipairs(fmtStackTrace(entry.trace)) do
      table.insert(state.tests[make_key(entry)].output, vim.trim(i))
    end
  end
end

---Marks the test as successful
---@param state table : the state of the buffer
---@param entry table : the test entry
local mark_success = function(state, entry)
  state.tests[make_key(entry)].success = entry.status == "passed"
end

local ns = vim.api.nvim_create_namespace("live-tests")
local group = vim.api.nvim_create_augroup("AutoTest", { clear = true })
local hl_group = vim.api.nvim_set_hl(ns, "PassedTest", { fg = "#2ECC71", italic = true })

---Gets the output from the test runner and parses it
---@usage output_process(bufnr, state, data)
---@param bufnr number : the buffer number
---@param state table : the state of the buffer
---@param data any : the output from the test runner
---@return nil : when there is no output
local output_process = function(bufnr, state, data)
  if not data then
    print("no output text to parse through")
    return
  end

  -- INFO: need to remove odd chars added when grabbing the result from the test output
  local s = vim.inspect(data)
  local sub1 = string.sub(s, 7)
  local len = string.len(sub1)
  local sub2 = string.sub(sub1, 1, len - 9)

  local decoded = vim.json.decode(sub2)
  if decoded.results.tests ~= {} then
    for _, t in pairs(decoded.results.tests) do
      -- this is where we parse through the decoded lua table
      add_csharp_test(state, t)
      add_csharp_output(state, t)
      mark_success(state, t)
      local test = state.tests[make_key(t)]
      if test.success and test.line then
        local flavor = "\t  " .. test.dur .. "ms"
        local text = { flavor, "String" }
        local opts = {
          virt_text = { text },
        }
        vim.api.nvim_buf_set_extmark(bufnr, ns, test.line, 0, opts)
      end
    end
  else
    error("Failed to handle" .. vim.inspect(data))
  end
end

---Exits the test runner and sets the diagnostics
---@usage output_exit(bufnr, state)
---@param bufnr number : the buffer number
---@param state table : the state of the buffer
---@return nil
local output_exit = function(bufnr, state)
  local failed = {}
  for _, t in pairs(state.tests) do
    if t.line then
      if not t.success then
        table.insert(failed, {
          bufnr = bufnr,
          lnum = t.line,
          col = 0,
          severity = vim.diagnostic.severity.ERROR,
          source = "cs-test",
          message = "Test Failed " .. t.dur .. "ms",
          user_data = {},
        })
      end
    end
  end
  vim.diagnostic.set(ns, bufnr, failed, {})
end

---Attaches the test runner to the buffer
---@usage attach_to_buffer(bufnr, command)
---@param bufnr number : the buffer number
---@param command any : the command to run the test runner
local attach_to_buffer = function(bufnr, command)
  local state = {
    bufnr = bufnr,
    tests = {},
  }
  vim.api.nvim_buf_create_user_command(bufnr, "CSTestDiag", function()
    local line = vim.fn.line(".") - 1
    for _, test in pairs(state.tests) do
      if test.line == line then
        vim.cmd.new()
        vim.api.nvim_buf_set_lines(vim.api.nvim_get_current_buf(), 0, -1, false, test.output)
      end
    end
  end, {})
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    pattern = "*_tests.cs", -- only for C# test classes right now
    callback = function()
      vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

      local path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":h") -- get bufnr dir path
      vim.api.nvim_set_current_dir(path)

      state = {
        bufnr = bufnr,
        tests = {},
      }

      vim.fn.jobstart(command, {
        stdout_buffered = true,
        on_stdout = function(_, data)
          output_process(bufnr, state, data)
        end,
        on_exit = function()
          output_exit(bufnr, state)
        end,
      })
    end,
  })
end

vim.api.nvim_create_user_command("CSTestOnSave", function()
  attach_to_buffer(vim.api.nvim_get_current_buf(), { "dotnet", "run", "-silent", "-ctrf", "/dev/stdout" })
end, {}) -- { 'dotnet', 'run', '-silent', '-ctrf', '/dev/stdout' }

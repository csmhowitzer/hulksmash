-- INFO: This provides a keymap to allow a build of the C# solution

local buildSlnCmd = { "dotnet", "build" }
local cleanSlnCmd = { "dotnet", "msbuild", "-t:clean" }
local rebuildSlnCmd = { "dotnet", "msbuild", "-t:rebuild" }
local addPackageCmd = { "dotnet", "add", "[PROJECT]", "package", "<package name>" }
local addProjRefCmd = { "dotnet", "add", "reference", "[PROJECT_PATH]" }

-- NOTE: This is the dotnet sdk flavor of Clean/Rebuild as this commadn is not directly present in
-- the current dotnet sdk
--local rebuildSlnCmd = { 'dotnet', 'build', '--no-incremental' }

local utils = require("user.utils")

vim.notify = require("notify")

---formats the text to bed displayed by the notify popupcomment
---@param data any : the console output from the command
---@return string
local formatText = function(data)
  local ret = ""
  for _, t in pairs(data) do
    ret = ret .. "\n" .. t
  end
  return ret
end

---commands that will be ran after the dotnet command is calledcomment
---@param reloadBuf any
local run_on_exit = function(reloadBuf)
  if reloadBuf then
    vim.cmd([[e]])
    vim.cmd([[LspRestart]])
  end
end

---Runs the specified dotnet sdk command
---@param command any
---@param reloadBuf any
local dotnetCmd = function(command, reloadBuf)
  vim.fn.jobstart(command, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      vim.notify(formatText(data), vim.log.levels.INFO, {
        title = "DotNet CLI Message",
      })
    end,
    on_exit = function()
      run_on_exit(reloadBuf)
    end,
  })
end

--- Executes the input command
---@param command any : the dotnet command to run, each word is a item in the table
---@param reloadBuf? boolean : reloads the buffer after the command executes
local executeCmd = function(command, reloadBuf)
  local bufnr = vim.api.nvim_get_current_buf()
  local type = vim.filetype.match({ buf = bufnr })

  if type == "cs" then
    dotnetCmd(command, reloadBuf)
  end
end

---Formats the selected list item
---@param selected any : the list item
---@return string
local format_selection = function(selected)
  local list = vim.split(selected, "/")
  local updated = string.gsub(list[#list], ".csproj", "")
  return updated
end

---Opens a list of C# projects to add as a reference to the current project
local select_cs_proj_ref = function()
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

local add_to_proj_file = function(projPath, line)
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

local add_proto_to_proj = function(name, service)
  local projPath = utils.find_proj_root()
  if projPath then
    add_to_proj_file(projPath, '<Protobuf Include="Protos\\' .. name .. '.proto" GrpcServices="' .. service .. '" />')
  end
end

vim.keymap.set("n", "<C-b>b", function()
  executeCmd(buildSlnCmd)
end, { desc = "[B]uild Solution" })

vim.keymap.set("n", "<C-b>r", function()
  executeCmd(rebuildSlnCmd)
end, { desc = "[R]ebuild Solution" })

vim.keymap.set("n", "<C-b>c", function()
  executeCmd(cleanSlnCmd)
end, { desc = "[C]lean Solution" })

vim.keymap.set("n", "<leader>dap", function()
  vim.ui.input({ prompt = "Package name: " }, function(input)
    addPackageCmd[3] = utils.find_proj_root()
    addPackageCmd[5] = input
    executeCmd(addPackageCmd)
  end)
end, { desc = "[B]uild Solution" })

-- user commands
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

-- user commands
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

-- user commands
vim.api.nvim_create_user_command("CSAddProtoByBufServer", function()
  local bufName = utils.get_current_filename()
  add_proto_to_proj(bufName, "Server")
end, { desc = "Add a proto file to the C# project" })
-- user commands
vim.api.nvim_create_user_command("CSAddProtoByBufClient", function()
  local bufName = utils.get_current_filename()
  add_proto_to_proj(bufName, "Client")
end, { desc = "Add a proto file to the C# project" })
-- user commands
vim.api.nvim_create_user_command("CSAddProtoByBufBoth", function()
  local bufName = utils.get_current_filename()
  add_proto_to_proj(bufName, "Both")
end, { desc = "Add a proto file to the C# project" })

-- keymaps that are CS only
-- keymaps that aren't CLI functions
vim.api.nvim_create_autocmd({ "BufEnter", "FileType" }, {
  group = vim.api.nvim_create_augroup("CS_Only_Keymaps", {
    clear = true,
  }),
  pattern = { "*.cs", "*.csproj", "*.sln" },
  callback = function()
    -- vim.keymap.set("n", "<leader>gd", function()
    --   require("csharp").go_to_definition()
    -- end, { desc = "[G]oto [D]efinition (Roslyn)" })
    vim.keymap.set("n", "<leader>dbg", function()
      require("csharp").debug_project()
    end, { desc = "[D]e[b]u[g] project" })
    vim.keymap.set("n", "<leader>drp", function()
      select_cs_proj_ref()
    end, { desc = "[D]otnet [P]roject [R]eference" })
  end,
})

-- we want to create a new proto file
--    we need to know where to place the file
--        work off of a "Protos/" directory for default
--    we need a file name
--    we need a namespace
--    we need to update the .csproj with the protobuf
--        <Protobuf Include="Protos\greet.proto" GrpcServices="Server" />
--
-- we want to create a new class file
--    we need to know where to place the file
--    we need the class name (file name)
--    we need the namespace
--
-- Same for interfaces

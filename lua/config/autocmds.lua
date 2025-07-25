-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
  callback = function(event)
    -- In this case, we create a function that lets us more easily define mappings specific
    -- for LSP related items. It sets the mode, buffer and description for us each time.
    local map = function(keys, func, desc, mode)
      mode = mode or "n"
      vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
    end

    -- map('gd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')
    -- map('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
    -- map('gI', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')
    -- map('<leader>D', require('telescope.builtin').lsp_type_definitions, 'Type [D]efinition')
    -- map('K', vim.lsp.buf.hover, 'Hover Documentation')
    -- map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

    map("<leader>ds", require("telescope.builtin").lsp_document_symbols, "[D]ocument [S]ymbols")
    map("<leader>ws", require("telescope.builtin").lsp_dynamic_workspace_symbols, "[W]orkspace [S]ymbols")

    -- Refactoring keymaps (code refactor category)
    map("<leader>crn", vim.lsp.buf.rename, "[C]ode [R]efactor Re[n]ame")
    map("<leader>crm", function()
      -- Suppress the same roslyn.nvim cancellation bug for extract method
      local original_notify = vim.notify
      vim.notify = function(msg, level, opts)
        if type(msg) == "string" and
           msg:find("lsp_commands%.lua:72") and
           msg:find("attempt to index local 'action'") then
          return
        end
        original_notify(msg, level, opts)
      end

      vim.lsp.buf.code_action({
        context = { only = { "refactor.extract" } },
        filter = function(action)
          return action.title:match("[Ee]xtract.*[Mm]ethod") or
                 action.title:match("[Ee]xtract.*[Ff]unction")
        end,
        apply = true,
      })

      -- Restore after user interaction time
      vim.defer_fn(function()
        vim.notify = original_notify
      end, 2000)
    end, "[C]ode [R]efactor Extract [M]ethod", { "n", "x" })
    map("<leader>crc", function()
      -- NOTE: This works correctly but shows a roslyn.nvim error when escaping selection
      -- Error: "attempt to index local 'action' (a nil value)" in lsp_commands.lua:72
      -- The functionality works despite the error - this is a known roslyn.nvim bug
      -- Will be retested during Neovim 0.11 upgrade

      vim.lsp.buf.code_action({
        filter = function(action)
          return action.title and (
            action.title:find("Introduce constant") or
            action.title:find("Introduce variable")
          )
        end,
        apply = true,
      })
    end, "[C]ode [R]efactor Extract [C]onstant", { "n", "x" })



    map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction", { "n", "x" })

    -- The following two autocommands are used to highlight references of the
    -- word under your cursor when your cursor rests there for a little while.
    --    See `:help CursorHold` for information about when this is executed
    --
    -- When you move your cursor, the highlights will be cleared (the second autocommand).
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
      local highlight_augroup = vim.api.nvim_create_augroup("kickstart-lsp-highlight", { clear = false })
      vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
        buffer = event.buf,
        group = highlight_augroup,
        callback = vim.lsp.buf.document_highlight,
      })

      vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
        buffer = event.buf,
        group = highlight_augroup,
        callback = vim.lsp.buf.clear_references,
      })

      vim.api.nvim_create_autocmd("LspDetach", {
        group = vim.api.nvim_create_augroup("kickstart-lsp-detach", { clear = true }),
        callback = function(event2)
          vim.lsp.buf.clear_references()
          vim.api.nvim_clear_autocmds({ group = "kickstart-lsp-highlight", buffer = event2.buf })
        end,
      })
    end
  end,
})

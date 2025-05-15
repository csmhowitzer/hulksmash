-- Auto-retarget Roslyn when opening c# files to fix decompiliation navigation issues

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

    -- Small delay to ensure the file is fully loaded and auto-targeting has happened
    vim.defer_fn(function()
      -- Get all available targets
      local roslyn = require("roslyn")
      if roslyn and roslyn.get_targets then
        local targets = roslyn.get_targets()

        -- If targets are available, select the first one (usually the solution)
        if targets and #targets > 0 then
          -- Find the .sln target if available
          local sln_target
          for _, target in ipairs(targets) do
            if target:match("%.sln$") then
              sln_target = target
              break
            end
          end

          -- Target the solution or the first available target
          roslyn.target(sln_target or targets[1])

          -- Optional: Print a notification
          vim.notify("Roslyn auto-retargeted to " .. (sln_target or targets[1]), vim.log.levels.INFO, {
            title = "Roslyn Auto-Target",
          })
        end
      end
    end, 500) -- 500ms delay
  end,
})

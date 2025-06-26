# After Plugin Directory - Architectural Decision

## Why WSL2 Roslyn Enhancements Are in `after/plugin/`

This document explains why the WSL2 Roslyn enhancements are placed in the `after/plugin/` directory rather than following the `lua/m_augment/` pattern used for Augment plugin enhancements.

## Enhancement Pattern Comparison

### `lua/m_augment/` Pattern (Augment Plugin)
- **Module-based enhancement** - Augment plugin provides a Lua API
- **Explicit integration** - Code calls `require("m_augment.code")` when needed
- **Optional usage** - Features are used on-demand via explicit calls
- **Clean separation** - Enhancements are separate, importable modules
- **User control** - Developer chooses when and how to use features

### `after/plugin/` Pattern (Roslyn Plugin)
- **Hook-based enhancement** - Roslyn plugin uses Neovim's LSP system
- **Automatic integration** - Must intercept LSP handlers automatically
- **System-level fixes** - Modifies core LSP behavior for WSL2 compatibility
- **Load order critical** - Must load AFTER roslyn.nvim sets up LSP handlers
- **Transparent operation** - Works without user intervention

## Key Architectural Reasons

### 1. **Load Order Requirements** ⏰
```lua
-- roslyn.nvim sets up LSP handlers first
-- THEN our WSL2 fixes need to override them
vim.lsp.handlers["textDocument/definition"] = enhanced_definition_handler
```

The `after/plugin/` directory ensures our enhancements load **after** roslyn.nvim has already configured the LSP handlers, allowing us to properly override them.

### 2. **Automatic System Integration** 🔄
- **No manual setup required** - Works automatically when opening C# files
- **Transparent enhancement** - User doesn't need to call any setup functions
- **System-level compatibility** - Hooks into existing LSP workflow seamlessly

### 3. **Plugin Architecture Difference** 🏗️
- **Augment Plugin**: Provides API → You build modules using it
- **Roslyn Plugin**: Uses LSP system → We need to enhance the system itself

### 4. **WSL2 as Compatibility Layer** 🌉
The WSL2 enhancements are fundamentally **compatibility fixes** rather than feature additions:
- Path translation between Windows and WSL2 filesystems
- Cross-filesystem boundary navigation
- Environment-specific dependency validation

These are system-level concerns that should work transparently.

## Alternative Approach Considered

We could have used a modular approach:
```
lua/m_roslyn/
├── wsl2_fixes.lua
├── path_conversion.lua
└── diagnostics.lua
```

With manual activation:
```lua
require("m_roslyn.wsl2_fixes").setup()
```

## Trade-offs Analysis

### `after/plugin/` (Current Choice)
✅ **Automatic operation** - Works without user intervention  
✅ **Transparent experience** - Seamless WSL2 compatibility  
✅ **Correct load order** - Guaranteed to load after roslyn.nvim  
✅ **System integration** - Properly hooks into LSP workflow  
❌ **Less modular** - Harder to selectively enable features  
❌ **Less explicit** - User may not know enhancements are active  

### `lua/m_roslyn/` (Alternative)
✅ **More modular** - Could enable/disable specific features  
✅ **Explicit control** - User chooses what to load and when  
✅ **Cleaner separation** - Follows established m_augment pattern  
❌ **Manual setup required** - User must remember to call setup functions  
❌ **Load order complexity** - User must ensure correct timing  
❌ **Fragile integration** - Easy to forget or misconfigure  

## Final Decision Rationale

The `after/plugin/` approach was chosen because:

1. **WSL2 path conversion is a system-level compatibility fix** that should "just work"
2. **Load order is critical** for LSP handler overrides
3. **Transparency is preferred** for compatibility layers
4. **Similar to roslyn.nvim itself** - it works automatically without manual setup

This creates a seamless experience where WSL2 users get working decompilation navigation without any additional configuration, matching the "it just works" philosophy of the base roslyn.nvim plugin.

## Files in This Directory

- `wsl2_roslyn_fix.lua` - Main WSL2 compatibility enhancements
- `roslyn_auto_target.lua` - Enhanced auto-targeting for WSL2 environments

Both files are automatically loaded when Neovim starts and C# files are opened, providing transparent WSL2 support for roslyn.nvim decompilation navigation.

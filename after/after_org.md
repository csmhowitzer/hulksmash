# After Plugin Organization Analysis

*Analysis of after/plugin/ directory for migration and cleanup opportunities*

## 📋 **After Plugin Review & Migration Analysis**

Here's what I found in your `after/plugin/` directory:

### **🔧 Core System Files (Keep in after/plugin/)**
1. **`wsl2_roslyn_fix.lua`** - WSL2 LSP handler overrides (must load after roslyn.nvim)
2. **`roslyn_auto_target.lua`** - Roslyn LSP targeting (load order dependent)
3. **`luasnip.lua`** - LuaSnip configuration (after plugin loading)

### **🎨 UI/Theme Files (Migration Candidates)**
4. **~~`change_colors.lua`~~** - Theme toggle functions ✅ **MIGRATED to lib/theme_utils.lua**
5. **`scratch_pad.lua`** - Snacks scratch pad customization → **lib/scratch_pad.lua**

### **📁 File Type Autocmds (Consolidation Candidates)**
6. **`cs_cwd_on_save.lua`** - C# directory switching ✅ **MIGRATED to auto_cwd.nvim**
7. **`fe_cwd_on_save.lua`** - Frontend directory switching ✅ **MIGRATED to auto_cwd.nvim**  
8. **`md_cwd_on_save.lua`** - Markdown directory switching ✅ **MIGRATED to auto_cwd.nvim**

### **⌨️ Keymap/Command Files (Migration Candidates)**
9. **~~`cs_keymaps.lua`~~** - C# specific keymaps ✅ **MIGRATED to lib/cs_keymaps.lua**
10. **`cs_test_runner.lua`** - C# test runner → **lib/cs_test_runner.lua**
11. **~~`cmd_terminal.lua`~~** - Terminal keymaps ✅ **MIGRATED to lib/terminal_utils.lua**
12. **~~`md_fmt_width.lua`~~** - Format width rules ✅ **MIGRATED to lib/format_width.lua**

### **📚 Documentation**
13. **`AFTER_PLUGIN.md`** - Keep for architectural documentation

## 🎯 **Migration Recommendations:**

### **High Priority (Plugin Extractions):**
1. **~~Consolidate CWD files~~** → ✅ **COMPLETE** - Migrated to `auto_cwd.nvim` plugin
2. **~~Move theme functions~~** → ✅ **COMPLETE** - Migrated to `lib/theme_utils.lua`
3. **~~Enhance format width~~** → ✅ **EXTRACTED** - `~/plugins/format-width.nvim` with help docs
4. **~~C# build system~~** → ✅ **COMPLETE** - Enhanced `lib/cs_build.lua` + `lib/cs_keymaps.lua` (ready for plugin)
5. **Plugin Extractions Ready**:
   - **~~`format-width.nvim`~~** → ✅ **COMPLETE** - Extracted with professional help docs
   - **`csharp-build.nvim`** - Professional C# build system with visual feedback
   - **`scratch-manager.nvim`** - Buffer management utilities

### **Medium Priority:**
4. **Terminal utilities** → `lib/terminal_utils.lua`
5. **Scratch pad customization** → `lib/scratch_pad.lua`

## ✅ **Completed Migrations:**

### **CWD Consolidation (COMPLETE)**
- **Before**: 3 separate CWD files with duplicated logic
- **After**: 1 unified `auto_cwd.nvim` plugin with:
  - ✅ **6 languages supported** (C#, Go, Frontend, Python, Rust, Obsidian)
  - ✅ **Configurable and extensible**
  - ✅ **Debug mode for troubleshooting**
  - ✅ **Runtime language control**
  - ✅ **Proper plugin structure**
  - ✅ **46 comprehensive tests** (by ML)

### **Format Width Enhancement (COMPLETE → EXTRACTED)**
- **Before**: `after/plugin/md_fmt_width.lua` with hardcoded autocmds
- **After**: ✅ **EXTRACTED to `~/plugins/format-width.nvim`** with advanced features:
  - ✅ **Enhanced configuration system** with validation and backward compatibility
  - ✅ **Toggleable width enforcement** (`:FormatWidthToggle`)
  - ✅ **Manual formatting commands** (`:FormatWidth [width]`)
  - ✅ **Format-on-save** (opt-in per filetype)
  - ✅ **Simple reset command** (`:FormatWidthReset`)
  - ✅ **Professional help documentation** (`:help format-width`)
  - ✅ **Old lib/format_width.lua removed** - plugin is the sole system

### **C# Build System Enhancement (COMPLETE)**
- **Before**: Basic build functionality scattered across files
- **After**: Professional-grade build system:
  - ✅ **Animated visual feedback** (spinner + real-time timer)
  - ✅ **Multi-solution support** (explicit .sln/.csproj targeting)
  - ✅ **Terminal-compatible keymaps** (F4-F9 logical grouping)
  - ✅ **Quickfix integration** with error/warning navigation
  - ✅ **Context-aware execution** (works from any file in solution/project)
  - ✅ **Clean architecture** (`cs_build.lua` + `cs_keymaps.lua`)
  - ✅ **Ready for plugin extraction** to `~/plugins/csharp-build.nvim`

## � **Potential Self-Contained Plugins**
*Candidates to move into ~/plugins/ directory*

Following the successful pattern of `present.nvim` and `auto_cwd.nvim`, these modules are excellent candidates for standalone plugins:

### **🎯 Strong Plugin Candidates:**

#### **1. C# Test Runner (`cs_test_runner.lua`)** 🧪
**Plugin name**: `csharp-test-runner.nvim`
- **Self-contained functionality**: Complete C# test execution and visualization system
- **Reusable across projects**: Any C# developer would benefit from this
- **Rich feature set**: Live test results, virtual text indicators, diagnostic output
- **Independent**: Doesn't rely on your specific config structure
- **Clear scope**: "C# test runner with live feedback"
- **Community value**: High potential for broader C# development community

#### **2. Scratch Pad Manager (`scratch_pad.lua`)** 📝
**Plugin name**: `scratch-manager.nvim`
- **Universal utility**: Every developer needs scratch space
- **Well-architected**: Already has proper module structure with M table
- **Feature-rich**: File persistence, multiple filetypes, window management
- **Configurable**: Border colors, positioning, sizing all customizable
- **Independent**: Builds on Snacks but adds significant value
- **Community value**: Universal developer tool

#### **3. Format Width Manager (`md_fmt_width.lua`)** 📏
**Plugin name**: `format-width.nvim`
- **Language-agnostic concept**: Format width rules for different file types
- **Configurable**: Easy to extend for more languages
- **Simple but valuable**: Solves a common formatting need
- **Reusable pattern**: Other developers have similar needs
- **Community value**: Medium - useful for consistent formatting workflows

### **🤔 Less Suitable for Standalone Plugins:**

#### **Theme Toggle (`change_colors.lua`)** 🎨
- **Too personal**: Hardcoded colors specific to your preferences
- **Better as lib**: More suitable for `lib/theme_utils.lua`

#### **C# Keymaps (`cs_keymaps.lua`)** ⌨️
- **Too opinionated**: Very specific keymap choices
- **Better as lib**: More suitable for `lib/cs_keymaps.lua`

#### **Terminal Utils (`cmd_terminal.lua`)** 💻
- **Too simple**: Just basic terminal window management
- **Better as lib**: More suitable for `lib/terminal_utils.lua`

### **🚀 Recommendation Priority:**
1. **`csharp-test-runner.nvim`** - Most compelling standalone plugin with high community value
2. **`scratch-manager.nvim`** - Universal utility that enhances existing tools
3. **`format-width.nvim`** - Simple but useful for consistent formatting workflows

## �🚀 **Next Steps:**

**Ready for next migration candidates:**
- Theme utilities (clean consolidation)
- C# specific tools (logical grouping)
- Terminal utilities (workflow optimization)

**Ready for plugin extraction:**
- C# Test Runner → `~/plugins/csharp-test-runner.nvim`
- Scratch Manager → `~/plugins/scratch-manager.nvim`
- Format Width Manager → `~/plugins/format-width.nvim`

---

*This analysis helps maintain a clean, organized after/plugin/ directory by identifying files that can be consolidated into the lib/ structure while preserving load-order dependent files that must remain in after/plugin/. Additionally, it identifies self-contained functionality that would benefit the broader community as standalone plugins.*

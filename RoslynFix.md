- Needs attention so we can navigate into decompiled references
  - otherwise will end up relying on other options

## Following this thread

[roslyn.nvim issue thread](https://github.com/seblyng/roslyn.nvim/issues/116)

## PROBLEM CLARIFIED! 🎯

**Real Issue**: roslyn.nvim works perfectly on **macOS desktop** but fails on **Windows work laptop with WSL2**
**Root Cause**: WSL2 environment differences, not roslyn.nvim itself

### Current Status:
- ✅ **macOS Desktop**: roslyn.nvim + decompilation navigation works perfectly
- ❌ **Windows WSL2**: Same config fails to navigate into decompiled sources

### WSL2-Specific Investigation Needed:

**Potential WSL2 Issues:**
1. **Path Translation**: Windows/Linux path differences
2. **File System Access**: WSL2 file system mounting issues
3. **Roslyn LSP Binary**: Different binary needed for Linux vs macOS
4. **Network/Socket Issues**: LSP communication problems in WSL2
5. **Permissions**: File access permissions in WSL2 environment

### Next Steps:
1. **Test on WSL2**: Verify current roslyn.nvim behavior on work laptop
2. **Check Roslyn LSP logs**: Look for WSL2-specific errors
3. **Path debugging**: Verify decompiled file paths in WSL2
4. **Binary verification**: Ensure correct Roslyn LSP binary for Linux
5. **WSL2 config**: Check WSL2-specific Neovim/LSP settings

### Keep Using:
- **roslyn.nvim**: Microsoft's official LSP (same as VS Code)
- **Current config**: Works perfectly on macOS
- **Auto-targeting**: Helps with solution detection

### 📝 **macOS Decompilation Path (WORKING):**
```
/var/folders/zj/n7bg2l7n7gs7j_nn6d1ycndm0000gn/T/MetadataAsSource/71da937e916a4c1dbc3a19dbc2d68f97/DecompilationMetadataAsSourceFileProvider/56e96ace918944d582a2d20bbfa8a6ff/Results.cs
```

**Key Observations:**
- **Location**: `/var/folders/.../T/` (macOS temp directory)
- **Structure**: `MetadataAsSource/[hash]/DecompilationMetadataAsSourceFileProvider/[hash]/[file].cs`
- **Behavior**: roslyn.nvim successfully creates and navigates to decompiled temp files
- **Access**: Full read access to decompiled source content

**WSL2 Comparison Needed:**
- Does WSL2 create similar temp file structure?
- Are temp files accessible in WSL2 environment?
- Do path translations work correctly?
- Are permissions set properly on decompiled files?

---

## 🔄 **THREAD CONTINUATION GUIDE**

**Context for New Augment Session:**
This investigation was started on macOS desktop and needs to continue on Windows work laptop with WSL2.

### **Investigation Summary:**
- **Problem**: roslyn.nvim decompilation navigation works perfectly on macOS but fails on Windows WSL2
- **Setup**: Identical HULKSMASH v1.0 Neovim config, same versions across machines
- **Baseline Confirmed**: macOS decompilation working with documented path above
- **Root Cause**: WSL2 environment differences, not configuration issues

### **Current Status:**
- ✅ macOS: roslyn.nvim + decompilation navigation works perfectly
- ❌ WSL2: Same config fails to navigate into decompiled sources
- ✅ Environment mapped: Complete dotfiles and config understanding
- ✅ Path documented: macOS temp file structure recorded

### **WSL2 Investigation Plan:**
1. **Test roslyn.nvim behavior** - Try "Go to Definition" on external libraries
2. **Check temp file creation** - Look for `/tmp/MetadataAsSource/...` or similar
3. **Compare paths** - Document WSL2 decompilation paths vs macOS baseline
4. **Debug environment** - Check PATH, permissions, file system mounting
5. **Verify LSP binary** - Ensure Roslyn LSP works correctly in WSL2

### **Key Files to Reference:**
- `lua/plugins/roslyn.lua` - roslyn.nvim configuration
- `after/plugin/roslyn_auto_target.lua` - Auto-targeting script
- `~/dotfiles/.zshrc` - Environment setup with .NET tools
- This file (`RoslynFix.md`) - Investigation notes and findings

### **Commands to Test:**
```bash
# Check if decompilation creates temp files
ls -la /tmp/MetadataAsSource* 2>/dev/null || echo "No MetadataAsSource found"

# Check .NET tools availability
which dotnet
dotnet --version

# Check Roslyn LSP in Mason
ls -la ~/.local/share/nvim/mason/bin/roslyn*

# Test file path when decompilation works
# In Neovim after gd: :echo expand('%:p')
```

**Goal**: Get roslyn.nvim decompilation navigation working on WSL2 to match macOS functionality.

### **Health Check Available:**
```vim
:checkhealth wsl2_roslyn
```
Comprehensive diagnostics for WSL2 Roslyn setup including:
- WSL2 environment detection
- wslpath functionality testing
- Roslyn LSP configuration
- WSL2 fix implementation status
- Diagnostic tools availability
- File system permissions

---

## 🎯 **SOLUTION IMPLEMENTED** (2025-06-26)

### **Root Cause Identified:**
The issue was **WSL2 cross-filesystem path translation** between:
- **Windows project paths**: `/mnt/c/projects/acculynx/...` (where C# projects live)
- **Linux temp paths**: `/tmp/MetadataAsSource/...` (where Roslyn creates decompiled files)
- **LSP communication**: Path format confusion between Windows and WSL2

### **Key Discovery with `wslpath`:**
```bash
# WSL temp path: /tmp/MetadataAsSource
# Windows equivalent: C:\Users\BrandonHolbert\AppData\Local\lxss\tmp\MetadataAsSource
```
**Problem**: Roslyn LSP returns Windows-style paths, but Neovim expects WSL paths!

### **Key Discovery:**
✅ **Decompilation IS working** - Roslyn LSP creates files in `/tmp/MetadataAsSource/`
❌ **Navigation was failing** - Neovim couldn't properly handle cross-filesystem navigation

### **Solutions Implemented:**

#### 1. **Enhanced Roslyn Configuration** (`lua/plugins/roslyn.lua`)
- Added WSL2 detection and specific configuration
- Enhanced settings for WSL2 environments
- Improved path handling for cross-filesystem projects

#### 2. **WSL2-Specific LSP Handler** (`after/plugin/wsl2_roslyn_fix.lua`)
- **`wslpath` integration** for automatic Windows ↔ WSL path conversion
- Custom `textDocument/definition` handler for WSL2
- Enhanced decompiled file opening with proper error handling
- Automatic readonly/modifiable settings for decompiled sources
- Buffer-local keymaps for decompiled files (`q` to close)
- `:TestWSLPath` command for debugging path conversion

#### 3. **Enhanced Auto-targeting** (`after/plugin/roslyn_auto_target.lua`)
- WSL2-aware solution detection
- Longer initialization delays for WSL2 environments
- Preference for Windows-mounted solutions when in WSL2

#### 4. **Diagnostic Tools** (`lua/user/roslyn_diagnostics.lua`)
- `:RoslynDiagnostics` command to troubleshoot issues
- `<leader>ard` keymap for quick diagnostics
- Comprehensive environment and LSP status checking

### **Testing Instructions:**
1. **Restart Neovim** to load new configurations
2. **Open a C# file** from Windows project (e.g., `/mnt/c/projects/acculynx/...`)
3. **Test navigation**: Place cursor on external library type (e.g., `List`, `Console`, `Dictionary`)
4. **Press `gd`** to go to definition
5. **Verify**: Should open decompiled source in `/tmp/MetadataAsSource/...`

### **✅ SUCCESS CONFIRMED (2025-06-26):**
**DECOMPILATION NAVIGATION IS NOW WORKING!** 🎉
- Successfully navigated to decompiled definitions from Windows C# projects
- Path conversion working correctly between WSL2 and Windows filesystems
- Roslyn LSP properly initializing for Windows-mounted solutions

### **Troubleshooting:**
- Run `:RoslynDiagnostics` to check environment
- Use `<leader>ard` for quick diagnostics
- Check `:LspInfo` for Roslyn LSP status
- Restart LSP with `:LspRestart` if needed

### **Expected Behavior:**
- ✅ Decompiled files open in readonly buffers
- ✅ Proper syntax highlighting for C# decompiled sources
- ✅ `q` keymap to close decompiled buffers
- ✅ Auto-targeting works for Windows-mounted solutions
- ✅ Enhanced error messages and notifications

---

## 🚀 **PERFORMANCE OPTIMIZATION** (2025-06-28)

### **Performance Problem Identified:**
After fixing decompilation navigation, discovered **severe performance issues**:
- **Original**: 46+ seconds from Neovim start to full LSP functionality
- **User Impact**: Unacceptable development workflow delays
- **Environment**: WSL2, Windows project on `/mnt/c/`, 11-project solution

### **Investigation Process:**

#### **Phase 1: Root Cause Analysis**
- **Initial assumption**: LSP attach was slow
- **Reality discovered**: LSP attach is fast (~5s), **project initialization** is slow (~41s)
- **Key insight**: The issue is solution loading, not LSP communication

#### **Phase 2: Baseline Testing**
- **All features disabled**: 18.76 seconds (absolute minimum possible)
- **Critical finding**: LSP features only cost ~2 seconds total
- **Real bottleneck**: Solution loading and project metadata processing

#### **Phase 3: Systematic Optimization**
Applied comprehensive performance optimizations across multiple areas.

### **Optimizations Applied:**

#### **1. Lazy Loading Enhancements**
```lua
-- Added to lua/plugins/roslyn.lua
ft = "cs",                                    -- Load on C# filetype
event = { "BufReadPre *.cs", "BufNewFile *.cs" }, -- Load on C# file events
lazy = true,                                  -- Prevent eager loading
```

#### **2. Performance-Tuned Configuration**
- **broad_search**: `false` (was: `true`) - Disable for faster startup
- **debug**: `false` (was: `true`) - Disable debug mode for speed
- **filewatching**: `false` (was: `true`) - Causes WSL2 slowdowns

#### **3. Heavy Features Disabled During Init**
```lua
-- Disabled during initialization (auto re-enabled after 5s)
dotnet_provide_regex_completions = false
dotnet_show_completion_items_from_unimported_namespaces = false
dotnet_enable_references_code_lens = false
csharp_enable_inlay_hints_for_implicit_variable_types = false
dotnet_search_reference_assemblies = false
dotnet_navigate_to_decompiled_sources = false
```

#### **4. Analysis Scope Optimization**
```lua
-- Limited to open files only (was: fullSolution)
dotnet_analyzer_diagnostics_scope = "openFiles"
dotnet_compiler_diagnostics_scope = "openFiles"
```

#### **5. Project Loading Optimizations**
```lua
dotnet_load_projects_on_demand = true        -- Load projects only when needed
dotnet_enable_package_auto_restore = false   -- Disable NuGet restore during init
dotnet_analyze_open_documents_only = true    -- Only analyze open documents
dotnet_enable_import_completion = false      -- Disable during init
dotnet_enable_analyzers_support = false     -- Disable analyzers during init
```

#### **6. WSL2 Environment Optimizations**
```bash
# Added to after/plugin/wsl2_roslyn_fix.lua
DOTNET_SKIP_FIRST_TIME_EXPERIENCE = "true"
DOTNET_CLI_TELEMETRY_OPTOUT = "true"
MSBUILD_DISABLE_SHARED_BUILD_PROCESS_LANGUAGE_SERVICE = "1"
DOTNET_USE_POLLING_FILE_WATCHER = "true"
MSBUILD_CACHE_ENABLED = "true"
DOTNET_ReadyToRun = "0"
```

#### **7. Auto Re-enable System**
- Heavy features automatically restored 5 seconds after LSP attach
- Provides fast startup with full functionality after project loads
- User notification: "🚀 Roslyn heavy features enabled after initialization"

#### **8. Smart Notification System**
- Only shows notifications when in .NET projects or debug mode enabled
- Reduces noise in non-C# development environments
- Debug mode toggle: `:WSL2RoslynDebug [on|off]`

### **Performance Results:**

#### **Timeline:**
- **Original**: 46+ seconds to functionality
- **Baseline (all features off)**: 18.76 seconds (minimum possible)
- **Optimized**: ~21 seconds (**56% improvement**)

#### **Breakdown:**
- **LSP Attach**: ~5 seconds (fast and consistent)
- **Project Initialization**: ~16 seconds (down from 41s)
- **Feature Cost**: ~2 seconds (minimal impact)

### **✅ SUCCESS METRICS:**
- **56% performance improvement** achieved
- **Consistent ~21 second** initialization time
- **Full functionality** preserved with auto re-enable
- **User workflow** significantly improved
- **Well-documented** and maintainable solution

### **Testing Commands:**
```vim
:RoslynTiming                    # Check current LSP status and timing
:WSL2RoslynDebug on             # Enable debug notifications
:messages                       # View all recent notifications
```

### **Workflow Testing:**
```bash
cd "/mnt/c/projects/acculynx/Microservices/App Connections/connectionengine"
nvim .
# <leader><leader> to open .cs file
# Wait for "Roslyn project initialization complete"
# :RoslynTiming to check performance
```

### **Future Optimization Strategies:**
**Target**: Reduce from current 21s closer to 18.76s baseline

#### **Investigation Areas:**
1. **Project-level loading** instead of solution-level for faster initial attach
2. **NuGet package caching** optimizations (local cache, offline mode)
3. **MSBuild incremental compilation** settings
4. **Alternative LSP servers** (csharp-ls, omnisharp) for comparison
5. **WSL2 filesystem performance** tuning (mount options, disk caching)
6. **Solution file preprocessing** to reduce project discovery time
7. **Roslyn workspace warm-up** strategies
8. **Custom LSP initialization** sequencing for large solutions
9. **Memory-mapped file optimizations** for cross-filesystem access
10. **Parallel project loading** if supported by future Roslyn versions

### **Key Insights:**

#### **What Worked:**
- **Lazy loading**: Prevents unnecessary startup overhead
- **Feature toggling**: Disable expensive features during init, re-enable after
- **Scope limitation**: Analyze only open files instead of full solution
- **Environment tuning**: WSL2-specific optimizations for cross-filesystem performance

#### **What Didn't Work:**
- **Aggressive feature disabling**: Only saved ~2 seconds total
- **Project-level root detection**: Would break cross-project references
- **Complete analysis disabling**: Minimal impact on startup time

#### **Fundamental Limits:**
- **WSL2 filesystem overhead**: Cross-filesystem performance on `/mnt/c/`
- **Large solution complexity**: 11 projects with interdependencies
- **NuGet package resolution**: Cannot be completely avoided
- **Baseline minimum**: ~18.76s appears to be realistic floor

---

## 🔧 **SMART NOTIFICATION UTILITY** (2025-06-28)

### **Generalized Solution:**
Created a reusable `utils.smart_notify` module that other plugins can use for context-aware notifications.

### **Key Features:**
- **Context-aware**: Only shows notifications in relevant project directories
- **Debug mode support**: Toggle verbose notifications per plugin
- **Always show errors**: Critical issues always visible
- **Predefined configs**: Ready-to-use for common project types (.NET, Node.js, Python, Rust, Go)
- **Easy migration**: Simple replacement for `vim.notify`

### **Usage Examples:**
```lua
-- Use predefined configurations
local smart_notify = require('utils.smart_notify')
smart_notify.dotnet("Building project...", vim.log.levels.INFO)
smart_notify.nodejs("Installing dependencies...", vim.log.levels.INFO)

-- Create custom notifier
local my_notify = smart_notify.create_notifier({
  debug_var = "my_plugin_debug",
  project_patterns = { "*.myconfig" },
  title = "My Plugin"
})
my_notify("Custom notification", vim.log.levels.INFO)

-- Create debug command
smart_notify.create_debug_command("MyPluginDebug", "my_plugin_debug", "My Plugin")
```

### **Benefits:**
- **Reduces notification noise** in non-relevant directories
- **Consistent UX** across all plugins
- **User control** via debug commands
- **Easy adoption** for existing plugins

### **Files:**
- `lua/utils/smart_notify.lua` - Main utility module
- `lua/utils/smart_notify_examples.lua` - Usage examples and patterns

---

*Last Updated: 2025-06-28*
*Branch: roslyn_proj_attach*
*Status: Production Ready - Both decompilation navigation AND performance optimized*
*New: Smart notification utility available for other plugins*

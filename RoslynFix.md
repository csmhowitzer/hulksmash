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

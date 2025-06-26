---@diagnostic disable: undefined-field
-- Tests for WSL2 decompiled file handling
-- Run with: :PlenaryBustedFile %
--
-- Note: Uses template-based paths with placeholders ([hash], [user]) to ensure
-- cross-platform compatibility between WSL2 and macOS environments

local eq = assert.are.same

describe("WSL2 Decompiled File Pattern Detection", function()

  describe("decompiled file pattern matching", function()
    it("should detect MetadataAsSource patterns in paths", function()
      local test_patterns = {
        "/tmp/MetadataAsSource/hash/file.cs",
        "/var/tmp/MetadataAsSource/another/path.cs",
        "C:\\Users\\test\\AppData\\Local\\lxss\\tmp\\MetadataAsSource\\file.cs",
        "/some/path/DecompilationMetadataAsSourceFileProvider/file.cs"
      }

      for _, path in ipairs(test_patterns) do
        local is_decompiled = path:match("/tmp/MetadataAsSource/") or
                             path:match("MetadataAsSource") or
                             path:match("DecompilationMetadataAsSourceFileProvider")

        eq(true, is_decompiled ~= nil, "Should detect decompiled file: " .. path)
      end
    end)

    it("should not detect regular files as decompiled", function()
      local regular_patterns = {
        "/home/user/project/file.cs",
        "/mnt/c/projects/regular/file.cs",
        "/tmp/regular_file.cs",
        "C:\\projects\\normal\\file.cs"
      }

      for _, path in ipairs(regular_patterns) do
        local is_decompiled = path:match("/tmp/MetadataAsSource/") or
                             path:match("MetadataAsSource") or
                             path:match("DecompilationMetadataAsSourceFileProvider")

        eq(nil, is_decompiled, "Should not detect regular file as decompiled: " .. path)
      end
    end)

    it("should handle URI to filename conversion patterns", function()
      local uri_templates = {
        "file:///tmp/MetadataAsSource/[hash]/Console.cs",
        "file:///C:/Users/[user]/AppData/Local/lxss/tmp/MetadataAsSource/file.cs"
      }

      for _, template in ipairs(uri_templates) do
        -- Generate test URI with placeholder values
        local test_uri = template:gsub("%[hash%]", "test123")
                               :gsub("%[user%]", "testuser")

        local is_decompiled_uri = test_uri:match("MetadataAsSource")
        eq(true, is_decompiled_uri ~= nil, "Should detect decompiled URI: " .. test_uri)
      end
    end)

    it("should detect various MetadataAsSource directory structures", function()
      local metadata_patterns = {
        "/tmp/MetadataAsSource/[hash]/DecompilationMetadataAsSourceFileProvider/[hash]/Console.cs",
        "/var/tmp/MetadataAsSource/[hash]/DecompilationMetadataAsSourceFileProvider/[hash]/String.cs",
        "C:\\Users\\[user]\\AppData\\Local\\lxss\\tmp\\MetadataAsSource\\[hash]\\List.cs"
      }

      for _, pattern in ipairs(metadata_patterns) do
        -- Replace placeholders with realistic values for testing
        local test_path = pattern:gsub("%[hash%]", "abc123def456")
                                :gsub("%[user%]", "testuser")

        local has_metadata = test_path:match("MetadataAsSource") and
                           (test_path:match("DecompilationMetadataAsSourceFileProvider") or test_path:match("%.cs$"))

        eq(true, has_metadata ~= nil, "Should detect metadata structure: " .. test_path)
      end
    end)
  end)

  describe("path fallback logic", function()
    it("should generate fallback paths for MetadataAsSource files", function()
      local original_path = "/some/weird/path/MetadataAsSource/test/Console.cs"
      local expected_fallback = "/tmp/MetadataAsSource/test/Console.cs"

      local fallback = original_path:gsub("^.*MetadataAsSource", "/tmp/MetadataAsSource")
      eq(expected_fallback, fallback)
    end)

    it("should handle paths with MetadataAsSource suffix extraction", function()
      -- Use generic path structure that works across environments
      local test_path = "C:\\Users\\[user]\\AppData\\Local\\lxss\\tmp\\MetadataAsSource\\[hash]\\file.cs"
      local actual_path = test_path:gsub("%[user%]", "testuser"):gsub("%[hash%]", "abc123")

      local suffix = actual_path:match("MetadataAsSource.*") or ""

      eq(true, suffix:len() > 0, "Should extract MetadataAsSource suffix")
      eq(true, suffix:match("MetadataAsSource") ~= nil, "Suffix should contain MetadataAsSource")
    end)
  end)
end)

-- Tests for m_roslyn.auto_insert_docs module
-- Following established testing patterns with M._function_name exposure

describe("m_roslyn.auto_insert_docs", function()
  local auto_insert_docs
  
  before_each(function()
    -- Reset module state
    package.loaded["m_roslyn.auto_insert_docs"] = nil
    auto_insert_docs = require("m_roslyn.auto_insert_docs")
  end)
  
  describe("should_trigger_docs", function()
    it("should trigger on third slash", function()
      assert.is_true(auto_insert_docs._should_trigger_docs("//", 2, "/"))
    end)
    
    it("should not trigger on first slash", function()
      assert.is_false(auto_insert_docs._should_trigger_docs("", 0, "/"))
    end)
    
    it("should not trigger on second slash", function()
      assert.is_false(auto_insert_docs._should_trigger_docs("/", 1, "/"))
    end)
    
    it("should not trigger on non-slash character", function()
      assert.is_false(auto_insert_docs._should_trigger_docs("//", 2, "a"))
    end)
    
    it("should handle indented slashes", function()
      assert.is_true(auto_insert_docs._should_trigger_docs("    //", 6, "/"))
    end)
    
    it("should not trigger if slashes are not consecutive", function()
      assert.is_false(auto_insert_docs._should_trigger_docs("/ /", 3, "/"))
    end)
    
    it("should handle mixed content before slashes", function()
      assert.is_true(auto_insert_docs._should_trigger_docs("code //", 7, "/"))
    end)
  end)
  
  describe("configuration", function()
    it("should use default configuration", function()
      auto_insert_docs.setup()
      local config = auto_insert_docs.get_config()
      
      assert.is_true(config.enabled)
      assert.equals("///", config.trigger_pattern)
      assert.is_false(config.debug)
    end)
    
    it("should merge custom configuration", function()
      auto_insert_docs.setup({
        enabled = false,
        debug = true,
        trigger_pattern = "///"
      })
      
      local config = auto_insert_docs.get_config()
      assert.is_false(config.enabled)
      assert.is_true(config.debug)
      assert.equals("///", config.trigger_pattern)
    end)
    
    it("should preserve unspecified defaults", function()
      auto_insert_docs.setup({ debug = true })
      local config = auto_insert_docs.get_config()
      
      assert.is_true(config.enabled) -- default preserved
      assert.is_true(config.debug)   -- custom value
      assert.equals("///", config.trigger_pattern) -- default preserved
    end)
  end)
  
  describe("enable/disable functionality", function()
    it("should enable documentation auto-insert", function()
      auto_insert_docs.setup({ enabled = false })
      auto_insert_docs.enable()
      
      local config = auto_insert_docs.get_config()
      assert.is_true(config.enabled)
    end)
    
    it("should disable documentation auto-insert", function()
      auto_insert_docs.setup({ enabled = true })
      auto_insert_docs.disable()
      
      local config = auto_insert_docs.get_config()
      assert.is_false(config.enabled)
    end)
    
    it("should toggle documentation auto-insert", function()
      auto_insert_docs.setup({ enabled = true })
      auto_insert_docs.toggle()
      
      local config = auto_insert_docs.get_config()
      assert.is_false(config.enabled)
      
      auto_insert_docs.toggle()
      local config2 = auto_insert_docs.get_config()
      assert.is_true(config2.enabled)
    end)
  end)
  
  describe("setup behavior", function()
    it("should not setup when disabled", function()
      auto_insert_docs.setup({ enabled = false })
      -- Should not create autocmds when disabled
      -- This is tested by checking that no errors occur and config is respected
      local config = auto_insert_docs.get_config()
      assert.is_false(config.enabled)
    end)
    
    it("should setup when enabled", function()
      auto_insert_docs.setup({ enabled = true })
      local config = auto_insert_docs.get_config()
      assert.is_true(config.enabled)
    end)
  end)
  
  describe("pattern matching edge cases", function()
    it("should handle empty line", function()
      assert.is_false(auto_insert_docs._should_trigger_docs("", 0, "/"))
    end)

    it("should handle line with only spaces", function()
      assert.is_false(auto_insert_docs._should_trigger_docs("   ", 3, "/"))
    end)

    it("should handle cursor at beginning", function()
      assert.is_false(auto_insert_docs._should_trigger_docs("//test", 0, "/"))
    end)

    it("should handle cursor in middle of existing slashes", function()
      -- Cursor between two slashes: "/|/"
      assert.is_false(auto_insert_docs._should_trigger_docs("//", 1, "/"))
    end)

    it("should handle multiple slash groups", function()
      -- Should trigger only for the current position
      assert.is_true(auto_insert_docs._should_trigger_docs("/// code //", 11, "/"))
    end)
  end)

  describe("template generation fallback", function()
    -- Mock buffer for testing
    local mock_bufnr = 1

    it("should generate basic summary template", function()
      -- Mock vim.api.nvim_buf_get_lines to return a simple class
      _G.vim = _G.vim or {}
      _G.vim.api = _G.vim.api or {}
      _G.vim.api.nvim_buf_get_lines = function(bufnr, start, end_line, strict)
        return {"public class TestClass"}
      end

      local template = auto_insert_docs._generate_documentation_template(mock_bufnr, 0)
      assert.is_not_nil(template:match("/// <summary>"))
      assert.is_not_nil(template:match("/// </summary>"))
    end)

    it("should generate template with parameters", function()
      _G.vim.api.nvim_buf_get_lines = function(bufnr, start, end_line, strict)
        return {"public string TestMethod(string name, int age)"}
      end

      local template = auto_insert_docs._generate_documentation_template(mock_bufnr, 0)
      assert.is_not_nil(template:match("/// <summary>"))
      assert.is_not_nil(template:match('<param name="name">'))
      assert.is_not_nil(template:match('<param name="age">'))
      assert.is_not_nil(template:match("/// <returns>"))
    end)

    it("should not add returns for void methods", function()
      _G.vim.api.nvim_buf_get_lines = function(bufnr, start, end_line, strict)
        return {"public void TestMethod(string name)"}
      end

      local template = auto_insert_docs._generate_documentation_template(mock_bufnr, 0)
      assert.is_not_nil(template:match("/// <summary>"))
      assert.is_not_nil(template:match('<param name="name">'))
      assert.is_nil(template:match("/// <returns>"))
    end)
  end)
end)

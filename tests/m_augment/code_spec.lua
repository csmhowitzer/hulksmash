---@diagnostic disable: undefined-field
-- Tests for m_augment.code module
-- Run with: :PlenaryBustedFile %

local eq = assert.are.same
local code = require("m_augment.code")

describe("m_augment.code.find_code_blocks", function()
  it("should find single code block", function()
    local lines = {
      "Here's some code:",
      "```lua",
      "print('hello')",
      "local x = 42",
      "```",
      "That was the code."
    }

    local blocks = code.find_code_blocks(lines)

    eq(1, #blocks)
    eq(2, blocks[1].start)
    eq(5, blocks[1].finish)
    eq("lua", blocks[1].lang)
    eq({"print('hello')", "local x = 42"}, blocks[1].content)
  end)

  it("should find multiple code blocks", function()
    local lines = {
      "First block:",
      "```python",
      "print('python')",
      "```",
      "Second block:",
      "```javascript",
      "console.log('js')",
      "```"
    }

    local blocks = code.find_code_blocks(lines)

    eq(2, #blocks)
    eq("python", blocks[1].lang)
    eq({"print('python')"}, blocks[1].content)
    eq("javascript", blocks[2].lang)
    eq({"console.log('js')"}, blocks[2].content)
  end)

  it("should handle 4-backtick code blocks", function()
    local lines = {
      "Code with 4 backticks:",
      "````lua path=file.lua mode=EDIT",
      "function test()",
      "  return true",
      "end",
      "````"
    }

    local blocks = code.find_code_blocks(lines)

    eq(1, #blocks)
    eq("lua", blocks[1].lang)
    eq({"function test()", "  return true", "end"}, blocks[1].content)
  end)

  it("should ignore unclosed code blocks", function()
    local lines = {
      "Unclosed block:",
      "```lua",
      "print('incomplete')",
      "-- no closing backticks"
    }

    local blocks = code.find_code_blocks(lines)

    eq(0, #blocks)
  end)

  it("should handle code blocks without language", function()
    local lines = {
      "No language specified:",
      "```",
      "some code",
      "```"
    }

    local blocks = code.find_code_blocks(lines)

    eq(1, #blocks)
    eq("text", blocks[1].lang)
    eq({"some code"}, blocks[1].content)
  end)
end)



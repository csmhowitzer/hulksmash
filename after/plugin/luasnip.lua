require("luasnip.session.snippet_collection").clear_snippets("lua")
require("luasnip.session.snippet_collection").clear_snippets("cs")

local ls = require("luasnip")

local s = ls.snippet
local i = ls.insert_node
local t = ls.text_node
local f = ls.function_node
local c = ls.choice_node

local fmt = require("luasnip.extras.fmt").fmt
local fmta = require("luasnip.extras.fmt").fmta
local rep = require("luasnip.extras").rep
local events = require("luasnip.util.events").events

local sn = ls.sn
local d = ls.dynamic_node

-- find the .csproj root folder for the given file the buffer resides in
local find_proj_root = function()
  local bufnr = vim.api.nvim_get_current_buf()
  local bufPath = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":h")
  vim.api.nvim_set_current_dir(bufPath)
  return vim.fs.root(bufPath, function(name)
    return name:match("%.csproj$") ~= nil
  end)
end

local get_proj_name = function()
  return string.gsub(vim.fn.fnamemodify(find_proj_root(), ":t"), ".csproj", "")
end

local get_parent_dir = function()
  local bufnr = vim.api.nvim_get_current_buf()
  local bufPath = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":h")
  local pathSplit = vim.split(bufPath, "/")
  return pathSplit[#pathSplit]
end

local get_file_name = function(position)
  return d(position, function()
    local bufnr = vim.api.nvim_get_current_buf()
    local bufName = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":t")
    local className = string.sub(bufName, 1, #bufName - 3)
    return sn(nil, t(className))
  end, {})
end

local get_namespace = function(position)
  return d(position, function()
    local parentDir = get_parent_dir()
    local projName = get_proj_name()

    return sn(nil, t(projName .. "." .. parentDir))
  end, {})
end

local function copy(args)
  return args[1]
end

ls.add_snippets("lua", {
  s("el", fmt("<%= {} %>{}", { i(1), i(0) })),
  s("ei", fmt("<%= if {} do %>{}<% end %>{}", { i(1), i(2), i(0) })),
  s("hello", { t('print("hello world")') }),
  s("fn", {
    -- Simple static text.
    t("//Parameters: "),
    -- function, first parameter is the function, second the Placeholders
    -- whose text it gets as input.
    f(copy, 2),
    t({ "", "function " }),
    -- Placeholder/Insert.
    i(1),
    t("("),
    -- Placeholder with initial text.
    i(2, "int foo"),
    -- Linebreak
    t({ ") {", "\t" }),
    -- Last Placeholder, exit Point of the snippet. EVERY 'outer' SNIPPET NEEDS Placeholder 0.
    i(0),
    t({ "", "}" }),
  }),
})

ls.add_snippets("cs", {
  s("hello", { t('print("hello csharp!")') }),
  s(
    "xuc",
    fmta(
      [[
        using Xunit;
        using static Xunit.Assert;

        namespace <a>;

        public class <b>
        {
            <c>
        }
      ]],
      {
        a = i(1, "namespaceName"),
        b = i(2, "ClassName"),
        c = i(3),
      }
    )
  ),
  s(
    "xuf",
    fmta(
      [[
          [Fact(DisplayName="<a>")]
          public void <b>_<c>() 
          {
              //Arrange
              <d>
              //Act

              //Assert
              Equal("", "I'm a test, and I'm not configured yet!!");
          }
      ]],
      {
        a = i(1, "Display Test Name"),
        b = i(2, "When"),
        c = i(3, "Then"),
        d = i(4),
      }
    )
  ),
  s(
    "xut",
    fmta(
      [[
          [Theory]
          [InlinData(<a>)]
          public void <b>_<c>(<d> <e>) 
          {
              //Arrange
              <f>
              //Act

              //Assert
              Equal("", "I'm a test, and I'm not configured yet!!");
          }
      ]],
      {
        a = i(1, "TestData"),
        b = i(2, "When"),
        c = i(3, "Then"),
        d = i(4, "type"),
        e = i(5, "name"),
        f = i(6),
      }
    )
  ),
  s(
    "exc",
    fmta(
      [[
        public class <a>_Exception : Exception
        {
            public <b>() : base() { }
            public <c>(string message) : base(message) { }
        }
      ]],
      {
        a = i(1, "ClassName"),
        b = rep(1),
        c = rep(1),
      }
    )
  ),
  s(
    "err",
    fmta(
      [[
        public sealed class <a>Exception() : Exception("<b>");
        <c>
      ]],
      {
        a = i(1, "ClassName"),
        b = i(2, "Error Message"),
        c = i(3),
      }
    )
  ),
  s(
    "class",
    fmta(
      [[
        namespace <a>;

        public class <b>
        {
            <c>
        }
      ]],
      {
        a = get_namespace(1),
        b = get_file_name(2),
        c = i(3),
      }
    )
  ),
  s(
    {
      trig = "///",
      descr = "XML comment summary",
    },
    fmt(
      [[
    /// <summary>
    /// {}
    /// </summary>{}
    ]],
      {
        i(1),
        i(2),
      }
    )
  ),
  s(
    "XML XML",
    fmt([[{}]], {
      c(1, {
        sn(
          nil,
          fmt(
            [[
                /// <summary>
                /// {}
                /// </summary>
            ]],
            {
              i(1, "Summary of the item"),
            }
          )
        ),

        sn(
          nil,
          fmt(
            [[
                /// <remarks>
                /// {}
                /// </remarks>
            ]],
            {
              i(1, "Supplemenary info about the item"),
            }
          )
        ),

        sn(
          nil,
          fmt(
            [[
                /// <param name="{}">{}</param>
            ]],
            {
              i(1),
              i(2),
            }
          )
        ),

        sn(
          nil,
          fmt(
            [[
                /// <typeparam name="{}">{}</typeparam>
            ]],
            {
              i(1),
              i(2),
            }
          )
        ),

        sn(
          nil,
          fmt(
            [[
                /// <returns>{}</returns>
            ]],
            {
              i(1, "Specify the return value"),
            }
          )
        ),

        sn(
          nil,
          fmt(
            [[
                /// <exception cref="{}">{}</exception>
            ]],
            {
              i(1, "Exception type"),
              i(2, "Circumstancs for exception"),
            }
          )
        ),

        sn(
          nil,
          fmt(
            [[
                /// <seealso cref="{}"/>
            ]],
            {
              i(1),
            }
          )
        ),

        sn(
          nil,
          fmt(
            [[
                /// <para>
                /// {}
                /// </para>
            ]],
            {
              i(1, "Paragraph"),
            }
          )
        ),

        sn(
          nil,
          fmt(
            [[
                /// <code>
                /// {}
                /// </code>
            ]],
            {
              i(1, "Code block"),
            }
          )
        ),

        sn(
          nil,
          fmt(
            [[
                /// <paramref name="{}"/>
            ]],
            {
              i(1, "Specifies a reference to a parameter in the same documentation comment"),
            }
          )
        ),

        sn(
          nil,
          fmt(
            [[
                /// <typeparamref name="{}"/>
                ]],
            {
              i(1, "Specifies a reference to a type parameter in the same documentation comment"),
            }
          )
        ),

        sn(
          nil,
          fmt(
            [[
                /// <c>{}</c>
                ]],
            {
              i(1, "Specifies a reference to a type parameter in the same documentation comment"),
            }
          )
        ),

        sn(
          nil,
          fmt(
            [[
                /// <see cref="{}">{}</see>
                ]],
            {
              i(1, "reference"),
              i(2, "Specifies a reference to a type parameter in the same documentation comment"),
            }
          )
        ),

        --
      }),
    })
  ),
})

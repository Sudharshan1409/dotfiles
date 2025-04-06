-- lua/my_snippets.lua
local ls = require('luasnip')
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local fmt = require("luasnip.extras.fmt").fmt
local f = ls.function_node

ls.add_snippets("all", {
    s("ternary", {
        -- equivalent to "${1:cond} ? ${2:then} : ${3:else}"
        i(1, "cond"), t(" ? "), i(2, "then"), t(" : "), i(3, "else")
    }),
    s("sud", {
        t("Sudharshan V")
    })
})

-- for js files

ls.add_snippets('javascript', {
    s("todo", {
        t("// TODO: "), i(1, "todo")
    }),
    s("log", {
        t("console.log("), i(1, "value"), t(");")
    }),
    s("fn", {
        t("const "), i(1, "name"), t(" = ("), i(2, "args"), t(") => {"), i(0), t("};")
    }),
    s("afn", {
        t("const "), i(1, "name"), t(" = async ("), i(2, "args"), t(") => {"), i(0), t("};")
    }),
})

-- for ts files

ls.add_snippets('typescript', {
    s("todo", {
        t("// TODO: "), i(1, "todo")
    }),
    s("log", {
        t("console.log("), i(1, "value"), t(");")
    }),
    s("fn", {
        t("const "), i(1, "name"), t(" = ("), i(2, "args"), t(") => {"), i(0), t("};")
    }),
    s("afn", {
        t("const "), i(1, "name"), t(" = async ("), i(2, "args"), t(") => {"), i(0), t("};")
    }),
})

-- for lua files

ls.add_snippets('lua', {
    s("todo", {
        t("-- TODO: "), i(1, "todo")
    }),
    s("req", fmt([[local {} = require("{}")]], { f(function(import_name)
        local parts = vim.split(import_name[1][1], ".", { plain = true })
        return parts[#parts] or ""
    end, { 1 }), i(1) })),
})

-- for python files

ls.add_snippets('python', {
    s("todo", {
        t("# TODO: "), i(1, "todo")
    }),
    s("fn", {
        t("def "), i(1, "name"), t("("), i(2, "args"), t("):"), i(0)
    }),
    s("afn", {
        t("async def "), i(1, "name"), t("("), i(2, "args"), t("):\n"), i(0)
    }),
})

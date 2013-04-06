on("load", 
    function()
        for k, v in pairs(string) do
            registerHook("string_"..k, v)
        end
        for k, v in pairs(table) do
            registerHook("table_"..k, v)
        end
        registerHook("lua_print", print)
        registerHook("lua_unpack", unpack)
        registerHook("lua_pairs", pairs)
        registerHook("lua_next", next)
        registerHook("lua_tostring", tostring)
        registerHook("lua_tonumber", tonumber)
        registerHook("lua_type", type)
        registerHook("lua_error", function(err, level)
            error(err, 2 + (level or 1))
        end)
        registerHook("yield", coroutine.yield)
    end
)
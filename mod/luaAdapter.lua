on("load", 
    function()
        for k, v in pairs(string) do
            registerUHook("string_"..k, v)
        end
        for k, v in pairs(table) do
            registerUHook("table_"..k, v)
        end
        registerUHook("lua_print", print) -- debug code, TODO: remove
        registerUHook("lua_unpack", unpack)
        registerUHook("lua_pairs", pairs)
        registerUHook("lua_next", next)
        registerUHook("lua_tostring", tostring)
        registerUHook("lua_tonumber", tonumber)
        registerUHook("lua_type", function(obj)
            if {userdata = 1, table = true}[type(obj)] then
                local mt = getmetatable(obj)
                if mt and mt.__type then return mt.__type end
            end
            return type(obj)
        end)
        registerUHook("lua_error", function(err, level)
            -- todo: fancy stuff
            error(err, 2 + (level or 1))
        end)
        registerUHook("yield", coroutine.yield)
    end
)
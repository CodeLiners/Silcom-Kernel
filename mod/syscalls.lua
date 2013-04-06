on("enable", 
    function()
        usermode_set("syscall", function(hook, ...)
            return mod_getHook(hook)(...)
        end)
    end
)

on("disable", 
    function()
        usermode_set("syscall", nil)
    end
)
on("enable", 
    function()
        usermode_set("syscall", function(hook, ...)
            hook = mod_getHook(hook)
            if hook.meta.syscall then
                return hook.meta.func(...)
            else
                error("Unknown syscall")
            end
        end)
    end
)

on("disable", 
    function()
        usermode_set("syscall", nil)
    end
)
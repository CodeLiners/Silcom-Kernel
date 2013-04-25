local modList = {}
local myG = {_G = _G}
local hookList = {}
setmetatable(myG._G, {__index = _G, __pairs = _G, __newindex = rawset})

local callbacks = {

    enable = function(module, ...)
        if not modList[module] then return false, "module not loaded" end
        mod_handleEvent(module, "enable")
        if modList[module].tid then
            thread_resume(modList[module].tid, ...)
        end
        modList[module].enabled = true
        return true
    end,

    disable = function(module)
        if not modList[module] then return false, "module not loaded" end
        mod_handleEvent(module, "disable")
        if modList[module].tid then
            thread_suspend(modList[module].tid)
        end
        modList[module].enabled = false
        return true
    end,

    init = function(module)
        if not modList[module] then return false, "module not loaded" end
        return pcall(mod_handleEvent(module, "init"))
    end

    postInit = function(module)
        if not modList[module] then return false, "module not loaded" end
        return pcall(mod_handleEvent(module, "postInit"))
    end

    load = function(module, ...)
        if modList[module] then error("already loaded") end
        local mod, err = loadfile("/boot/mod/"..module..".lua")
        if not mod then error(err) end
        local modEnv = setmetatable({_G = myG}, {__index = _G})
    
        function modEnv.on( event, handler )
            modList[module].handlers[event] = modList[module].handlers[event] or {}
            table.insert( modList[module].handlers[event], handler 
        end

        function modEnv.throw(event, ...)
            mod_event(module, event, ...)
        end

        local function registerHook(hook, func, meta)
            if not hookList[hook] then
                modList[module].hooks[hook] = {func = func, meta = meta or {}, module = module}
                hookList[hook] = modList[module].hooks[hook]
            else
                return hook.." was already registered by module '"..hookList[hook].module.."'"
            end
        end

        function modEnv.registerHook(hooks, p2, p3)
            local func, meta
            utils_checkType(hooks, {"table", "string"}, 1, 3)
            utils_checkType(p2, {"nil", "table", "function"}, 2, 3)
            utils_checkType(p3, {"nil", "function"}, 3, 3)
            if type(p2) == "table" then
                meta = p2
                func = p3
            else
                meta = {}
                func = p2
            end
            local response
            if type(hooks) == "table" then
                local responseTable = {}
                for h, f in pairs(hooks) do
                    table.insert(responseTable, registerHook(h, f, meta))
                end
                if responseTable[1] then
                    response = ""
                    for k, v in ipairs(responseTable) do
                        response = response..v.."\n"
                    end
                end
            else
                utils_checkType(func, {"function"}, 2, 3)
                return registerHook(hooks, func, meta)
            end
        end

        function modEnv.registerUHook(hooks, func)
            retrun modEnv.registerHook(hooks, {syscall = true}, func)
        end

        --[[function modEnv.registerKernelHook(hooks, func)
            utils_checkType(hooks, {"table", "string"}, 1, 3)
            utils_checkType(func, {"nil", "function"}, 2, 3)            
            local response
            if type(hooks) == "table" then
                local responseTable = {}
                for h, f in pairs(hooks) do
                    table.insert(responseTable, registerHook(h, f, true))
                end
                if responseTable[1] then
                    response = ""
                    for k, v in ipairs(responseTable) do
                        response = response..v.."\n"
                    end
                end
                return response
            else
                utils_checkType(func, {"function"}, 2, 3)
                return registerHook(hooks, func, true)
            end
        end]]

        modList[module] = {handlers = {}, enabled = false, hooks = {}}
        setfenv(mod, modEnv)
        ok, err = pcall(mod, ...)
        if  ok then 
            mod_handleEvent(module, "load")
            if type(modEnv.run) == "function" then
                modList[module].tid = thread_create(modEnv.run, 0, nil, modEnv)
            end
            return true
        else
            modList[module] = nil
            return false, err
        end
    end,

    unload = function(module)
        if mod_isEnabled(module) then mod_handleEvent(module, "disable") end
        mod_handleEvent(module, "unload")
        modList[module] = nil
    end,

    reload = function(module)
        callbacks.unload(module)
        callbacks.load(module)
    end,

    message = function(module, ...)
        if not modList[module] then return false, "module not loaded" end
        mod_handleEvent(module, "message", ...)
        return true
    end

}

function mod_isLoaded(name)
    return modList[name] and true or false
end

function mod_isEnabled(name)
    return (modList[name] or false) and modList[name].enabled
end

function mod_event(module, event, ...)
    if module then
        if modList[module] then
            return pcall(callbacks[event], module, ...)
        end
    else
        local response = {}
        for module, v in pairs(modList) do
            response[module] = pcall(callbacks[event], k, ...)
        end
        return response
    end
end

function mod_getList()
    local list = {}
    for k, v in pairs(modlist) do
        table.insert(list, k)
    end
    return list
end

function mod_getHook(hook)
    return hookList[hook]
end

function mod_handleEvent(module, event, ...)
    if modList[module].handlers[event] then
        for k, v in ipairs(modList[module].handlers[event]) do
            v(...)
        end
    end
end

function mod_registerCallBack(name, func)
    if not callbacks[name] then
        callbacks[name] = func
        return true
    end
    return false
end
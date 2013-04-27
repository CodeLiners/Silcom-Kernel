KERNEL_VERSION = "1.0"
KERNEL_DIR = KERNEL_DIR or "/boot"

local constants = {
    LF = string.char(10),
    CR = string.char(11),
}
local ascii = {
    LF = 10,
    CR = 11,
    ESC = 27
}

for k, v in pairs(constants) do
    rawset(_G, k, v)
end     

for k, v in pairs(ascii) do
    v_ = string.char(v)
    rawset(_G, k, v_)
    ascii[k] = v_
end 

local function loadCore()
    local coremods = {
        "vfs.lua",
        "utils",
        "event",
        "threading",
        "process",
        "streams",
        "mod"
    }
    for k, v in ipairs(coremods) do
        local coremod = loadfile(KERNEL_DIR.."/core/"..v..".lua")
        setfenv(coremod, _G)
        coremod()
    end
end

local function doModCallBack(callback, lang)
    print(lang[1])
    local modList = mod_getList()
    if callback == "load" then
        modList = fs.list(KERNEL_DIR.."/mod")
        for k, v in pairs(modList) do
            v = v:gsub("%.lua$","")
        end
    end
    for k, v in ipairs(modlist) do
        local ok, err = mod_event(module, callback, "KernelBoot")
        if not ok then 
            error("Couldn't "..lang[2].." '"..module.."'. The module crashed with the error: "..err)
        else
            print(module.." was "..lang[3].." successfully.")
        end
    end
    print(#modlist.." Modules were "..lang[3].." successfully.")
end


-- TODO: move to init process
function run()
    print("Silcom Kernel "..KERNEL_VERSION.." booting...")

    loadCore()

    local initproc
    local function createAndRunThread(func, env)
        if not initproc then 
            process_create(func, nil, "kernel", 0, nil, nil, nil, nil, "init", {tenv = env})
            initproc = true
        else
            local t = thread_create(func, 0, nil, env)
            thread_resume(t)
        end
    end
    rawset(_G, "kernel_createAndRunThread", createAndRunThread)

    doModCallBack("load", {"Attempting to load Modules.", "load", "loaded"})
    doModCallBack("init", {"Starting Initialization.", "initialize", "initialize"})
    doModCallBack("postInit", {"Starting Post-Initialization.", "post-initialize", "post-initialized"})
    doModCallBack("enable", {"Attempting to enable Modules.", "enable", "enabled"})

    print("Starting task scheduler...")
    thread_startEngine()
    error("Thread engine stopped somehow")
end

local s, m = pcall(run)
if not s then 
    printError("[Kernel Panic] "..(m or "Unknown Error."))
    printError("Please report on the Silcom issue tracker and reboot.")
    while true do
        coroutine.yield()
    end
end

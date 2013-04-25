--[[
    Serves an api for processes
]]

local processes = {}
local processlist = {}
local envsetupcallbacks = {}

function process_exists(pid)
    return (processes[pid] and true or false)
end

function process_getRunning()
    return thread_get(thread_getRunning()).pid
end

function process_create(func, uid, mode, forcepid, parent, args, myterm, envvars, name, params)
    params = params or {}
    if not (mode and ({kernel = true, user = true})[mode]) then
        error("Invalid mode")
    end
    args = utils_checkType(args, {"table", "nil"}, 6, nil, "native/process_create") or {}
    --print(3)
    local id = forcepid or math.random(1, 99999999)
    --print(5)
    local env

    local function pcreatecallback(...)
        if mode == "user" then 
            env = {}
            for k, v in ipairs(envsetupcallbacks) do
                v(uid, id, env)
            end
            --for k, v in pairs(env) do print(k, " ", v) end
            processes[id].env = env
            setfenv(func, env)
        end
        func(...)
    end

    --print(4)
    processes[id] = {
        pid = id,
        uid = uid,
        mode = mode,
        eventQueue = {},
        env = env or _G,
        threads = {},
        stdoutbuff = "",
        stdinbuff = "",
        stderrbuff = "",
        parent = parent or nil,
        term = myterm or (processes[parent] or _G).term,
        messagehandlers = {},
        envvars = envvars or {},
        name = name or ("#"..tostring(id))
    }
    --print(1)
    table.insert(processlist, id)
    local thread = thread_create(pcreatecallback, id, processes[id].name.."/main", params.tenv)
    processes[id].threads = {thread}
    --print(2)
    thread_resume(thread, unpack(args))
    return id, thread
end

function process_mayInteractWith(spid, tpid)
    local sp, tp = processes[spid], processes[tpid]
    return sp.mode == "kernel" -- source process runs in kernel mode
        or (sp.uid == 0 and tp.mode == "user") -- source process owned by root and target in usermode
        or sp.uid == tp.uid -- processes owned by same user
        or tp.parent == spid -- target is child of source
end

function process_send(pid, message, ...)
    if not processes[pid] then error("Invalid PID: "..tostring(pid)) end
    if message == "SIGKILL" then
        for k, v in ipairs(processes[pid].threads) do
            thread_terminate(v) -- HEADSHOT
        end
        processes[pid].killflag = true
    end
    table.insert(processes[pid].eventQueue, {message, ...})
end

function process_get(pid)
    return processes[pid]
end

function process_set(pid, name, val)
    processes[pid][name] = val    
end

function process_addListener(pid, message, callback)
    --processes[pid].messagehandlers[message] = callback
    if not processes[pid].messagehandlers[message] then processes[pid].messagehandlers[message] = {} end
    local handlers = processes[pid].messagehandlers[message]
    table.insert(handlers, callback)
end

function process_registerThread(pid, tid)
    table.insert(processes[pid].threads, tid)
end

function process_removeListener(pid, message, callback)
    local k = utils_getKey(processes[pid].messagehandlers[message], callback)
    if k then table.remove(processes[pid].messagehandlers[message], k) end
    if #processes[pid].messagehandlers[message] == 0 then processes[pid].messagehandlers[message] = nil end
end

local function removeByPid(pid)
    local id
    for k, v in ipairs(processlist) do
        if v == pid then id = k end
    end
    table.remove(processlist, id)
    processes[pid] = nil
end

function process_handleEvent(pid)
    local e = processes[pid].eventQueue[1]
    if e then 
        --print("Handling events for "..pid..": "..e[1])
        local h = processes[pid].messagehandlers[e[1]]
        if h then 
            e[1] = {name = e[1]}
            for k, v in ipairs(h) do
                --h(unpack(e)) 
                local p = thread_create(v, pid)
                thread_resume(p, unpack(e)) -- make sure event handlers run in their own thread to prevent kernel crashes
            end
        end
        table.remove(processes[pid].eventQueue, 1)
    end
end

local function bgWorker()
    event_addHandler("sys_processdeath", function (meta, pid, data)
        log("[DEBUG] Process "..data.name.." (#"..pid..") terminated.")
    end)
    while true do
        coroutine.yield()
        for a = 1, #processlist do
            local pid = processlist[a]
            if pid == nil then break end
            process_handleEvent(pid)
            local proc = processes[pid]
            for b = 1, #proc.threads do
                if not thread_get(proc.threads[b]) then
                    table.remove(proc.threads, b)
                    b = b - 1
                end
            end
            if #proc.threads == 0 then
                event_push("sys_processdeath", pid, processes[pid])
                table.remove(processlist, a)
                processes[pid] = nil
            end
            coroutine.yield()
        end
    end
end

function process_onEnvSetup(func)
    table.insert(envsetupcallbacks, func)
end

function process_getRunning()
    return thread_get(thread_getRunning()).pid
end

function process_list()
    local pl = {}
    for k, v in ipairs(processlist) do
        pl[k] = v
    end
    return pl
end

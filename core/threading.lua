--[[
    Threading
    GIves basic threadhandling
]]

local threads = {}
local threadlist = {}
local current = nil

function thread_create(func, pid, name, env)
    if not process_exists(pid) then
        error("Invalid process: "..pid)
    end
    
    local id = utils_getUniqueKey(threads)

    setfenv(func, env or process_get(pid).env)
    threads[id] = {
        routine = coroutine.create(func),
        running = false,
        started = false,
        pid = pid,
        killIssued = false,
        id = id,
        name = name or (process_get(pid).name.."/"..id)
    }
    process_registerThread(pid, id)
    --print(threads[id])
    table.insert(threadlist, id)
    return id
end

function thread_resume(id, ...)
    if not threads[id] then
        error("Invalid threadid")
    end
    if threads[id].running then
        error("Thread already running")
    end
    local args = {...}
    if #args > 0 and threads[id].started then
        error("Can only pass arguments on initial start")
    end
    threads[id].running = true
    threads[id].started = true
    threads[id].args = args
end

function thread_suspend(id)
    threads[id].running = false
end

function thread_getRunning()
    return current
end

function thread_terminate(id)
    threads[id].killIssued = true
end

function thread_getAll()
    return threads
end

function thread_list()

end

function thread_startEngine()
    -- temporary fix for cc bug
    sleep(0)    
    -- for debugging
    event_addHandler("sys_threadCrash", function (meta, tid, m, data)
        log("[DEBUG] Thread "..data.name.." (#"..tid..") Crashed: "..m)
    end)

    event_addHandler("sys_threadDeath", function (meta, tid, data)
        log("[DEBUG] Thread "..data.name.." (#"..tid..") died")
    end)
    while true do
        if #threadlist == 0 then
            event_updateQueue()
            event_handleUpTo(10)
            --print("No threads")
        end
        for a = 1, #threadlist do
            event_updateQueue()
            event_handleUpTo(10)
            local t = threads[threadlist[a]]
            if not t then break end -- prevent crashes
            if t.running then
                current = t.id
                local s, m = coroutine.resume(t.routine, unpack(t.args))
                current = nil
                if not s then
                    if not t.killIssued then event_push("sys_threadCrash", t.id, m, {name = t.name}) end
                    --print("Thread #"..t.id.." crashed: "..(m or "<no message>"))
                    table.remove(threadlist, a)
                    threads[t.id] = nil
                    a = a - 1
                elseif coroutine.status(t.routine) == "dead" then
                    event_push("sys_threadDeath", t.id, {name = t.name})
                    table.remove(threadlist, a)
                    threads[t.id] = nil
                    a = a - 1
                else
                    t.args = {}
                end
            end
            
        end
    end
end

function thread_shallKill(id)
    return threads[id].killIssued
end

function thread_get(id)
    return threads[id]
end

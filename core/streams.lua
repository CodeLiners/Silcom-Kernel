--[[
    Stream regestry
]]

local streams = {}


--[[
    param/pid: Id of the process this handle is linked to
    param/handler: a table with callbacks to handle the access
    return:
        * the handle to pass on to userspace
]]
function stream_register(pid, handler)
    local h = setmetatable({}, {__type = "handle"})
    if not streams[pid] then
        streams[pid] = setmetatable({}, {mode = "k"})
    end
    streams[pid][h] = handler
    return h
end

--[[
    param/h: The handle to perform the call on
    param/pid: the process that asked for the call
    param/func: the function to call
    param/args: packed args to pass on
    param/flags: a couple options, none avaible yet
    returns:
        * error message or false
        * returned values, packed
]]
function stream_doCall(h, pid, func, args, flags)
    local s = streams[pid]
    if not s then return "invalid_handle" end
    local handl = s[h]
    if not handl then return "invalid_handle" end
    if not handl[func] then return "unknown_function" end
    return false, {handl[func](pid, args)}
end

local function onProcDeath(pid)
    -- Dispose all handles of that process
    streams[pid] = nil
end

event_addHandler("sys_processdeath", onProcDeath)
local stdstreams = {}
local streams

local function stream(stype, pid) {
    local str = {
        read = function (amount, block)
            callerpid = process_getRunning()
            if stype ~= "i" and callerpid == pid then
                error("Write-only stream")
            end
            utils_checkType(data, {"boolean", "string"}, 1, 4, "stream/"..type.."/read")
            amount = amount or 1
            if amount < 1 then
                error("Invalid amount")
            end
            local data = stdstreams[pid][stype]

            ret = data:sub(amount + 1)
        end
    }
    return
}

on("load", function ()
    registerUHook("stream_write", function (handle, data)
        utils_checkType(data, {"number", "string"}, 1, 4, "syscall/stream_write")
        return stream_doCall(handle, process_getRunning(), "write", {data}, {})
    end)
    registerUHook("stream_read", function (handle, data, block)
        utils_checkType(data, {"number", "nil"}, 1, 4, "syscall/stream_read")
        return stream_doCall(handle, process_getRunning(), "read", {data, block}, {})
    end)
    registerUHook("stream_readline", function (handle, block)
        return stream_doCall(handle, process_getRunning(), "readline", {block}, {})
    end)
    registerUHook("io_getstream" function (type)
        local pid = process_getRunning()
        --stdstreams[pid] = stdstreams[pid] or {o = "", i = "", e = ""}

    end)

    

    event_addHandler("sys_processdeath", function (pid)
        stdstreams[pid] = nil
    end)

    --streams = {stdout = stream("o"), stdin = stream("i"), stderr = stream("e")}
end)
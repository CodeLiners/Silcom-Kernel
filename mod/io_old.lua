local function getPID()
    return thread_get(thread_getRunning()).pid
end

on("load",
    function()
        registerHook("io_stdout", function(text)
            local pid = getPID()
            process_set(pid, "stdoutbuff", process_get(pid).stdoutbuff..text)
        end)

        registerHook("io_stdin", function(mode, block)
            local inp = process_get(getPID()).stdinbuff
            if mode == "line" then
                local ret = ""
                while true do
                    if 1 == inp:len() and not block then
                        ret = ret..inp
                        inp = ""
                        return ret
                    elseif inp:len() == 0 and not block then
                        return ret
                    elseif inp:len() == 0 then
                        coroutine.yield()
                    end
                    ret = ret.inp:sub(1,1)
                    inp = inp:sub(2)
                    if ret:sub(-1, -1) == "\n" then
                        return ret:sub(1, -2)
                    end
                end
            elseif mode == "char" then
                local ret
                while inp:len() == 0 do
                    ret = inp:sub(1,1)
                    inp = ret.inp:sub(1,1)
                    if not block then break end
                    coroutine.yield()
                end
                return ret
            end
        end)

        registerHook("io_stderr", function(text)
            local pid = getPID()
            process_set(pid, "stderrbuff", process_get(pid).stderrbuff..text)
        end)

        registerHook("io_readstderr", function(tarpid, mode)
            if not process_mayInteractWith(getPID(), tarpid) then
                error("Cannot read stderr from that process", 3)
            end
            local inp = process_get(tarpid).stderrbuff
            if mode == "line" then
                local ret = ""
                while true do
                    if 1 == inp:len() then
                        ret = ret..inp
                        inp = ""
                        return ret
                    elseif inp:len() == 0 then
                        return ret
                    end
                    ret = ret.inp:sub(1,1)
                    inp = inp:sub(2)
                    if ret:sub(-1, -1) == "\n" then
                        return ret:sub(1, -2)
                    end
                end
            elseif mode == "char" then
                local ret = inp:sub(1,1)
                inp = ret.inp:sub(1,1)
                return ret
            end
        end)

        registerHook("io_readstdout", function(tarpid, mode)
            if not process_mayInteractWith(getPID(), tarpid) then
                error("Cannot read stdout from that process", 3)
            end
            --print("1(read from):", tarpid or "nil")
            local inp = process_get(tarpid).stdoutbuff
            if mode == "line" then
                --print("2")
                local ret = ""
                while true do
                    --print("3:", ret or "nil", ":", inp or "nil")
                    if 1 == inp:len() then
                        ret = ret..inp
                        inp = ""
                        process_set(tarpid, "stdoutbuff", inp)
                        return ret
                    elseif inp:len() == 0 then
                        process_set(tarpid, "stdoutbuff", inp)
                        return ret
                    end
                    ret = ret..inp:sub(1,1)
                    inp = inp:sub(2)
                    if ret:sub(-1, -1) == "\n" then
                        process_set(tarpid, "stdoutbuff", inp)
                        return ret:sub(1, -2)
                    end
                end
            elseif mode == "char" then
                local ret = inp:sub(1,1)
                inp = ret.inp:sub(1,1)
                process_set(tarpid, "stdoutbuff", inp)
                return ret
            end
        end)

        registerHook("io_writestdin", function(tarpid, mode)
            if not process_mayInteractWith(getPID(), tarpid) then
                error("Cannot write stdin of that process", 3)
            end
            process_set(tarpid, "stdinbuff", process_get(tarpid).stdinbuff..text)
        end)
    end
)
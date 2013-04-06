local function getPID()
    return thread_get(thread_getRunning()).pid
end

on("load",
    function()
        registerHook("term", function(func, ...)
            local f = process_get(getPID()).term[func]
            if not f then error("Invalid term function: "..func.."("..table.concat({...}, ", ")..")") end
            return f(...)
        end)

        registerHook("term_listfunc", function()
            local ret = {}
            for k, v in pairs(process_get(getPID()).term) do
                table.insert(ret, k)
            end
            return ret
        end)

        registerHook("term_event", function(term, type, ...)
            term_termEvent(term, type, ...)
        end)
    end
)

function term_termEvent(term, type, ...)
    for k, v in ipairs(process_list()) do
        --print(k, v)
        local p = process_get(v)
        if p and p.term == term then
            process_send(p.pid, "event_term_"..type, ...)
        end
    end
end
--[=[[
    [[Infoblock for eventqueue]]
    1. Dimension: Queue
    2. Dimension: 
        name
        <args>
]]=]
local eventqueue = {} -- no events to handle
local listeners = {}

function event_handleOne()
    if eventqueue[1] then
        if type(listeners[eventqueue[1][1]]) == "table" then
            local meta = {name = eventqueue[1][1], handlercount = #listeners[eventqueue[1][1]]}
            for k, v in ipairs(listeners[eventqueue[1][1]]) do
                eventqueue[1][1] = meta
                v(unpack(eventqueue[1]))
            end
        end
        table.remove(eventqueue, 1)
    end
end

function event_handleUpTo(num)
    for a = 1, num do
        if #eventqueue == 0 then break end
        event_handleOne()
    end
end

function event_push(...)
    table.insert(eventqueue, {...})
end

function event_updateQueue(...)
    local stopper = {"stop"}
    os.queueEvent("queueStopper", stopper)
    while true do
        local e = {coroutine.yield()}
        --print(textutils.serialize(e))
        --print (e[2])
        if e[1] == "queueStopper" --[[and e[2] == stopper ]]then break end -- prevent blocking :D
        e[1] = "native_"..e[1]
        table.insert(eventqueue, e)
    end
end

local function addOneHandler( event, handler )
    if type(listeners[event]) ~= "table" then
        listeners[event] = {}
    end
    table.insert(listeners[event], handler)
end

function event_addHandler(p1, p2)
    if type(p1) == "string" and type(p2) == "function" then
        addOneHandler(p1, p2)
    elseif type(p1) == "table" and type(p2) == "nil" then
        for k, v in pairs(p1) do
            addOneHandler(k, v)
        end
    elseif type(p1) == "table" and type(p2) == "function" then
        for k, v in ipairs(p1) do
            addOneHandler(v, p2)
        end
    end
end

function event_removeHandler( event, handler )
    local r
    for k, v in ipairs(listeners[event]) do
        if v == handler then r = k break end
    end
    if r then listeners[event][r] = nil end
end
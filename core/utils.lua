local setmt, getmt = setmetatable, getmetatable
local metatables = setmt({}, {__mode="k"}) -- weak keys to prevent mem leaks

function utils_joinTable(table, sep)
    local sep_
    if type(sep) == "string" then
        sep_ = function (num, k, v) return (k == 1 and "" or sep) end
    elseif type(sep) == "function" then
        sep_ = sep
    end
    ret = ""
    for k, v in ipairs(table) do
        ret = ret..(sep_(#table, k, v) or "")..tostring(v)
    end
    return ret
end

function utils_getKey(...)
    return utils_getkey(...)
end

function utils_getkey(haystack, needle)
    for k, v in pairs(haystack) do
        if v == needle then return k end
    end
end

function utils_checkType(obj, t, paramnr, stacklvl, name)
    if type(t) == "string" then
        if type(obj) == t then
            return obj
        else
            error((name and (name..": ") or "")..(paramnr and ("Parameter #"..paramnr..": ") or "")..t.." expected, got "..type(obj), stacklvl or 2)
        end
    elseif  type(t) == "table" then
        if utils_getkey(t, type(obj)) then
            return obj
        else
            local function callback(num, k, v)
                if k == num then
                    return " or "
                elseif k > 1 then
                    return ", "
                end
            end
            error((paramnr and ("Parameter #"..paramnr..": ") or "")..utils_joinTable(t, callback).." expected, got "..type(obj), stacklvl or 2)
        end
    end
end

function utils_copyTable(t, tracker, target)
    utils_checkType(t, "table", 1, 3, "native/utils_copyTable")
    tracker = utils_checkType(tracker, {"table", "nil"}, 2, 3, "native/utils_copyTable") or {}
    target = utils_checkType(target, {"table", "nil"}, 3, 3, "native/utils_copyTable") or {}
    local mt = getmetatable(t)
    if mt and mt.__copy then 
        return mt.__copy(t, tracker, target)
    else
        local ret = target
        for k, v in pairs(t) do
            if tracker[k] then 
                ret[k] = tracker[k] 
            else
                local ty = type(t)
                if ty == "table" then
                    local t = {}
                    tracker[k] = t
                    ret[k] = utils_copyTable(table, tracker, t)
                else
                    ret[k] = v
                end
            end
        end
        return ret
    end
end

function startsWith(haystack, needle)
    if needle:len() > haystack:len() then return false end
    return (haystack:sub(1, needle:len()) == needle)
end 

function endsWith(haystack, needle)
    if needle:len() > haystack:len() then return false end
    return (haystack:sub(0 - needle:len()) == needle)
end

local function str_split( str, char )
    if #char != 1 then error("char has to be 1 char long") end
    return {str:match((str:gsub("[^"..sep.."]*"..sep, "([^"..sep.."]*)"..sep)))}
end

rawset(string, "startsWith", startsWith)
rawset(string, "endsWith", endsWith)
rawset(string, "split", str_split)
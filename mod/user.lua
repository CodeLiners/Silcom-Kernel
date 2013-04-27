-- /etc/passwd format like on linux, except second field is unused: 
-- -- user::UID:GID(currently unused and always -1):Full Name or so:homedir:shell/command
-- /etc/shadow format: user:hash(sha1)
local function initpasswd()
    local f = vfs.open("/etc/passwd", "w")
    f.writeLine("root::0:-1::/root:/bin/sh")
    f.writeLine("login::1:-1:Login service:/:/bin/false")
    f.close()
end

function user_loginOnTerm(term)
    prog_execute("/bin/login", "user", 1, term, 0, "")
end

function user_info( user )
    local f = vfs.open("/etc/passwd")
    local usr
    while true do
        local line = f.readLine()
        local fields = line:split(":")
        if fields[1] == user then
            usr = fields
            break
        end
    end
    f.close()
    if not usr then return end
    local f = vfs.open("/etc/shadow")
        while true do
        local line = f.readLine()
        local fields = line:split(":")
        if fields[1] == user then
            usr.pass = fields[2]
            break
        end
    end
    f.close()
    return usr
end

function user_needsLogin( user )
    return not user_info.pass == ""
end

function user_checkLogin( user, pass )
    local usr = user_info(user)
    if not usr return nil end
    if usr.pass == "" or stringutils.SHA1(pass) == usr.pass then -- empty password or 
        return {shell = usr[7], home = usr[6], name = urs[5]}
    end

end

function user_getHome( user )
    return user_info()[7]
end

function user_getName( user )
    return user_info()[5]
end

on("load", function ()
    if vfs.touch("/etc/passwd") then
        initpasswd()
    end
    vfs.touch("/etc/shadow")
    registerUHook("user_login", function (user, pass)
        if process_get(process_getRunning()).uid != 1 then
            error("Access denied")
        end
        return user_checkLogin(user, pass)
    end)
    
    registerUHook("user_getHome", user_getHome)
    registerUHook("user_getName", user_getName)
end)
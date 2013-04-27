-- /etc/passwd format like on linux, except second field is unused: 
-- -- user::UID:GID(currently unused and always -1):Full Name or so:homedir:shell/command
-- /etc/shadow format: user:hash(sha1)
local function initpasswd()
    local f = vfs.open("/etc/passwd", "w")
    f.writeLine("root::0:-1::/root:/bin/sh")
end

function user_loginOnTerm(term)
    prog_execute("/bin/login", "user", 0, term, 0, "")
end

on("load", function ()
    if vfs.touch("/etc/passwd") then
        initpasswd()
    end
    vfs.touch("/etc/shadow")
end)
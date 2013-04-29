-- /etc/passwd format like on linux, except second field is unused: 
-- -- user::UID:GID(currently unused and always -1):Full Name or so:homedir:shell/command
-- /etc/shadow format: user:hash(sha1)

local PASSWDFILE = "/etc/passwd"
local SHADOWFILE = "/etc/shadow"

local function initpasswd()
    local f = vfs.open(PASSWDFILE, "w")
    f.writeLine("root::0:-1::/root:/bin/sh")
    f.writeLine("login::1:-1:Login service:/:/bin/false")
    f.close()
end

function user_loginOnTerm(term)
    prog_execute("/bin/login", "user", 1, term, 0, "")
end

function user_info( user )
    local f = vfs.open(PASSWDFILE)
    local usr
    while true do
        local line = f.readLine()
		if not line then 
			break 
		end
        local fields = line:split(":")
        if fields[1] == user then
            usr = fields
            break
        end
    end
    f.close()
    if not usr then return end
    local f = vfs.open(SHADOWFILE)
    while true do
        local line = f.readLine()
		if not line then 
			break 
		end
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

function user_create( user, pass )
	if type(user) ~= "string" then
		error("Username is not specified")
	end
    local f = vfs.open(PASSWDFILE)
	local uid = -1
    while true do
        local line = f.readLine()
		if not line then 
			break 
		end
        local fields = line:split(":")
        if fields[1] == user then
			f.close()
			error("User already exists")
        end
		if fields[3] > uid then
			uid = fields[3]
		end
    end
    f.close()
	-- add user to passwd
	local f = vfs.open(PASSWDFILE, "a+")
	f.writeLine(string.format("%s::%s:-1::%s:/bin/sh", user, uid + 1, "/home/"..user))
	f.close()
	-- add password to shadow
	local f = vfs.open(SHADOWFILE, "a+")
	f.writeLine(string.format("%s:%s:%s:::::", user, pass and stringutils.SHA1(pass) or "", os.time() * 1000))
	f.close()
end

function user_changePassword( user, newPass, oldPass )
	if type(user) ~= "string" then
		error("Username is not specified")
	end
    local f = vfs.open(PASSWDFILE)
    local usr
    while true do
        local line = f.readLine()
		if not line then 
			break 
		end
        local fields = line:split(":")
        if fields[1] == user then
            usr = fields
            break
        end
    end
    f.close()
    if not usr then
		error("User does not exist")
	end
	-- update shadow
	local lines = vfs.readLines(SHADOWFILE)
	for index, line in ipairs(lines) do
        local fields = line:split(":")
        if fields[1] == user then
			if fields[2] == "" or (stringutils.SHA1(oldPass or "") ~= stringutils.SHA1(fields[2] or ""))
				lines[index] = string.format("%s:%s:%s:::::", user, newPass and stringutils.SHA1(newPass) or "", os.time() * 1000)
				vfs.writeLines(SHADOWFILE, lines)
				break
			else
				error("oldPass is wrong")
			end
		end
    end
end

on("load", function ()
    if vfs.touch(PASSWDFILE) then
        initpasswd()
    end
    vfs.touch(SHADOWFILE)
    registerUHook("user_login", function (user, pass)
        if process_get(process_getRunning()).uid ~= 1 then
            error("Access denied")
        end
        return user_checkLogin(user, pass)
    end)
    
    registerUHook("user_getHome", user_getHome)
    registerUHook("user_getName", user_getName)
    registerUHook("user_create", user_create)
    registerUHook("user_changePassword", user_changePassword)
end)
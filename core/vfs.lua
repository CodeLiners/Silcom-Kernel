local function startsWith(haystack, needle)
    if needle:len() > haystack:len() then return false end
    return (haystack:sub(1, needle:len()) == needle)
end 

local function endsWith(haystack, needle)
    if needle:len() > haystack:len() then return false end
    return (haystack:sub(0 - needle:len()) == needle)
end 

function vfs.combine(base, rel)
    if not base then base = "/" end
    if not rel then rel = "" end
    --print("combining "..base.." with "..rel)
    if startsWith(rel, "/") then
        rel = rel:sub(2)
        base = "/"
    end

    if startsWith(rel, "./") then
        rel = rel:sub(3)
    end

    if not startsWith(base, "/") then base = "/"..base end

    if endsWith(rel, "..") then rel = rel.."/" end

    local lastrel, lastbase
    while startsWith(rel, "../") do
        lastrel = rel
        lastbase = base
        if base:match("%/.+") then
            base = base:gsub("%/[^%/]+%/?$", "")
            if base == "" then base = "/" end
        end
        rel = rel:sub(4)
        if rel == lastrel and base == lastbase then break end
    end

    while rel:match("%.%.%/") do
        lastrel = rel
        lastbase = base
        rel = rel:gsub("([^%/]+)%/%.%.%/(.+)", "%2")
        if rel == lastrel and base == lastbase then break end
    end
    if not (endsWith(base, "/") or startsWith(rel, "/")) then base = base.."/" end
    return base..rel
end

function vfs.resolve( path )
    --return path
    if type(path) ~= "string" then error("path must be string", 2) end
    if string.sub(path, 1, 1) ~= "/" then path = "/"..path end
    --print("Resolving "..path.."...")
    if mounts[path] then return mounts[path] end
    local ret = vfs.combine(vfs.resolve( vfs.combine( path, "../" ) ), fs.getName(path))
    --print(path.." => "..ret)
    --sleep(1)
    return ret
end

function vfs.readAll(file)
    local f = vfs.open(file, "r")
    local ret = f.readAll()
    f.close()
    return ret
end

function vfs.writeAll(file, content)
    local dir = vfs.combine(file, "..")
    if not vfs.exists(dir) then error("No such directory: "..dir.." (when writing to "..file..")") end
    local f = vfs.open(file, "w")
    f.write(content)
    f.close()
end

function vfs.mount( path, as )
    mounts[as] = path
end

function vfs.unmount( as )
    mounts[as] = nil
end

function vfs.open( file, mode )
    return fs.open(vfs.resolve(file), mode)
end

function vfs.exists( file )
    if type(file) ~= "string" then error("file must be string", 2) end
    return fs.exists(vfs.resolve(file))
end

function vfs.loadfile(file, chunkname)
    if not vfs.exists(file) then error("No such file: "..file) end
    local f = vfs.open(file, "r")
    --print(f.readAll())
    local fn, err = loadstring(f.readAll(), (chunkname or fs.getName(file)))
    f.close()
    return fn, err
end

function vfs.dofile(f, ...)
    fn, err = vfs.loadfile(f)
    if not fn then error (err) end
    fn(...)
end

function vfs.isDir( path )
    return fs.isDir( vfs.resolve(path))
end

function vfs.isFile( path )
    return not fs.isDir( vfs.resolve(path)) -- this might look obsolete but there will be 
end

function vfs.list( path )
    return fs.list( vfs.resolve(path) )
end

function vfs.loadlib( name )
    return vfs.dofile("/lib/"..name..".lua")
end

function vfs.mkdir( name )
    return fs.makeDir(vfs.resolve(name))
end
vfs.makeDir = vfs.mkdir

function vfs.readAll( name )
    local f = cfs.open(name, "r")
    local cont = f.readAll()
    f.close()
    return cont
end

function vfs.touch( name )
    if not vfs.exists(name) then 
        vfs.open(name, "w").close()
    end
end

function vfs.readLines( path )
  local f = vfs.open(path, "r")
  if f then
        local lines = {}
        local line = f.readLine()
        while line do
			table.insert(lines, line)
			line = f.readLine()
        end
        f.close()
        return lines
  end
  return nil
end

function vfs.writeLines( path, lines )
  local f = vfs.open(path, "w")
  if f then
        for index, line in ipairs(lines) do
			f.writeLine(line)
        end
        f.close()
  end
end

for k, v in ipairs(maindirs) do
    if not vfs.exists(v) then vfs.mkdir(v) end
end

setmetatable(vfs, {__index = fs})
rawset(_G, "vfs", vfs)
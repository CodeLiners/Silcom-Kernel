function prog_execute(file, mode, uid, term, parent, args, env, name)
    name = name or file
    data = vfs.readAll(file)
    if data:sub(1,2) == "#!" then 
        -- script
        local ip = ""
        while true do
            local c = data:sub(1, 1)
            if c == LF then break end
            ip = ip..c
            data = data:sub(2)
        end
        prog_execute(ip, mode, uid, term, parent, args.." "..file, env, name)
    elseif data:sub(1,1) == string.char(27) then
        local headerlen = data:sub(2, 2):byte() * 256 + data:sub(3, 3):byte()
        local header = ""
        for i = 1, headerlen do
            header = header..data:sub(3 + i, 3 + i)
        end
        local code = data:sub(4 + headerlen)
        local func = vfs.loadstring(ascii.ESC + code)
        process_create(func, uid, mode, nil, parent, args, term, env, name)
    elseif DEBUG then
        local func = vfs.loadfile(file)
        process_create(func, uid, mode, nil, parent, args, term, env, name)
    else
        error("Invalid file")
    end
end

on("load", function ()
    --
end)
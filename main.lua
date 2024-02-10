scripts.gear = scripts.gear or {
    name = 'dev/arkadia-gear',
    shortName = 'gear',
    tag = 'SPRZET',
    names = {},
    eq = {
        weapons = {},
        containers = {},
        commands = {}
    }
}


function scripts.gear:getChar()
    if not gmcp.char then 
        return character_name
    else
        return gmcp.char.info.name
    end
end


function scripts.gear:saveData()
    local data = {}

    table.save(getMudletHomeDir() .. '/gear_names.lua', self.names)
    table.save(getMudletHomeDir() .. '/gear_' .. self:getChar() .. '.lua', self.eq)
end


function scripts.gear:loadData()

    local namesFile = getMudletHomeDir() .. '/gear_names.lua'
    local charFile = getMudletHomeDir() .. '/gear_' .. self:getChar() .. '.lua'
    
    pluginMsg(self.tag, 'info', 'Ladowanie danych postaci z pliku %s', charFile)
    pluginMsg(self.tag, 'info', 'Ladowanie danych slownika z pliku %s', namesFile)
    
    if not lfs.attributes(namesFile) or not lfs.attributes(charFile) then
        self:saveData()
    end

    table.load(charFile, self.eq)
    table.load(namesFile, self.names)

    print("AFTER LOADED")
    print(dump_table(self.eq))
    print("---------")    
end


function scripts.gear:msg(t, text, ...)
    -- print("MSG: " .. dump_table(arg))
    pluginMsg('SPRZET', t, text, unpack(arg))
end


function scripts.gear:init()
    self:loadData()
    self:msg('ok', "Zaladowane")
end


function scripts.gear:reload(debug)
    reloadPlugin(self, debug)
end


loadPlugin(scripts.gear)

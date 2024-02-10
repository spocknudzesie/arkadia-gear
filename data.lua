function scripts.gear:setItem(t, number, name, persist)
    print(dump_table({t, number, name}))
    if t ~= 'weapons' and t ~= 'containers' then
        return error({code=-1, msg='Bledna kategoria przedmiotu'})
    end

    local words = name:split(' ')
    local noun = words[#words]

    print(dump_table(words))
    print(noun)

    if not self.names[noun] then
        return error('Brak odmiany wyrazu "' .. noun .. '". Dodaj ja komenda /odmien')
    end

    if self.eq[t][number] and persist then
        self.eq[t][number].nameNom = name
    else
        self.eq[t][number] = {nameNom = name}
    end
    self:saveData()
    return self.eq[t][number]
end


function scripts.gear:deleteItem(t, number)
    if t ~= 'weapons' and t ~= 'containers' then
        return error({code=-1, msg='Bledna kategoria przedmiotu'})
    end

    if not self.eq[t][number] then
        return error({code=-2, msg='Brak przedmiotu nr ' .. number .. ' w kategorii ' .. t})
    end

    if t == 'weapons' then
        self:deleteWeapon(number)
    elseif t == 'containers' then
        self:deleteContainer(number)
    end
    
    self.eq[t][number] = nil
    self:saveData()
    return true
end


function scripts.gear:getItem(t, number)
    if t ~= 'weapons' and t ~= 'containers' then
        return error({code=-1, msg='Bledna kategoria przedmiotu'})
    end

    return self.eq[t][tonumber(number)]
end


function scripts.gear:setContainer(number, value, persist)
    return self:setItem('containers', number, value, persist)
end


function scripts.gear:setWeapon(number, value, persist)
    return self:setItem('weapons', number, value, persist)
end


function scripts.gear:getContainer(number)
    return self:getItem('containers', number)
end


function scripts.gear:getWeapon(number)
    return self:getItem('weapons', number)
end


function scripts.gear:setCommand(name, value)
    self.commands[name] = value:split('')
end


function scripts.gear:inflect(name, case, prepend)
    local words = name:split(' ') -- table
    local res = {} -- table
    
    for i=1, #words, 1 do
        local word = words[i]
        -- scripts.gear:msg('info', 'i=%d, word=%s', i, word)
        if i < #words then
            table.insert(res, word:inflect('adj', case))
        else
            local form = self.names[word][case]
            if not form then
                form = string.format('Brak odmiany nazwy %s w przypadku %s', word, case)
            end
            table.insert(res, form)
        end
    end

    if prepend then
        local adj -- string

        if name:match('a ') then
            adj = "swoja"
        elseif name:match('e ') then
            adj = "swoje"
        else
            adj = "swoj"
        end
            
        table.insert(res, 1, adj:inflectAdj(case))
    end

    return table.concat(res, ' ')
end


function scripts.gear:findContainerByType(t)
    for i, item in pairs(self.eq.containers) do
        if item.type == t then
            return i, item
        end
    end
end

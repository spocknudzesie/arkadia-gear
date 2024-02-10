function scripts.gear:unpairWeapon(number)
    local w1 = self:getWeapon(number)
    local w2

    if not w1 then
        return error('Bron nr ' .. number .. ' nie zostala ustawiona.')
    end

    if not w1.pairedWeapon then
        return error('Bron nr ' .. number .. ' nie ma pary.')
    end

    w2 = self:getWeapon(w1.pairedWeapon)

    if not w2 then
        pluginMsg(self.tag, 'error', 'Bron nr ' .. w1.pairedWeapon .. ' przypisana jako para ' .. self:inflect(w1.nameNom, 2) .. ' nie istnieje.')
    else
        w2.pairedWeapon = nil
    end

    w1.pairedWeapon = nil
    self:saveData()
    return true
end


function scripts.gear:pairWeapon(number, pairNumber)
    local w1 = self:getWeapon(number)
    local w2 = self:getWeapon(pairNumber)

    if not w1 then
        return error('Bron nr ' .. number .. ' nie zostala ustawiona.')
    end

    if not w2 then
        return error('Bron nr ' .. pairNumber .. ' nie zostala ustawiona.')
    end

    if w1.pairedWeapon and w1.pairedWeapon ~= weapon2 then
        local p = self:getWeapon(w1.pairedWeapon)
        if p then
            p.pairedWeapon = nil
            pluginMsg(self.tag, 'ok', 'Odpinam bron %s od %s', self:inflect(p.nameNom, 4), self:inflect(w1.nameNom, 2))
        end
    end

    w1.pairedWeapon = pairNumber
    w2.pairedWeapon = number
    self:saveData()
    return {w1, w2}
end


function scripts.gear:assignWeaponToContainer(number, contNumber)
    local w = self:getWeapon(number)
    local c = self:getContainer(contNumber)

    if not w then
        return error('Bron nr ' .. number .. ' nie zostala ustawiona.')
    end

    if not c then
        return error('Pojemnik nr ' .. contNumber .. ' nie zostal ustawiony.')
    end

    w.container = contNumber
    self:saveData()
    return true
end


function scripts.gear:wieldWeapon(number, textOnly, dontPair)
    local w = self:getWeapon(number)
    local c
    local cmd
    local cmds = {}

    if not w then
        return error('Bron nr ' .. number .. ' nie zostala ustawiona.')
    end

    if w.container then
        c = self:getContainer(w.container)

        if not c then
            return error(string.format('%s przypisano do pojemnika %d, ktory nie istnieje.',
                self:inflect(w.nameNom, 4), w.container))
        end

        -- print("Dobywanie " .. self:inflect(w.nameNom, 2)  .. " z pojemnika " .. w.container)
        table.insert(cmds, self:getFromContainer(w.container, self:inflect(w.nameNom, 4), true))
    end

    if self.eq.commands.wield then
        print('Dobywanie komenda - TODO')
        return
    end

    cmd = 'dobadz ' .. self:inflect(w.nameNom, 2)

    if dontPair then
        table.insert(cmds, cmd)
        return cmds
    end

    table.insert(cmds, cmd)

    if w.pairedWeapon and not dontPair then
        -- print("Dobywanie pary")
        table.insert(cmds, self:wieldWeapon(w.pairedWeapon, textOnly, true))
    end

    if textOnly then
        cmds = table.flatten(cmds)
        return cmds
    else
        cmds = table.flatten(cmds)
        for i, c in pairs(cmds) do
            send(c)
        end
    end
end


function scripts.gear:unwieldWeapon(number, textOnly, dontPair)
    local w = self:getWeapon(number)
    local c
    local cmd
    local cmds = {}

    if not w then
        return error('Bron nr ' .. number .. ' nie zostala ustawiona.')
    end

    if w.container then
        c = self:getContainer(w.container)

        if not c then
            return error(string.format('%s przypisano do pojemnika %d, ktory nie istnieje.',
                self:inflect(w.nameNom, 4), w.container))
        end

        -- print("Opuszczanie " .. self:inflect(w.nameNom, 2)  .. " do pojemnika " .. w.container)
        table.insert(cmds, self:putIntoContainer(w.container, self:inflect(w.nameNom, 4), true))
    else
        table.insert(cmds, 'opusc ' .. self:inflect(w.nameNom, 4))
    end

    if w.pairedWeapon and not dontPair then
        -- print("Opuszczanie pary")
        -- print(dump_table(cmds))
        table.insert(cmds, self:unwieldWeapon(w.pairedWeapon, true, true))
    end

    if textOnly then
        cmds = table.flatten(cmds)
        return cmds
    else
        cmds = table.flatten(cmds)
        for i, c in pairs(cmds) do
            send(c)
        end
    end
end


function scripts.gear:describeWeapon(number)
    local w = self:getWeapon(number)
    local pair
    local cont
    local desc = {}

    if not w then
        return "Brak broni nr " .. number
    end

    table.insert(desc, w.nameNom)

    if w.container then
        cont = self:getContainer(w.container)
        if not cont then
            cont = 'Pojemnik: (!) ' .. w.container
        else
            cont = 'Pojemnik: ' .. cont.nameNom
        end
        
        table.insert(desc, cont)
    end

    if w.pairedWeapon then
        pair = self:getWeapon(w.pairedWeapon)
        if not pair then
            pair = 'Para: (!) ' .. w.pairedWeapon
        else
            pair = 'Para: ' .. pair.nameNom
        end

        table.insert(desc, pair)
    end

    return table.concat(desc, ', ')
end


function scripts.gear:removeWeaponsFromContainer(number)
    for i, weapon in pairs(self.eq.weapons) do
        if tonumber(weapon.container) == number then
            weapon.container = nil
            pluginMsg(self.tag, 'error', '%s jest bez pojemnika!', weapon.nameNom)
        end
    end    
end


function scripts.gear:deleteWeapon(number)
    local w = self:getWeapon(number)

    if not w then
        return error('Bron nr ' .. number .. ' nie zostala ustawiona.')
    end

    self:unpairWeapon(number)
    pluginMsg(self.tag, 'info', 'Usunieto bron nr %d - %s', number, w.nameNom)
    self.eq.weapons[number] = nil
    self:saveData()
    return true
end

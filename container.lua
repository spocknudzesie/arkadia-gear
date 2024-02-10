function scripts.gear:openCloseContainer(number, cmd, textOnly)
    local cont = self:getContainer(number)

    if not cont then
        return error('Brak zdefiniowanego pojemnika nr ' .. number)
    end

    if self:isScabbard(number) then
        return
    end

    local cmd = string.format('%s %s', cmd, self:inflect(cont.nameNom, 4, true))

    if textOnly then
        return cmd
    else
        send(cmd)
    end
end


function scripts.gear:openContainer(number, textOnly)
    return self:openCloseContainer(number, 'otworz', textOnly)
end


function scripts.gear:closeContainer(number, textOnly)
    return self:openCloseContainer(number, 'zamknij', textOnly)
end


function scripts.gear:getPutContainer(number, syntax, item, textOnly)
    local cont = self:getContainer(number)
    local cmd

    if not cont then
        return error('Brak zdefiniowanego pojemnika nr ' .. number)
    end

    local cmd = string.format(syntax, item, self:inflect(cont.nameNom, 2, not self:isScabbard(number)))

    if textOnly then
        return cmd
    else
        return send(cmd)
    end
end


function scripts.gear:getFromContainer(number, item, textOnly)
    if self:isScabbard(number) then
        return self:getPutContainer(number, 'powyjmij %s z %s', item, textOnly)
    end

    return self:getPutContainer(number, "wez %s z %s", item, textOnly)
end


function scripts.gear:putIntoContainer(number, item, textOnly)
    if self:isScabbard(number) then
        return self:getPutContainer(number, 'powsun %s do %s', item, textOnly)
    end

    return self:getPutContainer(number, 'wloz %s do %s', item, textOnly)
end


function scripts.gear:isScabbard(number)
    local c = self:getContainer(number)

    if not c then
        return error('Brak zdefiniowanego pojemnika nr ' .. number)
    end

    return c.nameNom:match('pochwa$') or c.nameNom:match('temblak$') or c.nameNom:match('uprzaz$')
end


function scripts.gear:setContainerType(number, t)
    local cont = self:getContainer(number)

    if not cont then
        return error('Brak zdefiniowanego pojemnika nr ' .. number)
    end

    if t == 0 or t == '0' or t == 'usun' or t == '-1' or t == '-1' then
        t = nil    
        pluginMsg(self.tag, 'ok', 'Typ pojemnika %s (%d) usuniety', cont.nameNom, number)
    else
        pluginMsg(self.tag, 'ok', 'Typ pojemnika %s (%d) ustawiony na %s', cont.nameNom, number, t)        
    end

    cont.type = t
    
    self:saveData()
end


function scripts.gear:deleteContainer(number)
    local cont = self:getContainer(number)

    if not cont then
        return error('Brak zdefiniowanego pojemnika nr ' .. number)
    end

    self:removeWeaponsFromContainer(number)
    pluginMsg(self.tag, 'ok', 'Usunieto pojemnik "%s"', cont.nameNom)
    self.eq.containers[number] = nil
    self:saveData()
    return true
end
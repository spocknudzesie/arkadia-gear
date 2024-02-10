function scripts.gear:cmdHelp()

    local line = function(cmd, syntax, desc)
        if syntax then
            syntax = ' ' .. syntax
        else
            syntax = ''
        end

        hecho(string.format('(+) #ffffff%s%s#r - %s\n', cmd, syntax, desc))
    end

    print('--- POMOC DO MODULU WYPOSAZENIA ---')
    line('/sprzet pomoc', nil, 'ta pomoc')
    line('/sprzet', nil, 'lista ustawionego wyposazenia')
    line('/ustaw', '<b/p><nr> <nazwa>', 'ustawia wskazana <b>ron lub <p>ojemnik')
    line('/Ustaw', '<b/p><nr> <nazwa>', 'ustawia wskazana <b>ron lub <p>ojemnik, zachowujac jej pojemnik i inne dane')
    line('/odmien', '<mia> <dop> <bie>', 'zapisuje do slownika odmiane podanej nazwy')
    line('/d[nr]', nil, 'dobywa broni o podanym numerze lub pierwszej ustawionej')
    line('/o[nr]', nil, 'opuszcza bron o podanym numerze lub pierwsza ustawiona')
    line('/przypisz', 'b<nr> do p<nr>', 'przypisuje bron o podanym numerze do podanego pojemnika')
    line('/paruj', 'b<nr> z b<nr>', 'paruje bronie o podanych numerach lub usuwa parowanie, jesli podane zostanie 0')
    line('/obp<nr>', nil, 'oglada pojemnik o podanym numerze lub pierwszy ustawiony')
    line('/otw<nr>', nil, 'otwiera podany pojemnik')
    line('/zam<nr>', nil, 'zamyka podany pojemnik')
    line('/wl<nr>', '<co>', 'wklada podane przedmioty do wskazanego pojemnika')
    line('/we<nr>', '<co>', 'bierze podane przedmioty ze wskazanego pojemnika')
    line('/wem<nr>', nil, 'bierze monety z podanego pojemnika lub z sakiewki')
    line('/wlm<nr>', nil, 'wklada monety do podanego pojemnika lub do sakiewki')
    line('/wek<nr>', nil, 'bierze kamienie z podanego pojemnika lub z sakiewki')
    line('/wlk<nr>', nil, 'wklada kamienie do podanego pojemnika lub do sakiewki')    
    line('/ustaw_typ', 'p<nr> <typ>', 'ustawia typ podanego pojemnika lub usuwa, jesli podasz 0')
end

function scripts.gear:getCmd()
    return matches[1]:split(' ')[1]
end


function scripts.gear:cmdSet(var, number, value, persist)
    local category
    local categoryPl
    local result

    function err()
        pluginMsg(self.tag, 'error', 'Poprawna skladnia: #ffffff%s b[ron]/p[ojemnik] <nr> <wartosc>', self:getCmd())
        return false
    end

    if var == "bron" or var == 'b' then
        category = 'weapons'
        categoryPl = 'Bron'
    elseif var == 'pojemnik' or var == 'poj' or var == 'p' then
        category = 'containers'
        categoryPl = 'Pojemnik'
    else
        return err()
    end

    number = tonumber(number)

    if not number then
        return err()
    end

    if category == 'weapons' then
        result = self:setWeapon(number, value, persist)
    elseif category == 'containers' then
        result = self:setContainer(number, value, persist)
    end

    if result then
        pluginMsg(self.tag, 'ok', 'Ustawiono %s nr %s: #ffffff%s#r', categoryPl, number, value)
    else
        return false
    end
end


function scripts.gear:cmdAddName(nom, gen, acc)
    print(dump_table(matches))
    if not nom or not gen or not acc then
        pluginMsg(self.tag, 'error', 'Poprawna skladnia: #ffffff%s <mianownik> <dopelniacz> <biernik>#r', self:getCmd())
        return false
    end

    if self.names[nom] and (not self._confirmation or self._confirmation ~= nom) then
        pluginMsg(self.tag, 'info', 'Odmiana wyrazu "%s" juz istnieje. Jesli chcesz ja nadpisac, powtorz komende.', nom)
        self._confirmation = nom
        return false
    end

    self.names[nom] = {nom, gen, nil, acc, nil, nil}
    if self._confirmation and self._confirmation == nom then
        self._confirmation = nil
    end

    pluginMsg(self.tag, 'ok', 'Odmiana wyrazu "%s" dodana.', nom)
    self:saveData()
    return true
end


function scripts.gear:cmdList()
    local containers = {}
    local weapons = {}
    local weaponNames
    local containerNames

    if matches[2] == ' pomoc' then
        return self:cmdHelp()
    end

    function getNames(index)
        return table.values(table.map(self.eq[index], function(w) return w.nameNom end))
    end

    function pairsByKeys (t, f)
        local a = {}
        for n in pairs(t) do table.insert(a, n) end
        table.sort(a, f)
        local i = 0      -- iterator variable
        local iter = function ()   -- iterator function
            i = i + 1
            if a[i] == nil then return nil
            else return a[i], t[a[i]]
            end
        end

        return iter
    end

    weaponNames = getNames('weapons')
    containerNames = getNames('containers')

    local longestWeapon = table.findLongest(weaponNames)
    local longestContainer = table.findLongest(containerNames)


    print("--- POJEMNIKI ---")
    for i, v in pairsByKeys(self.eq.containers) do
        local t
        local weapons = {}
        local weaponsInContainer
        if v.type then t = '(' .. v.type .. ')'
        else t = ''
        end

        for j, w in pairs(self.eq.weapons) do
            -- print(dump_table({j, w.nameNom, w.container}))
            if w.container and tonumber(w.container) == tonumber(i) then
                -- print("MATCH")
                table.insert(weapons, string.format('[%d] %s', j, w.nameNom))
            end
        end

        if #weapons > 0 then
            weaponsInContainer = 'bronie: ' .. table.concat(weapons, ', ')
        else
            weaponsInContainer = ''
        end

        hecho(string.format("#777777[%d]#r ", i))
        hechoLink("[#aa0000-#r]", function() self:deleteContainer(i) end, "Usun pojemnik", true)
        hecho(string.format(" %-"..longestContainer.."s %-10s %s\n",
            v.nameNom,
            t,
            weaponsInContainer
        ))
    end

    print("")

    local pairColors = {'#aaaa00', '#aa00aa', '#00aaaa'}
    local pairs = {}
    local pairIndex = 1

    print("--- BRON ---")
    for i, v in pairsByKeys(self.eq.weapons) do
        local pair
        local pairDesc
        local cont 
        local color
        if v.container then
            cont = string.format('pojemnik: [%d] %s', v.container, self:getContainer(v.container).nameNom)
        else
            cont = '[PRZYPISZ]'
        end

        color = '#bbbbbb'

        if v.pairedWeapon then
            pair = self:getWeapon(v.pairedWeapon)
            if not pairs[i] then
                pairs[i] = pairColors[pairIndex]
                pairs[tonumber(v.pairedWeapon)] = pairColors[pairIndex]
                pairIndex = pairIndex + 1
                color = pairs[i]
            else
                color = pairs[i]
            end
            -- print(dump_table(pairs))
            -- string.format('%s[%d] %s#r', color, v.pairedWeapon, pair.nameNom)
        end

        local containersAssignments = {}
        local pairAssignments = {}
        
        for j, c in ipairs(self.eq.containers) do
            local fun = function()
                expandAlias(string.format("/przypisz b%d do p%d", i, j))
                self:cmdList()
            end

            containersAssignments[c.nameNom] = fun
        end

        for j, w in ipairs(self.eq.weapons) do
            local fun = function()
                expandAlias(string.format('/paruj b%d z b%d', i, j))
                self:cmdList()
            end

            pairAssignments[w.nameNom] = fun
        end

        hecho(string.format('#777777[%d]#r ', i))
        hechoLink("[#aa0000-#r]", function() self:deleteWeapon(i) end, "Usun bron", true)
        hecho(' ')
        hechoLink("[#00ff00D#r]", function() expandAlias('/d'..i) end, 'Dobadz', true)
        hecho(' ')
        hechoLink("[#ffff00O#r]", function() expandAlias('/o'..i) end, 'Opusc', true)
        hecho(string.format(" %s%-"..longestWeapon.."s#r ", color, v.nameNom))
        hechoPopup(string.format("%-"..(longestContainer + 15).."s", cont),
            table.values(containersAssignments),
            table.keys(containersAssignments),
            true)
        hechoPopup('[PARUJ]',
            table.values(pairAssignments),
            table.keys(pairAssignments),
            true)
        print('')
        -- print(string.format("[%d] %s", i, self:describeWeapon(i)))
    end
end


function scripts.gear:cmdWield(number)
    if not tonumber(number) then number = '1' end
    local res = self:wieldWeapon(number)
    return res
end


function scripts.gear:cmdUnwield(number)
    if not tonumber(number) then number = '1' end
    local res = self:unwieldWeapon(number)
    return res
end


function scripts.gear:cmdAssign(weaponNum, containerNum, noConfirmation)
    local weapon = self:getWeapon(weaponNum)
    local container = self:getContainer(containerNum)

    if not weapon then
        return pluginMsg(self.tag, 'error', 'Bron nr %d nie zostala zdefiniowana', weaponNum)
    end

    if not container then
        return pluginMsg(self.tag, 'error', 'Pojemnik %d nie zostal zdefiniowany', containerNum)
    end

    if not noConfirmation then
        pluginMsg(self.tag, 'ok', 'Bron %d (%s) przypisana do pojemnika %d (%s)', weaponNum, weapon.nameNom, containerNum, container.nameNom)
    end

    self:saveData()
    return self:assignWeaponToContainer(weaponNum, containerNum)
end


function scripts.gear:cmdPair(weapon1, weapon2)

    if weapon2 == "0" or weapon2 == 0 then
        return self:unpairWeapon(weapon1)
    end

    local res = self:pairWeapon(weapon1, weapon2)

    if res then
        pluginMsg(self.tag, 'ok', 'Sparowano #ffffff%s#r i #ffffff%s#r', self:inflect(res[1].nameNom, 4), self:inflect(res[2].nameNom, 4))
    else
        return
    end
end


function scripts.gear:cmdExamineContainer(number)
    local cont
    number = tonumber(number) or 1
    -- print("NUMBER="..number)
    cont = self:getContainer(number)

    if not cont then
        return error('Pojemnik nr ' .. number .. ' nie zostal ustawiony.')        
    end

    return send('ob ' .. self:inflect(cont.nameNom, 4), true)
end

function scripts.gear:cmdOpenContainer(number)
    return self:openContainer(number)
end

function scripts.gear:cmdCloseContainer(number)
    return self:closeContainer(number)
end

function scripts.gear:cmdGetFromContainer(number, items)
    if not tonumber(number) then number = 1 end

    local cont = self:getContainer(number)

    if not cont then
        return error('Brak zdefiniowanego pojemnika nr ' .. number)
    end

    items = items:gsub(' i ', ', '):split(', ')

    for _, i in pairs(items) do
        self:getFromContainer(number, i)
    end
end


function scripts.gear:cmdPutIntoContainer(number, items)
    if not tonumber(number) then number = 1 end
    local cont = self:getContainer(number)

    if not cont then
        return error('Brak zdefiniowanego pojemnika nr ' .. number)
    end

    items = items:gsub(' i ', ', '):split(', ')

    for _, i in pairs(items) do
        self:putIntoContainer(number, i)
    end
end



function scripts.gear:cmdGetValuables(number, item)
    local num, cont = self:findContainerByType('sakiewka')
    
    if not tonumber(number) and num then
        number = num
    end

    if number then
        num = number
    end

    return self:cmdGetFromContainer(num, 'monety')
    
end


function scripts.gear:cmdPutValuables(number, item)
    local num, cont = self:findContainerByType('sakiewka')
    
    if not tonumber(number) and num then
        number = num
    end

    if number then
        num = number
    end    

    return self:cmdPutIntoContainer(num, item)
end


function scripts.gear:cmdRenumber(category, n1, n2)
    local cat, catPl
    local item1, item2

    n1 = tonumber(n1)
    n2 = tonumber(n2)

    -- print(dump_table(matches))
    if category == 'p' or category == 'pojemnik' then
        cat = 'containers'
        catPl = 'pojemnika'
        item1 = self:getContainer(n1)
        item2 = self:getContainer(n2)
    elseif category == 'b' or category == 'bron' then
        cat = 'weapons'
        catPl = 'broni'
        item1 = self:getWeapon(n1)
        item2 = self:getWepaon(n2)
    end

    if not item1 then
        return error('Nie ustawiono ' .. catPl .. ' nr ' .. n1)
    end

    -- print("ITEM1: " .. dump_table(item1))
    -- print("ITEM2: " .. dump_table(item2))

    if item2 then
        self.eq[cat]['x'] = table.dup(item2)
        -- print(dump_table(self.eq[cat]))
        self.eq[cat][n2] = table.dup(item1)
        self.eq[cat][n1] = table.dup(self.eq[cat]['x'])
        self.eq[cat]['x'] = nil
        pluginMsg(self.tag, 'ok', '%s (%d) i %s (%d) zamienione miejscami.', item1.nameNom, n1, item2.nameNom, n2)
    else
        self.eq[cat][n2] = table.dup(item1)
        self.eq[cat][n1] = nil
        pluginMsg(self.tag, 'ok', '%s (%d) od teraz ma nr %d', item1.nameNom, n1, n2)
    end

    pluginMsg(self.tag, 'info', 'Pamietaj o zmianie przypisania par lub pojemnikow.')

end


function scripts.gear:cmdSetType(number, t)
    return self:setContainerType(number, t)
end

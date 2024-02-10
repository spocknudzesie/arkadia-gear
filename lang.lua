string.getGender = function(self)
    local ending = self:sub(-1)

    if ending == 'a' then
        return 'f'
    elseif ending == 'e' or ending == 'o' then
        return 'n'
    else
        return 'm'
    end
end


string.inflectAdj = function(self, case)
    local stem = self:sub(1, -2)
    local stem_ending = stem:sub(-1)
    local soft
    local gender = self:getGender()

    -- print(string.format('inflecting adjective %s (gender %s) in case %d', self, gender, case))

    if self:match('j$') or self:match('ja$') or self:match('je$') then
        local endings = {
            f = {'a', 'ej', 'ej', 'a', 'a', 'ej'},
            m = {'j', 'jego', 'jemu', 'j', 'im', 'im'},
            n = {'je', 'jego', 'jemu', 'j', 'im', 'im'}
        }
        
        return self:sub(1, -2) .. endings[gender][case]
    end

    if gender == 'm' then
        if self:match('i$') then
            local endings = {'', 'ego', 'emu', '', 'm', 'm'}
            return self .. endings[case]
        else
            local endings = {'y', 'ego', 'emu', 'y', 'ym', 'ym'}
            return stem .. endings[case]
        end
    end

    if gender == 'n' then
        local endings = {'e', 'ego', 'emu', 'e', 'ym', 'ym'}
        
        if self:match('ie$') then
            endings = {'e', 'ego', 'emu', 'e', 'm', 'm'}
        end
        
        return stem .. endings[case]
    end

    if gender == 'f' then
        local endings = {'a', 'ej', 'ej', 'a', 'a', 'ej'}

        if self:match('[kg].$') then
            endings = {'a', 'iej', 'iej', 'a', 'a', 'iej'}
        end

        return stem .. endings[case]
    end
end


string.inflect = function(self, t, case, anim)

    local cases = {
        gen = 2,
        dop = 2,
        dat = 3,
        cel = 3,
        acc = 4,
        bie = 4,
        ins = 5,
        nar = 5,
        loc = 6,
        mie = 6
    }

    -- print(string.format('inflecting %s as %s into %s', self, t, case))

    if t ~= 'adj' and t ~= 'noun' then
        return string.format('%s nie jest prawidlowym typem odmiany', t)
    end

    if type(case) == 'number' then
        if case < 2 or case > 6 then
            return string.format('%d to bledny przypadek', case)
        end
    elseif cases[case] and (cases[case] < 2 or cases[case] > 6) then
        return string.format('%d to bledny przypadek', case)
    end

    if type(case) == 'string' then
        case = cases[case]
    end

    if t == 'adj' then
        if case == 4 and anim == true then
            case = 2
        end
        
        return self:inflectAdj(case)
    end
end



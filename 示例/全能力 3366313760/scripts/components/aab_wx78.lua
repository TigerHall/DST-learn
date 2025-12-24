local WX78 = Class(function(self, inst)
    self.inst = inst
end)

function WX78:OnSave()
    local data = {}

    data.gears_eaten = self.inst._gears_eaten
    -- WX-78 needs to manually save/load health, hunger, and sanity, in case their maxes
    -- were modified by upgrade circuits, because those components only save current,
    -- and that gets overridden by the default max values during construction.
    -- So, if we wait to re-apply them in our OnLoad, we will have them properly
    -- (as entity OnLoad runs after component OnLoads)
    data._wx78_health = self.inst.components.health.currenthealth
    data._wx78_sanity = self.inst.components.sanity.current
    data._wx78_hunger = self.inst.components.hunger.current

    return data
end

function WX78:OnLoad(data)
    if not data then return end

    local inst = self.inst
    if data.gears_eaten ~= nil then
        inst._gears_eaten = data.gears_eaten
    end

    -- Compatability with pre-refresh WX saves
    if data.level ~= nil then
        inst._gears_eaten = (inst._gears_eaten or 0) + data.level
    end

    -- WX-78 needs to manually save/load health, hunger, and sanity, in case their maxes
    -- were modified by upgrade circuits, because those components only save current,
    -- and that gets overridden by the default max values during construction.
    -- So, if we wait to re-apply them in our OnLoad, we will have them properly
    -- (as entity OnLoad runs after component OnLoads)
    if data._wx78_health then
        inst.components.health:SetCurrentHealth(data._wx78_health)
    end

    if data._wx78_sanity then
        inst.components.sanity.current = data._wx78_sanity
    end

    if data._wx78_hunger then
        inst.components.hunger.current = data._wx78_hunger
    end
end

return WX78

local Woby = Class(function(self, inst)
    self.inst = inst
end)

function Woby:OnSave()
    local data = {}
    local inst = self.inst
    data.woby = inst.woby ~= nil and inst.woby:GetSaveRecord() or nil
    data.buckdamage = inst._wobybuck_damage > 0 and inst._wobybuck_damage or nil
    return data
end

function Woby:OnLoad(data)
    if not data then return end
    local inst = self.inst

    if data.woby ~= nil then
        inst._woby_spawntask:Cancel()
        inst._woby_spawntask = nil

        local woby = SpawnSaveRecord(data.woby)
        inst.woby = woby
        if woby ~= nil then
            if inst.migrationpets ~= nil then
                table.insert(inst.migrationpets, woby)
            end
            woby:LinkToPlayer(inst)

            woby.AnimState:SetMultColour(0, 0, 0, 1)
            woby.components.colourtweener:StartTween({ 1, 1, 1, 1 }, 19 * FRAMES)
            local fx = SpawnPrefab(woby.spawnfx)
            fx.entity:SetParent(woby.entity)

            inst:ListenForEvent("onremove", inst._woby_onremove, woby)
        end
    end
    inst._wobybuck_damage = data.buckdamage or 0
end

return Woby

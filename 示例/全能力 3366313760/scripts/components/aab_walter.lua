local Walter = Class(function(self, inst)
    self.inst = inst
end)

function Walter:OnSave()
    local data = {}
    local inst = self.inst

    if inst.woby then
        data.woby = inst.woby:GetSaveRecord()
    else
        data.baglock = inst.baglock
    end
    data.buckdamage = inst._wobybuck_damage > 0 and inst._wobybuck_damage or nil
    data.wobycmd = inst.woby_commands_classified and inst.woby_commands_classified:OnSave() or nil

    return data
end

function Walter:OnLoad(data)
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
                if data.wobycmd then
                    data.wobycmd.sit = nil
                end
            end
            woby:LinkToPlayer(inst)
            if inst.woby_commands_classified then
                inst.woby_commands_classified:OnLoad(data.wobycmd)
            end

            woby.AnimState:SetMultColour(0, 0, 0, 1)
            woby.components.colourtweener:StartTween({ 1, 1, 1, 1 }, 19 * FRAMES)
            local fx = SpawnPrefab(woby.spawnfx)
            fx.entity:SetParent(woby.entity)

            inst:ListenForEvent("onremove", inst._woby_onremove, woby)
        end
    else
        inst.baglock = data.baglock
    end
    inst._wobybuck_damage = data.buckdamage or 0
end

return Walter

--- 保存小惊吓
local SmallGhost = Class(function(self, inst)
    self.inst = inst
end)

function SmallGhost:OnSave()
    local data = {}
    if self.inst.questghost ~= nil then
        data.questghost = self.inst.questghost:GetSaveRecord()
        self.inst.questghost = nil
    end
    return data
end

function SmallGhost:OnLoad(data)
    if data ~= nil then
        if data.questghost ~= nil and data.questghost == nil then
            local questghost = SpawnSaveRecord(data.questghost)
            if questghost ~= nil then
                if self.inst.migrationpets ~= nil then
                    table.insert(self.inst.migrationpets, questghost)
                end
                questghost.SoundEmitter:PlaySound("dontstarve/common/ghost_spawn")
                questghost:LinkToPlayer(self.inst)
            end
        end
    end
end

return SmallGhost

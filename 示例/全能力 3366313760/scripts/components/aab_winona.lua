local Winona = Class(function(self, inst)
    self.inst = inst
end)

function Winona:OnSave()
    return {
        charlie_vinesave = self.inst.charlie_vinesave
    }
end

function Winona:OnLoad(data)
    self.inst.charlie_vinesave = data.charlie_vinesave or self.inst.charlie_vinesave
    if not self.inst.components.health:IsDead() then
        self.inst.charlie_vinesave = nil
    end
end

return Winona

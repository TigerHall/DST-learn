local function Init(inst, self)
    if TUNING.AAB_HEALTH_MAX and self.currenthealth then
        inst.components.health:SetCurrentHealth(self.currenthealth)
    end
    if TUNING.AAB_SANITY_MAX and self.currentsanity then
        inst.components.sanity.current = self.currentsanity
    end
    if TUNING.AAB_HUNGER_MAX and self.currenthunger then
        inst.components.hunger.current = self.currenthunger
    end
end

---记录三维最大值
local Max = Class(function(self, inst)
    self.inst = inst

    self.currenthealth = nil
    self.currentsanity = nil
    self.currenthunger = nil

    inst:DoTaskInTime(0, Init, self)
end)

function Max:OnSave()
    return {
        currenthealth = TUNING.AAB_HEALTH_MAX and self.inst.components.health.currenthealth or nil,
        currentsanity = TUNING.AAB_SANITY_MAX and self.inst.components.sanity.current or nil,
        currenthunger = TUNING.AAB_HUNGER_MAX and self.inst.components.hunger.current or nil
    }
end

function Max:OnLoad(data)
    if not data then return end

    self.currenthealth = data.currenthealth or self.currenthealth
    self.currentsanity = data.currentsanity or self.currentsanity
    self.currenthunger = data.currenthunger or self.currenthunger
end

return Max

TUNING.AAB_HEALTH_MAX = GetModConfigData("health_max")
TUNING.AAB_SANITY_MAX = GetModConfigData("sanity_max")
TUNING.AAB_HUNGER_MAX = GetModConfigData("hunger_max")

local Utils = require("aab_utils/utils")

local function SetMaxHealthBefore(self, amount, ...)
    return nil, false, { self, TUNING.AAB_HEALTH_MAX, ... }
end
local function SetMaxSanityBefore(self, amount, ...)
    return nil, false, { self, TUNING.AAB_SANITY_MAX, ... }
end
local function SetMaxHungerBefore(self, amount, ...)
    return nil, false, { self, TUNING.AAB_HUNGER_MAX, ... }
end

AddPlayerPostInit(function(inst)
    if not TheWorld.ismastersim then return end

    if TUNING.AAB_HEALTH_MAX then
        inst.components.health:SetMaxHealth(TUNING.AAB_HEALTH_MAX)
        Utils.FnDecorator(inst.components.health, "SetMaxHealth", SetMaxHealthBefore)
    end
    if TUNING.AAB_SANITY_MAX then
        inst.components.sanity:SetMax(TUNING.AAB_SANITY_MAX)
        Utils.FnDecorator(inst.components.sanity, "SetMax", SetMaxSanityBefore)
    end
    if TUNING.AAB_HUNGER_MAX then
        inst.components.hunger:SetMax(TUNING.AAB_HUNGER_MAX)
        Utils.FnDecorator(inst.components.hunger, "SetMax", SetMaxHungerBefore)
    end

    inst:AddComponent("aab_max")
end)

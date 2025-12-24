local Utils = require("aab_utils/utils")

local WEAPON_FINITEUSES_MULT = GetModConfigData("weapon_finiteuses_mult") / 100

local function IsWeapon(inst)
    return inst.components.equippable and inst.components.equippable.equipslot == EQUIPSLOTS.HANDS
end

local function UseBefore(self, num, ...)
    if IsWeapon(self.inst) then
        return nil, false, { self, (num or 1) * WEAPON_FINITEUSES_MULT, ... }
    end
end

AddComponentPostInit("finiteuses", function(self)
    Utils.FnDecorator(self, "Use", UseBefore)
end)

----------------------------------------------------------------------------------------------------

AddPlayerPostInit(function(inst)
    if not TheWorld.ismastersim then return end

    if not inst.components.preserver then
        inst:AddComponent("preserver")
        inst.components.preserver:SetPerishRateMultiplier(1)
    end
end)

local function GetPerishRateMultiplierAfter(retTab, self, item)
    if item and item.components.perishable and IsWeapon(item) then
        retTab[1] = retTab[1] * WEAPON_FINITEUSES_MULT
    end
    return retTab
end

AddComponentPostInit("preserver", function(self)
    Utils.FnDecorator(self, "GetPerishRateMultiplier", nil, GetPerishRateMultiplierAfter)
end)

----------------------------------------------------------------------------------------------------

AddPrefabPostInitAny(function(inst)
    if not TheWorld.ismastersim then return end

    if inst.components.fueled and IsWeapon(inst) then
        inst.components.fueled.rate_modifiers:SetModifier(inst, WEAPON_FINITEUSES_MULT, "aab_weapon_finiteuses_mult")
    end
end)

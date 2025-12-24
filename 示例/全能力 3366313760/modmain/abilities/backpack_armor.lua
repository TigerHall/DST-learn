local Utils = require("aab_utils/utils")

local BACKPACK_ARMOR = GetModConfigData("backpack_armor") / 100

-- 不消耗耐久
local function SetConditionBefore(self, amount, ...)
    return nil, false, { self, self.maxcondition, ... }
end

AddPrefabPostInitAny(function(inst)
    if not TheWorld.ismastersim then return end

    if inst.components.container
        and inst.components.equippable
        -- and inst.components.equippable.equipslot == EQUIPSLOTS.BODY 可能会有多格mod改掉
        and inst.components.inventoryitem
    then
        if inst.components.armor then
            if inst.components.armor.absorb_percent and inst.components.armor.absorb_percent <= BACKPACK_ARMOR then
                inst.components.armor:SetAbsorption(BACKPACK_ARMOR) --两数取最大
            end
        else
            inst:AddComponent("armor")
            inst.components.armor:InitCondition(100, BACKPACK_ARMOR)
        end

        Utils.FnDecorator(inst.components.armor, "SetCondition", SetConditionBefore)
    end
end)

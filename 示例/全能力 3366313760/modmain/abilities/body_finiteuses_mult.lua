local Utils = require("aab_utils/utils")

local BODY_FINITEUSES_MULT = GetModConfigData("body_finiteuses_mult") / 100

local function IsBody(inst)
    return inst.components.equippable and inst.components.equippable.equipslot ~= EQUIPSLOTS.HANDS
end

----------------------------------------------------------------------------------------------------

-- 针对新鲜度的hook，找到一个真不容易啊，只对身上的物品有效
AddPlayerPostInit(function(inst)
    if not TheWorld.ismastersim then return end

    if not inst.components.preserver then
        inst:AddComponent("preserver")
        inst.components.preserver:SetPerishRateMultiplier(1) --竟然不给默认值
    end
end)

local function GetPerishRateMultiplierAfter(retTab, self, item)
    if item and item.components.perishable and IsBody(item) then
        retTab[1] = retTab[1] * BODY_FINITEUSES_MULT
    end
    return retTab
end

AddComponentPostInit("preserver", function(self)
    Utils.FnDecorator(self, "GetPerishRateMultiplier", nil, GetPerishRateMultiplierAfter)
end)

----------------------------------------------------------------------------------------------------

AddPrefabPostInitAny(function(inst)
    if not TheWorld.ismastersim then return end

    if inst.components.armor and IsBody(inst) then
        inst.components.armor.conditionlossmultipliers:SetModifier(inst, BODY_FINITEUSES_MULT, "aab_body_finiteuses_mult")
    end
end)

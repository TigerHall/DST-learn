local Utils = require("aab_utils/utils")
local STRUCTURE_INVINCIBLE = GetModConfigData("structure_invincible")


local function DoDeltaBefore(self, amount, overtime, cause, ignore_invincible, afflicter)
    return { 0 }, amount and amount < 0            --扣血
        and not (afflicter and afflicter:HasTag("player")) --非玩家
end

local function WorkedBy_InternalBefore(self, worker)
    return nil, not worker or not worker:HasTag("player")
end

local INVINCIBLE_ONEOF_TAGS = { "wall", "door" }
if STRUCTURE_INVINCIBLE == 2 then
    table.insert(INVINCIBLE_ONEOF_TAGS, "structure")
end
local function ShouldInvincible(ent)
    if ent:HasTag("HAMMER_workable") and ent:HasOneOfTags(INVINCIBLE_ONEOF_TAGS) then
        --建筑和墙体
        return true
    end

    --不添加雕像，暗影三基佬需要，有些mod可能也需要
    -- if ent:HasTag("heavy") and ent.components.equippable and ent.components.heavyobstaclephysics and ent.components.inventoryitem then
    --     --雕像
    --     return true
    -- end

    return false
end

local function OnIgnite(inst, data)
    inst:DoTaskInTime(0, function()
        if inst.components.burnable and inst.components.burnable.onburnt and not inst:HasTag("campfire") then --火坑不要熄灭
            inst:SpawnChild("dreadstone_spawn_fx")
            inst.components.burnable:Extinguish()
        end
    end)
end

AddPrefabPostInitAny(function(inst)
    if not TheWorld.ismastersim then return end

    if ShouldInvincible(inst) then --建筑的判断条件
        if inst.components.health then
            Utils.FnDecorator(inst.components.health, "DoDelta", DoDeltaBefore)
        end
        if inst.components.workable then
            Utils.FnDecorator(inst.components.workable, "WorkedBy_Internal", WorkedBy_InternalBefore)
        end
        if inst.components.burnable then
            inst:ListenForEvent("onignite", OnIgnite)
        end
    end
end)

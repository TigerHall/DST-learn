local Constructor = require("aab_utils/constructor")
local Utils = require("aab_utils/utils")
local normalbrain = require "brains/aab_my_pigbrain"

local function OnChangedLeader(inst, new_leader, prev_leader)
    if new_leader then
        inst.aab_leader:set(new_leader)
    else
        ErodeAway(inst) --玩家消失猪人也消失
    end
end

local function ShouldAcceptItem(inst, item)
    if item.components.equippable then --装备都要
        return true
    elseif inst.components.eater:CanEat(item) then
        local foodtype = item.components.edible.foodtype
        if foodtype == FOODTYPE.MEAT or foodtype == FOODTYPE.HORRIBLE then
            return true
        elseif foodtype == FOODTYPE.VEGGIE or foodtype == FOODTYPE.RAW then
            local last_eat_time = inst.components.eater:TimeSinceLastEating()
            return (last_eat_time == nil or
                    last_eat_time >= TUNING.PIG_MIN_POOP_PERIOD)
                and (inst.components.inventory == nil or
                    not inst.components.inventory:Has(item.prefab, 1))
        end
        return true
    end
end

local function OnGetItemFromPlayer(inst, giver, item)
    --I eat food
    if item.components.edible ~= nil then
        --meat makes us friends (unless I'm a guard)
        if (item.components.edible.foodtype == FOODTYPE.MEAT or
                item.components.edible.foodtype == FOODTYPE.HORRIBLE
            ) and
            item.components.inventoryitem ~= nil and
            ( --make sure it didn't drop due to pockets full
                item.components.inventoryitem:GetGrandOwner() == inst or
                --could be merged into a stack
                (not item:IsValid() and
                    inst.components.inventory:FindItem(function(obj)
                        return obj.prefab == item.prefab
                            and obj.components.stackable ~= nil
                            and obj.components.stackable:IsStack()
                    end) ~= nil)
            ) then
            if inst.components.combat:TargetIs(giver) then
                inst.components.combat:SetTarget(nil)
            elseif giver.components.leader ~= nil then
                giver:PushEvent("makefriend") --这事件好像也没用过
            end
        end
        if inst.components.sleeper:IsAsleep() then
            inst.components.sleeper:WakeUp()
        end
    end

    --I wear hats
    if item.components.equippable ~= nil and item.components.equippable.equipslot then
        local current = inst.components.inventory:GetEquippedItem(item.components.equippable.equipslot)
        if current ~= nil then
            inst.components.inventory:DropItem(current)
        end
        inst.components.inventory:Equip(item)
        -- inst.AnimState:Show("hat") --需要吗？
    end
end

local function GetLevel(inst)
    local leader = inst.aab_leader:value()
    if leader and leader.replica.aab_my_pig then
        return leader.replica.aab_my_pig:GetCurrent()
    end
    return 0 --有玩家报错不存在过，虽然不知道为什么，这里避免崩溃
end

local function OnWritten(inst, text, writer)
    inst.components.named:SetName(text, writer ~= nil and writer.userid or nil)
end

-- 猪人装备武器也不会用武器那个手攻击，干脆别显示了
local function OnEquip(inst, data)
    if data and data.eslot == EQUIPSLOTS.HANDS then
        inst.AnimState:Hide("ARM_carry")
        inst.AnimState:Show("ARM_normal")
    end
end

local function Init(inst)
    inst.aab_leader = net_entity(inst.GUID, "aab_my_pig.aab_leader")
    inst.GetLevel = GetLevel

    inst:AddTag("_writeable")

    if not TheWorld.ismastersim then return end

    inst:RemoveTag("_writeable")

    inst.components.locomotor:SetTriggersCreep(false)

    if not inst.components.writeable then
        inst:AddComponent("writeable")
    end
    inst.components.writeable:SetOnWrittenFn(OnWritten)
    inst.components.writeable:SetDefaultWriteable(false)

    inst.components.follower.maxfollowtime = nil
    inst.components.follower.OnChangedLeader = OnChangedLeader
    inst.components.follower.keepdeadleader = true
    inst.components.follower:KeepLeaderOnAttacked()
    inst.components.follower.AddLoyaltyTime = function() end --这个会把雇佣关系取消的

    inst:SetBrain(normalbrain)

    inst:RemoveComponent("werebeast") --移除这个组件希望sg里不要有什么兼容问题
    Utils.FakeComponent(inst, "werebeast")

    inst.components.health:StartRegen(TUNING.AAB_MY_PIG_HEALTH_HEAL, 1)

    inst.components.trader:SetAcceptTest(ShouldAcceptItem)
    inst.components.trader.onaccept = OnGetItemFromPlayer

    inst:ListenForEvent("equip", OnEquip)

    inst.persists = false
end

return Constructor.CopyPrefab("aab_my_pig", "pigman", { init = Init })

local Utils = require("aab_utils/utils")

local MONKEY_WEAK = GetModConfigData("monkey_weak")

-- 诅咒饰品改成藏宝图
local function DropItemBefore(self, item, ...)
    if item and item.prefab == "cursed_monkey_token" then
        item = ReplacePrefab(item, "stash_map")
        return nil, false, { self, item, ... }
    end
end

local function common(inst)
    if not TheWorld.ismastersim then return end

    local mult = MONKEY_WEAK == 1 and 0.4
        or MONKEY_WEAK == 2 and 0.7
        or MONKEY_WEAK == 3 and 1.2
        or 1.5
    inst.components.health:SetMaxHealth(inst.components.health.maxhealth * mult * mult)
    inst.components.locomotor:SetExternalSpeedMultiplier(inst, "aab_monkey_weak", mult)
    inst.components.combat.externaldamagemultipliers:SetModifier(inst, mult, "aab_monkey_weak")

    if MONKEY_WEAK == 1 then
        Utils.FnDecorator(inst.components.inventory, "DropItem", DropItemBefore)
    end
end

AddPrefabPostInit("powder_monkey", common)
AddPrefabPostInit("prime_mate", common)

-- 源源不断的大便
local function OnItemLose(inst, data)
    if not inst.components.inventory:IsFull()
        and not inst.components.inventory:FindItem(function(ent) return ent.prefab == "poop" end) then
        inst.components.inventory:GiveItem(SpawnPrefab("poop"))
    end
end

-- 没有猴子窝创建猴子窝
local function OnEntitySleep(inst, data)
    if not inst._aab_no_home_time and not inst.components.homeseeker then
        inst._aab_no_home_time = GetTime()
    end
end
local function OnEntityWake(inst, data)
    if inst._aab_no_home_time
        and GetTime() - inst._aab_no_home_time > TUNING.TOTAL_DAY_TIME
        and not FindEntity(inst, 12, function(ent) return ent.prefab == "monkeybarrel" end)
    then
        ReplacePrefab(inst, "monkeybarrel")
    end
end

AddPrefabPostInit("monkey", function(inst)
    common(inst)

    if not TheWorld.ismastersim then return end

    if MONKEY_WEAK == 4 then
        inst.components.inventory:GiveItem(SpawnPrefab("poop"))

        inst:ListenForEvent("itemlose", OnItemLose)
        inst:ListenForEvent("entitysleep", OnEntitySleep)
        inst:ListenForEvent("entitywake", OnEntityWake)
    end
end)


----------------------------------------------------------------------------------------------------

local function Remove(inst, thrower, target)
    if thrower:IsValid() and thrower.components.combat and not IsEntityDead(thrower) then
        thrower.components.combat:GetAttacked(target, 20)
    end

    inst:Remove()
end

-- 有概率炸膛
local function OnThrown(inst, data)
    if data and data.thrower and data.target and math.random() < MONKEY_WEAK * 0.3 then
        inst:DoTaskInTime(0, Remove, data.thrower, data.target)
    end
end

AddPrefabPostInit("monkeyprojectile", function(inst)
    if not TheWorld.ismastersim then return end

    if MONKEY_WEAK <= 2 then
        inst:ListenForEvent("onthrown", OnThrown)
    end
end)

----------------------------------------------------------------------------------------------------

if MONKEY_WEAK == 4 then
    AddPrefabPostInit("world", function(inst)
        if not TheWorld.ismastersim then return end

        inst:AddComponent("aab_monkeyspawner")
    end)
end

----------------------------------------------------------------------------------------------------

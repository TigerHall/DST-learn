local prefs = {}

local beecommon = require "brains/beecommon"

local workersounds =
{
    takeoff = "dontstarve/bee/bee_takeoff",
    attack = "dontstarve/bee/bee_attack",
    buzz = "dontstarve/bee/bee_fly_LP",
    hit = "dontstarve/bee/bee_hurt",
    death = "dontstarve/bee/bee_death",
}

local killersounds =
{
    takeoff = "dontstarve/bee/killerbee_takeoff",
    attack = "dontstarve/bee/killerbee_attack",
    buzz = "dontstarve/bee/killerbee_fly_LP",
    hit = "dontstarve/bee/killerbee_hurt",
    death = "dontstarve/bee/killerbee_death",
}

local function OnWorked(inst, worker)
    inst:PushEvent("detachchild")
    if worker.components.inventory ~= nil then
        inst.SoundEmitter:KillAllSounds()

        worker.components.inventory:GiveItem(inst, nil, inst:GetPosition())
    end
end

local function bonus_damage_via_allergy(inst, target, damage, weapon)
    return (target:HasTag("allergictobees") and TUNING.BEE_ALLERGY_EXTRADAMAGE) or 0
end

local function OnDropped(inst)
    if inst.buzzing and not (inst:IsAsleep() or inst.SoundEmitter:PlayingSound("buzz")) then
        inst.SoundEmitter:PlaySound(inst.sounds.buzz, "buzz")
    end
    inst.sg:GoToState("catchbreath")
    if inst.components.workable ~= nil then
        inst.components.workable:SetWorkLeft(1)
    end
    if inst.brain ~= nil then
        inst.brain:Start()
    end
    if inst.sg ~= nil then
        inst.sg:Start()
    end
    if inst.components.stackable ~= nil and inst.components.stackable:IsStack() then
        local x, y, z = inst.Transform:GetWorldPosition()
        while inst.components.stackable:IsStack() do
            local item = inst.components.stackable:Get()
            if item ~= nil then
                if item.components.inventoryitem ~= nil then
                    item.components.inventoryitem:OnDropped()
                end
                item.Physics:Teleport(x, y, z)
            end
        end
    end
end

local function OnPickedUp(inst)
    inst.sg:GoToState("idle")
    inst.SoundEmitter:KillSound("buzz")
    inst.SoundEmitter:KillAllSounds()
end

local function EnableBuzz(inst, enable)
    if enable then
        if not inst.buzzing then
            inst.buzzing = true
            if not (inst.components.inventoryitem:IsHeld() or inst:IsAsleep() or inst.SoundEmitter:PlayingSound("buzz")) then
                inst.SoundEmitter:PlaySound(inst.sounds.buzz, "buzz")
            end
        end
    elseif inst.buzzing then
        inst.buzzing = false
        inst.SoundEmitter:KillSound("buzz")
    end
end

local function OnWake(inst)
    if inst.buzzing and not (inst.components.inventoryitem:IsHeld() or inst.SoundEmitter:PlayingSound("buzz")) then
        inst.SoundEmitter:PlaySound(inst.sounds.buzz, "buzz")
    end
end

local function OnSleep(inst)
    inst.SoundEmitter:KillSound("buzz")
end

local RETARGET_MUST_TAGS = { "_combat", "_health" }                 -- 必须有这些标签才能作为目标
local RETARGET_CANT_TAGS = { "insect", "INLIMBO", "plantkin" }      -- 不能有这些标签
local RETARGET_ONEOF_TAGS = { "character", "animal", "monster" }    -- 有其中任意一个即可作为目标
local function Retarget(inst)
    if inst.prefab == "honorbee" and math.random() < 0.9 then
        return nil
    else
        return FindEntity(inst, SpringCombatMod(8),
            function(guy)
                return inst.components.combat:CanTarget(guy) and
                    not (guy.components.skilltreeupdater and guy.components.skilltreeupdater:IsActivated("wormwood_bugs"))
            end,
            RETARGET_MUST_TAGS,
            RETARGET_CANT_TAGS,
            RETARGET_ONEOF_TAGS)
    end
end

local function ShouldSleep(inst)
    return false
end

local function ShouldWake(inst)
    return true
end

local function MakeBee(name, data)
    local assets =
    {
        Asset("ANIM", "anim/"..name..".zip"),
    }

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddDynamicShadow()
        inst.entity:AddNetwork()

        MakeFlyingCharacterPhysics(inst, 1, .5)

        inst.DynamicShadow:SetSize(.8, .5)

        inst:AddTag("bee")
        inst:AddTag("insect")
        inst:AddTag("smallcreature")
        inst:AddTag("cattoyairborne")
        inst:AddTag("flying")
        inst:AddTag("ignorewalkableplatformdrowning")

        inst.AnimState:SetBank(name)
        inst.AnimState:SetBuild(name)
        inst.AnimState:PlayAnimation("idle", true)
        inst.AnimState:SetRayTestOnBB(true)

        MakeInventoryFloatable(inst)

        MakeFeedableSmallLivestockPristine(inst)

        if data.common_postinit ~= nil then
            data.common_postinit(inst)
        end

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
        inst.components.locomotor:EnableGroundSpeedMultiplier(false)
        inst.components.locomotor:SetTriggersCreep(false)

        inst:AddComponent("stackable")
        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.nobounce = true
        -- inst.components.inventoryitem:SetOnDroppedFn(OnDropped) Done in MakeFeedableSmallLivestock
        -- inst.components.inventoryitem:SetOnPutInInventoryFn(OnPickedUp)
        inst.components.inventoryitem.canbepickedup = false
        inst.components.inventoryitem.canbepickedupalive = true
        inst.components.inventoryitem.pushlandedevents = false
        inst.components.inventoryitem.atlasname = "images/inventoryimages/"..name..".xml"

        inst:AddComponent("lootdropper")

        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.NET)
        inst.components.workable:SetWorkLeft(1)
        inst.components.workable:SetOnFinishCallback(OnWorked)

        inst:AddComponent("health")

        inst:AddComponent("combat")
        inst.components.combat:SetPlayerStunlock(PLAYERSTUNLOCK.RARELY)
        inst.components.combat.bonusdamagefn = bonus_damage_via_allergy
        inst.components.combat:SetRetargetFunction(2, Retarget)

        inst:AddComponent("sleeper")
        inst.components.sleeper:SetSleepTest(ShouldSleep)
        inst.components.sleeper:SetWakeTest(ShouldWake)
        inst.components.sleeper.diminishingreturns = true

        inst:AddComponent("knownlocations")

        inst:AddComponent("inspectable")

        inst:AddComponent("tradable")

        inst:ListenForEvent("attacked", beecommon.OnAttacked)
        inst:ListenForEvent("worked", beecommon.OnWorked)

        MakeFeedableSmallLivestock(inst, TUNING.TOTAL_DAY_TIME*3, OnPickedUp, OnDropped)

        inst.buzzing = true
        inst.EnableBuzz = EnableBuzz
        inst.OnEntityWake = OnWake
        inst.OnEntitySleep = OnSleep

        if data.master_postinit ~= nil then
            data.master_postinit(inst)
        end

        return inst
    end

    table.insert(prefs, Prefab(name, fn, assets))
end

MakeBee("honor_bee", {
    common_postinit = function(inst)
        inst.Transform:SetSixFaced()

        inst:AddTag("honor")
    end,
    master_postinit = function(inst)
        inst.components.health:SetMaxHealth(TUNING.HONORBEE_HEALTH)
        inst.components.combat:SetDefaultDamage(TUNING.HONORBEE_DAMAGE)
        inst.components.combat:SetAttackPeriod(TUNING.HONORBEE_ATTACK_PERIOD)
        inst.components.combat:SetRange(TUNING.HONORBEE_ATTACK_RANGE)
        inst.components.combat.hiteffectsymbol = "mane"
        inst.components.combat.battlecryenabled = false

        inst:AddComponent("pollinator")

        inst.components.lootdropper:AddRandomLoot("honey", 30)
        inst.components.lootdropper:AddRandomLoot("stinger", 65)
        inst.components.lootdropper:AddRandomLoot("honor_splendor", 5)
        inst.components.lootdropper.numrandomloot = 1

        MakeSmallBurnableCharacter(inst, "mane")
        MakeSmallFreezableCharacter(inst, "mane")

        inst.sounds = workersounds
        inst.incineratesound = inst.sounds.death

        inst:SetStateGraph("SGbeeguard")
        local brain = require("brains/killerbeebrain")
        inst:SetBrain(brain)
    end,
})

MakeBee("terror_bee", {
    common_postinit = function(inst)
        inst.Transform:SetFourFaced()

        inst:AddTag("terror")
    end,
    master_postinit = function(inst)
        inst.components.health:SetMaxHealth(TUNING.TERRORBEE_HEALTH)
        inst.components.combat:SetDefaultDamage(TUNING.TERRORBEE_DAMAGE)
        inst.components.combat:SetAttackPeriod(TUNING.TERRORBEE_ATTACK_PERIOD)
        inst.components.combat:SetRange(TUNING.TERRORBEE_ATTACK_RANGE)
        inst.components.combat.hiteffectsymbol = "body"

        inst.components.lootdropper:AddRandomLoot("honey", 30)
        inst.components.lootdropper:AddRandomLoot("stinger", 60)
        inst.components.lootdropper:AddRandomLoot("terror_dangerous", 10)
        inst.components.lootdropper.numrandomloot = 1

        MakeSmallBurnableCharacter(inst, "body", Vector3(0, -1, 1))
        MakeTinyFreezableCharacter(inst, "body", Vector3(0, -1, 1))

        inst.sounds = killersounds
        inst.incineratesound = inst.sounds.death

        inst:SetStateGraph("SGbee")
        local brain = require("brains/killerbeebrain")
        inst:SetBrain(brain)
    end,
})

return unpack(prefs)
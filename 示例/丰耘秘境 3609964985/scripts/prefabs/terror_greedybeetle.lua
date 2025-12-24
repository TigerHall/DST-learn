local brain = require("brains/terror_greedybeetlebrain")

local sounds = {
    flap = "farming/creatures/lord_fruitfly/LP",
    hurt = "farming/creatures/lord_fruitfly/hit",
    attack = "farming/creatures/lord_fruitfly/attack",
    die = "farming/creatures/lord_fruitfly/die",
    die_ground = "farming/creatures/lord_fruitfly/hit",
    sleep = "farming/creatures/lord_fruitfly/sleep",
    buzz = "farming/creatures/lord_fruitfly/hit",
    spin = "farming/creatures/lord_fruitfly/spin",
    plant_attack = "farming/creatures/lord_fruitfly/plant_attack"
}

SetSharedLootTable("terror_greedybeetle",
{
    {"plantmeat",             1.00},
    {"terror_dangerous",      1.00},
    {"terror_dangerous",      1.00},
    {"terror_mucous",         1.00},
    {"terror_mucous",         1.00},
    {"terror_mucous",         1.00},
})

local EAT_SKILL_NAME = "EAT"
local EAT_SKILL_PERIOD = 8


local function OnLoad(inst, data)
    if data then
        inst.eaten_list = data.eaten_list
    end
end

local function OnSave(inst)
    local data = {
        eaten_list = inst.eaten_list
    }
    return data
end

local function KeepTargetFn(inst, target)
    local p1x, p1y, p1z = inst.components.knownlocations:GetLocation("home"):Get()
    local p2x, p2y, p2z = target.Transform:GetWorldPosition()
    local maxdist = TUNING.LORDFRUITFLY_DEAGGRO_DIST
    return inst.components.combat:CanTarget(target) and distsq(p1x, p1z, p2x, p2z) < maxdist * maxdist
end

local RETARGET_MUSTTAGS = { "player", "_combat" }
local RETARGET_CANTTAGS = { "playerghost" }
local function RetargetFn(inst)
    return not inst.planttarget and
        FindEntity(inst, TUNING.LORDFRUITFLY_TARGETRANGE, function(guy) return inst.components.combat:CanTarget(guy) end, RETARGET_MUSTTAGS, RETARGET_CANTTAGS) or nil
end

local function OnAttacked(inst, data)
    local attacker = data ~= nil and data.attacker or nil
    if attacker == nil then
        return
    end
    inst.planttarge = nil
    inst.components.combat:SetTarget(attacker)
end

local function OnDead(inst)
    for _, veggie in pairs(inst.eaten_list) do
        local prime = veggie.."_prime"
        if PrefabExists(prime) and math.random <= 0.3 then
            inst.components.lootdropper:SpawnLootPrefab(prime)
        else
            local product = veggie
            local seeds = veggie.."_seeds"
            local loots = {product, product, seeds, seeds, math.random() < 0.7 and product or seeds}
            for _, loot in pairs(loots) do
                inst.components.lootdropper:SpawnLootPrefab(loot)
            end
        end
    end
end

local function RememberKnownLocation(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    inst.components.knownlocations:RememberLocation("home", Vector3(x, 20, z), true)
end

local function ShouldSleep(inst)
    return false
end

local function ShouldWake(inst)
    return true
end

local function CanEat(inst)
    if inst.components.timer:TimerExists(EAT_SKILL_NAME) then
        return false
    end
    return true
end

local function Eat(inst, veggie)
    if not inst:CanEat() then
        return
    end

    print("Eating", veggie.prefab)
    if inst.eaten_list == nil then
        inst.eaten_list = {}
    end
    local name = string.gsub(veggie.prefab, "farm_plant_", "")
    name = string.gsub(name, "_oversized", "")
    name = string.gsub(name, "_waxed", "")
    name = string.gsub(name, "_rotten", "")
    table.insert(inst.eaten_list, name)

    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(veggie.Transform:GetWorldPosition())
    fx:SetMaterial("wood")
    veggie:Remove()

    inst.components.timer:StartTimer(EAT_SKILL_NAME, EAT_SKILL_PERIOD)
end

local function IsEating(inst)
    return inst.components.timer:TimerExists(EAT_SKILL_NAME)
end

local assets =
{
    Asset("ANIM", "anim/fruitfly.zip"),
    Asset("ANIM", "anim/fruitfly_evil.zip"),
}

local prefabs =
{
    "fruitflyfruit",
    "fruitfly",
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()
    inst.Transform:SetFourFaced()

    MakeGhostPhysics(inst, 1, 0.5)

    inst.AnimState:SetBank("fruitfly")
    inst.AnimState:SetBuild("fruitfly_evil")
    inst.AnimState:PlayAnimation("idle")

    inst.DynamicShadow:SetSize(1 * 2, 0.375 * 2)

    inst.sounds = sounds

    inst.Transform:SetScale(2, 2, 2)

    inst:AddTag("flying")
    inst:AddTag("ignorewalkableplatformdrowning")
    inst:AddTag("insect")
    inst:AddTag("small")
    inst:AddTag("lordfruitfly")
    inst:AddTag("hostile")
    inst:AddTag("epic")
    inst:AddTag("smallepic")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.eaten_list = {}

    inst:SetStateGraph("SGterror_greedybeetle")
    inst:SetBrain(brain)

    inst:AddComponent("inspectable")

    inst:AddComponent("sleeper")
    inst.components.sleeper:SetResistance(6)

    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = 6
    inst.components.locomotor.pathcaps = {allowocean = true}

    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "fruit2"
    inst.components.combat:SetAttackPeriod(TUNING.LORDFRUITFLY_ATTACK_PERIOD)
    inst.components.combat:SetDefaultDamage(TUNING.LORDFRUITFLY_DAMAGE)
    inst.components.combat:SetRange(TUNING.LORDFRUITFLY_ATTACK_DIST)
    inst.components.combat:SetRetargetFunction(3, RetargetFn)
    inst.components.combat:SetKeepTargetFunction(KeepTargetFn)
    inst.components.combat:SetTarget(nil)

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.LORDFRUITFLY_HEALTH)

    inst:AddComponent("knownlocations")
    inst:DoTaskInTime(0, RememberKnownLocation)

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("terror_greedybeetle")

    inst.components.sleeper:SetSleepTest(ShouldSleep)
    inst.components.sleeper:SetWakeTest(ShouldWake)

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_SMALL

    inst:AddComponent("timer")
    inst.CanEat = CanEat
    inst.Eat = Eat
    inst.IsEating = IsEating

    --divide by scale for accurate walkspeed
    inst.components.locomotor.walkspeed = TUNING.LORDFRUITFLY_WALKSPEED/2

    inst:ListenForEvent("attacked", OnAttacked)
    inst:ListenForEvent("death", OnDead)

    MakeMediumFreezableCharacter(inst, "fruit2")-- inst, symbol
    MakeMediumBurnableCharacter(inst, "fruit2")

    MakeHauntablePanic(inst)

    inst.OnLoad = OnLoad
    inst.OnSave = OnSave

    return inst
end


return Prefab("terror_greedybeetle", fn, assets, prefabs)
local assets =
{
    Asset("ANIM", "anim/ds_spider_basic.zip"),
    Asset("ANIM", "anim/ds_spider_warrior.zip"),
    -- Asset("ANIM", "anim/ds_spider_moon.zip"),
    Asset("ANIM", "anim/spider_white.zip"),
    Asset("ANIM", "anim/ds_spider_parasite_death.zip"),
    Asset("SOUND", "sound/spider.fsb"),
}

local prefabs =
{
    "spidergland",
    "monstermeat",
    "silk",
    "spider_web_spit",
    "spider_web_spit_acidinfused",
    "moonspider_spike",

    "spider_mutate_fx",
    "spider_heal_fx",
    "spider_heal_target_fx",
    "spider_heal_ground_fx"
}
local brain = require "brains/medal_origin_spiderbrain"

local function keeptargetfn(inst, target)
    return target ~= nil
         and target.components.combat ~= nil
         and target.components.health ~= nil
         and not target.components.health:IsDead()
end


-- local TARGET_MUST_TAGS = { "_combat", "character" }
-- local TARGET_CANT_TAGS = { "spiderwhisperer", "spiderdisguise", "INLIMBO", "chaos_creature" }
-- local function FindTarget(inst, radius)
--     if not inst.no_targeting then
--         return FindEntity(
--             inst,
--             SpringCombatMod(radius),
--             function(guy)
--                 return (not inst.bedazzled and (not guy:HasTag("monster") or guy:HasTag("player")))
--                     and inst.components.combat:CanTarget(guy)
--             end,
--             TARGET_MUST_TAGS,
--             TARGET_CANT_TAGS
--         )
--     end
-- end

-- local function WarriorRetarget(inst)
--     return FindTarget(inst, TUNING_MEDAL.MEDAL_ORIGIN_SPIDER_TARGET_DIST)
-- end

local TARGET_MUST_TAGS = { "_combat", "character" }
local TARGET_CANT_TAGS = {"FX", "NOCLICK","INLIMBO","chaos_creature"}
--更换仇恨目标
local function retargetfn(inst)
    local target = inst.components.combat.target--当前攻击目标
	if target ~= nil and target:HasTag("under_origin_tree") then return end--如果当前目标还在本源之树范围内，则保持仇恨
	--优先寻找本源之树范围内离得最近的玩家
    if TheWorld and TheWorld.medal_origin_tree ~= nil and TheWorld.medal_origin_tree.players ~= nil then
        local closest_player = nil
        local distance = math.huge
        for player in pairs(TheWorld.medal_origin_tree.players) do
			if player:IsValid() and inst.components.combat:CanTarget(player) then
                local dist = inst:GetDistanceSqToInst(player)
                if dist < distance then
                    closest_player = player
                    distance = dist
                end
            end
		end
        if closest_player ~= nil then return closest_player,true end
    end
	--真没玩家了就找个别的目标吧
	return FindEntity(inst, TUNING_MEDAL.MEDAL_ORIGIN_SPIDER_TARGET_DIST, function(guy)
        return  inst.components.combat:CanTarget(guy)
    end, TARGET_MUST_TAGS, TARGET_CANT_TAGS)
end

local function OnAttacked(inst, data)
    if inst.no_targeting then
        return
    end

    inst.defensive = false
    inst.components.combat:SetTarget(data.attacker)

    inst.components.combat:ShareTarget(data.attacker, 30, function(dude)
        return dude:HasTag("chaos_creature") and not dude.components.health:IsDead()
    end, 10)
end

--攻击到目标
local function OnHitOther(inst,data)
	if data and data.target then
        data.target:AddMedalDebuff("buff_medal_chaos_erosion")--添加1层混沌侵蚀
    end
end

-- local function CalcSanityAura(inst, observer)
--     if observer:HasTag("spiderwhisperer") or inst.bedazzled then
--         return 0
--     end

--     return inst.components.sanityaura.aura
-- end

local function SetHappyFace(inst, is_happy)
    if is_happy then
        inst.AnimState:OverrideSymbol("face", inst.build, "happy_face")
    else
        inst.AnimState:ClearOverrideSymbol("face")
    end
end

local function SoundPath(inst, event)
    local creature = "spider"
    if inst:HasTag("spider_healer") then
        return "webber1/creatures/spider_cannonfodder/" .. event
    elseif inst:HasTag("spider_moon") then
        return "turnoftides/creatures/together/spider_moon/" .. event
    elseif inst:HasTag("spider_warrior") then
        creature = "spiderwarrior"
    elseif inst:HasTag("spider_hider") or inst:HasTag("spider_spitter") then
        creature = "cavespider"
    else
        creature = "spider"
    end
    return "dontstarve/creatures/" .. creature .. "/" .. event
end

-- local DIET = { FOODTYPE.MEAT }
local BASE_PATHCAPS = { ignorecreep = true }
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    MakeCharacterPhysics(inst, 10, .5)

    inst.DynamicShadow:SetSize(1.5, .5)
    inst.Transform:SetFourFaced()

    inst:AddTag("cavedweller")
    inst:AddTag("monster")
    inst:AddTag("hostile")
    inst:AddTag("scarytoprey")
    -- inst:AddTag("canbetrapped")
    inst:AddTag("smallcreature")
    inst:AddTag("spider")
    inst:AddTag("drop_inventory_onpickup")
    inst:AddTag("drop_inventory_onmurder")
    inst:AddTag("spider_warrior")
    inst:AddTag("chaos_creature")--混沌生物

    -- inst.scrapbook_deps = {"silk","spidergland","monstermeat"}

    --trader (from trader component) added to pristine state for optimization
    -- inst:AddTag("trader")

    inst.AnimState:SetBank("spider")
    inst.AnimState:SetBuild("spider_white")
    inst.AnimState:PlayAnimation("idle")

    MakeFeedableSmallLivestockPristine(inst)

    inst:AddComponent("spawnfader")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    ----------
    -- inst.OnEntitySleep = OnEntitySleep

    -- locomotor must be constructed before the stategraph!
    inst:AddComponent("locomotor")
    inst.components.locomotor:SetSlowMultiplier( 1 )
    inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor.pathcaps = BASE_PATHCAPS
    -- boat hopping setup
    inst.components.locomotor:SetAllowPlatformHopping(true)
    inst.components.locomotor.walkspeed = TUNING_MEDAL.MEDAL_ORIGIN_SPIDER_WALK_SPEED
    inst.components.locomotor.runspeed = TUNING_MEDAL.MEDAL_ORIGIN_SPIDER_RUN_SPEED

    inst:AddComponent("embarker")
    inst:AddComponent("drownable")

    inst:SetStateGraph("SGmedal_origin_spider")

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:AddRandomLoot("monstermeat", 1)
    inst.components.lootdropper:AddRandomLoot("silk", .5)
    inst.components.lootdropper:AddRandomLoot("spidergland", .5)
    inst.components.lootdropper:AddRandomHauntedLoot("spidergland", 1)
    inst.components.lootdropper.numrandomloot = 1

    ---------------------
    -- MakeMediumBurnableCharacter(inst, "body")
    -- MakeMediumFreezableCharacter(inst, "body")
    -- inst.components.burnable.flammability = TUNING.SPIDER_FLAMMABILITY
    ---------------------

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING_MEDAL.MEDAL_ORIGIN_SPIDER_HEALTH)
    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "body"
    inst.components.combat:SetKeepTargetFunction(keeptargetfn)
    -- inst.components.combat:SetOnHit(SummonFriends)
    inst.components.combat:SetDefaultDamage(TUNING_MEDAL.MEDAL_ORIGIN_SPIDER_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING_MEDAL.MEDAL_ORIGIN_SPIDER_ATTACK_PERIOD)
    inst.components.combat:SetRange(TUNING_MEDAL.MEDAL_ORIGIN_SPIDER_ATTACK_RANGE, TUNING_MEDAL.MEDAL_ORIGIN_SPIDER_HIT_RANGE)
    inst.components.combat:SetRetargetFunction(2, retargetfn)

    inst:AddComponent("planarentity")--实体抵抗
    inst.ChaosDeathTimesKey = "medal_origin_tree"--死亡次数以本源之树的为准
    inst:AddComponent("medal_chaosdamage")--混沌伤害
    inst.components.medal_chaosdamage:SetBaseDamage(TUNING_MEDAL.MEDAL_ORIGIN_SPIDER_CHAOS_DAMAGE)

    -- inst:AddComponent("follower")
    --inst.components.follower.maxfollowtime = TUNING.TOTAL_DAY_TIME

    ------------------

    -- inst:AddComponent("sleeper")
    -- inst.components.sleeper.watchlight = true
    -- inst.components.sleeper:SetResistance(2)
    -- inst.components.sleeper:SetSleepTest(ShouldSleep)
    -- inst.components.sleeper:SetWakeTest(ShouldWake)
    ------------------

    inst:AddComponent("knownlocations")

    ------------------

    -- inst:AddComponent("eater")
    -- inst.components.eater:SetDiet(DIET, DIET)
    -- inst.components.eater:SetCanEatHorrible()
    -- inst.components.eater:SetStrongStomach(true) -- can eat monster meat!
    -- inst.components.eater:SetCanEatRawMeat(true)

    ------------------

    inst:AddComponent("inspectable")

    ------------------

    -- inst:AddComponent("inventory")
    -- inst:AddComponent("trader")
    -- inst.components.trader:SetAcceptTest(ShouldAcceptItem)
    -- inst.components.trader:SetAbleToAcceptTest(ShouldAcceptItem)
    -- inst.components.trader.onaccept = OnGetItemFromPlayer
    -- inst.components.trader.onrefuse = OnRefuseItem
    -- inst.components.trader.deleteitemonaccept = false

    ------------------

    -- inst:AddComponent("inventoryitem")
    -- inst.components.inventoryitem.nobounce = true
    -- inst.components.inventoryitem.canbepickedup = false
    -- inst.components.inventoryitem.canbepickedupalive = true
    -- inst.components.inventoryitem:SetSinks(true)

    --------------------

    inst:AddComponent("sanityaura")
    -- inst.components.sanityaura.aurafn = CalcSanityAura
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_MED

    ------------------

    -- inst:AddComponent("acidinfusible")
    -- inst.components.acidinfusible:SetFXLevel(1)
    -- inst.components.acidinfusible:SetMultipliers(TUNING.ACID_INFUSION_MULT.STRONGER)

    ------------------
    -- inst:AddComponent("halloweenmoonmutable")
    -- inst.components.halloweenmoonmutable:SetPrefabMutated("spider_moon")
    -- inst.components.halloweenmoonmutable:SetOnMutateFn(HalloweenMoonMutate)

    inst.recipe = "mutator_dropper"

    -- MakeFeedableSmallLivestock(inst, TUNING.SPIDER_PERISH_TIME)
    MakeHauntablePanic(inst)

    inst:SetBrain(brain)

    inst:ListenForEvent("attacked", OnAttacked)
    inst:ListenForEvent("onhitother", OnHitOther)--攻击到目标

    -- inst:ListenForEvent("startleashing", OnStartLeashing)
    -- inst:ListenForEvent("stopleashing", OnStopLeashing)

    -- inst:ListenForEvent("ontrapped", OnTrapped)
    -- inst:ListenForEvent("oneat", OnEat)

    -- inst:ListenForEvent("ondropped", OnDropped)

    -- inst:ListenForEvent("gotosleep", OnGoToSleep)
    -- inst:ListenForEvent("onwakeup", OnWakeUp)

    -- inst:ListenForEvent("onpickup", OnPickup)

    -- inst:WatchWorldState("iscaveday", OnIsCaveDay)
    -- OnIsCaveDay(inst, TheWorld.state.iscaveday)

    inst.SoundPath = SoundPath

    inst.incineratesound = SoundPath(inst, "die")

    inst.build = "spider_white"
    inst.SetHappyFace = SetHappyFace

    return inst
end

return Prefab("medal_origin_spider", fn, assets, prefabs)
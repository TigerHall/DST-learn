local brain = require "brains/medal_origin_mushgnomebrain"
-- local spore_brain = require "brains/medal_origin_mushgnome_sporebrain"

local assets =
{
    Asset("ANIM", "anim/grotto_mushgnome.zip"),
    Asset("SOUND", "sound/leif.fsb"),
}

local leaf_assets =
{
    Asset("ANIM", "anim/alterguardian_phase3.zip"),
}

local spore_assets =
{
    Asset("ANIM", "anim/spore_moon.zip"),
    Asset("ANIM", "anim/mushroom_spore_moon.zip"),
}

local prefabs =
{
    "character_fire",
    "livinglog",
    "medal_origin_mushgnome_spore",
    "spore_moon_coughout",
    "moon_cap",
}

SetSharedLootTable("medal_origin_mushgnome",
{
    {"livinglog",   1.0},
    {"livinglog",   0.5},
    {"medal_origin_mushgnome_spore",  1.0},
    {"medal_origin_mushgnome_spore",  1.0},
    {"medal_origin_mushgnome_spore",  1.0},
    {"medal_origin_mushgnome_spore",  0.5},
    {"medal_origin_mushgnome_spore",  0.5},
    {"moon_cap",   1.0},
    {"moon_cap",   1.0},
})

------------------------------------------------------地精------------------------------------------------------

-- local function onloadfn(inst, data)
--     if data ~= nil then
--         if data.hibernate then
--             inst.components.sleeper.hibernate = true
--         end
--         if data.sleep_time ~= nil then
--             inst.components.sleeper.testtime = data.sleep_time
--         end
--         if data.sleeping then
--             inst.components.sleeper:GoToSleep()
--         end
--     end
-- end

-- local function onsavefn(inst, data)
--     if inst.components.sleeper:IsAsleep() then
--         data.sleeping = true
--         data.sleep_time = inst.components.sleeper.testtime
--     end

--     if inst.components.sleeper:IsHibernating() then
--         data.hibernate = true
--     end
-- end

-- local function OnBurnt(inst)
--     if inst.components.propagator and inst.components.health and not inst.components.health:IsDead() then
--         inst.components.propagator.acceptsheat = true
--     end
-- end
--孢子生成回调
local function onspawnfn(inst, spawn)
    inst.SoundEmitter:PlaySound("dontstarve/cave/mushtree_tall_spore_fart")

    local pos = inst:GetPosition()

    local offset = FindWalkableOffset(
        pos,
        math.random() * TWOPI,
        spawn:GetPhysicsRadius(0) + inst:GetPhysicsRadius(0),
        8
    )
    local off_x = (offset and offset.x) or 0
    local off_z = (offset and offset.z) or 0
    spawn.Transform:SetPosition(pos.x + off_x, 0, pos.z + off_z)
    if inst.components.combat then
        spawn.followtarget = inst.components.combat.target--绑定追踪目标
    end
end
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
	local dist = TUNING_MEDAL.MEDAL_ORIGIN_MUSHGNOME_ATTACK_RANGE
    local notags = {"FX", "NOCLICK","INLIMBO", "wall", "structure", "aquatic","chaos_creature"}
    return FindEntity(inst, dist, function(guy)
        return  inst.components.combat:CanTarget(guy)
    end, nil, notags)
end
local function keeptargetfn(inst, target)
    return target ~= nil
         and target.components.combat ~= nil
         and not IsEntityDeadOrGhost(target)
end
--挨打
local function OnAttacked(inst, data)
    inst.components.combat:SetTarget(data.attacker)
end
--释放叶片攻击
local function DoLeafAttack(inst,doattack)
    --生成攻击特效,如果已经有了那就通过Show/Hide来控制显示或隐藏就行了
    if inst._leaf_fx == nil or not inst._leaf_fx:IsValid() then
        if doattack then
            inst._leaf_fx = SpawnPrefab("medal_origin_mushgnome_leaf_fx")
            inst._leaf_fx.entity:SetParent(inst.entity)
        end
    else
        if doattack then
            inst._leaf_fx:Show()
        else
            inst._leaf_fx:Hide()
        end
    end
end

--移除
local function OnRemoved(inst)
    --移除攻击特效
	if inst._leaf_fx ~= nil and inst._leaf_fx:IsValid() then
        inst._leaf_fx:Remove()
        inst._leaf_fx = nil
    end
end

local COLOUR_R, COLOUR_G, COLOUR_B = 227/255, 227/255, 227/255
local function normal_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    MakeCharacterPhysics(inst, 1000, .5)

    inst.DynamicShadow:SetSize(4, 1.5)

    inst.Transform:SetFourFaced()

    inst.Light:SetColour(COLOUR_R, COLOUR_G, COLOUR_B)
    inst.Light:SetIntensity(0.75)
    inst.Light:SetFalloff(0.5)
    inst.Light:SetRadius(0.6)

    inst:AddTag("moon_spore_protection")
    inst:AddTag("leif")
    inst:AddTag("monster")
    inst:AddTag("tree")
    inst:AddTag("lunar_aligned")
    inst:AddTag("chaos_creature")--混沌生物

    inst.AnimState:SetBank("grotto_mushgnome")
    inst.AnimState:SetBuild("grotto_mushgnome")
    inst.AnimState:PlayAnimation("idle_loop", true)
    inst.scrapbook_anim = "idle_loop"

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst.scrapbook_damage = 0

    local color = .5 + math.random() * .5
    inst.AnimState:SetMultColour(color, color, color, 1)

    ------------------------------------------

    -- inst.OnLoad = onloadfn
    -- inst.OnSave = onsavefn

    ------------------------------------------

    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = TUNING_MEDAL.MEDAL_ORIGIN_MUSHGNOME_WALK_SPEED

    inst:AddComponent("drownable")

    ------------------------------------------
    inst:SetStateGraph("SGmedal_origin_mushgnome")

    ------------------------------------------

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_MED

    -- MakeMediumBurnableCharacter(inst, "body")
    -- inst.components.burnable.flammability = TUNING.LEIF_FLAMMABILITY
    -- inst.components.burnable:SetOnBurntFn(OnBurnt)
    -- inst.components.propagator.acceptsheat = true

    -- MakeMediumFreezableCharacter(inst, "body")

    ------------------
    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING_MEDAL.MEDAL_ORIGIN_MUSHGNOME_HEALTH)

    ------------------

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING_MEDAL.MEDAL_ORIGIN_MUSHGNOME_DAMAGE)
    inst.components.combat.playerdamagepercent = .5--对玩家伤害为默认伤害的一半
    inst.components.combat:SetKeepTargetFunction(keeptargetfn)
    inst.components.combat:SetRetargetFunction(3, retargetfn)
    inst.components.combat:SetAttackPeriod(TUNING_MEDAL.MEDAL_ORIGIN_MUSHGNOME_ATTACK_PERIOD)
    inst.components.combat.hiteffectsymbol = "body"
    inst.components.combat:SetRange(TUNING_MEDAL.MEDAL_ORIGIN_MUSHGNOME_ATTACK_RANGE)

    inst:AddComponent("planarentity")--实体抵抗
    inst.ChaosDeathTimesKey = "medal_origin_tree"--死亡次数以本源之树的为准
    inst:AddComponent("medal_chaosdamage")--混沌伤害
    inst.components.medal_chaosdamage:SetBaseDamage(TUNING_MEDAL.MEDAL_ORIGIN_MUSHGNOME_CHAOS_DAMAGE)

    ------------------------------------------
    MakeHauntableIgnite(inst)
    ------------------------------------------

    -- inst:AddComponent("sleeper")
    -- inst.components.sleeper:SetResistance(3)

    ------------------------------------------

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("medal_origin_mushgnome")

    ------------------------------------------

    inst:AddComponent("inspectable")
    inst:AddComponent("knownlocations")

    ------------------------------------------

    inst:AddComponent("periodicspawner")
    inst.components.periodicspawner:SetPrefab("medal_origin_mushgnome_spore")
    inst.components.periodicspawner:SetOnSpawnFn(onspawnfn)
    inst.components.periodicspawner:SetDensityInRange(TUNING_MEDAL.MEDAL_ORIGIN_MUSHGNOME_SPORE_MAX_DENSITY_RAD, TUNING_MEDAL.MEDAL_ORIGIN_MUSHGNOME_SPORE_MAX_DENSITY)
    inst.components.periodicspawner:SetRandomTimes(TUNING_MEDAL.MEDAL_ORIGIN_MUSHGNOME_SPORESPAWN_MIN, TUNING_MEDAL.MEDAL_ORIGIN_MUSHGNOME_SPORESPAWN_MAX)
    inst.components.periodicspawner:Start()

    ------------------------------------------

    inst:SetBrain(brain)

    inst:ListenForEvent("attacked", OnAttacked)
    inst:ListenForEvent("onremove", OnRemoved)

    inst.DoLeafAttack = DoLeafAttack

    return inst
end

------------------------------------------------------孢子------------------------------------------------------
--停止行动
local function stop_testing(inst)
    if inst._prox_task ~= nil then
        inst._prox_task:Cancel()
        inst._prox_task = nil
    end
    if inst.components.locomotor then
        inst.components.locomotor:Stop()
    end
end
--腐烂了(保鲜值归零)
local function depleted(inst)
    if inst:IsInLimbo() then
        inst:Remove()
    else
        stop_testing(inst)

        inst:AddTag("NOCLICK")
        inst.persists = false

        inst.components.workable:SetWorkable(false)
        inst:PushEvent("pop")

        inst:RemoveTag("medal_spore")--耐久为0了就不用标签来判断是否拥挤了,反正马上爆炸了

        --如果在屏幕外的话加载不到sg,所以需要定时清理掉
        inst:DoTaskInTime(3, inst.Remove)
    end
end
--捕捉时马上爆炸
local function onworked(inst, worker)
    inst:PushEvent("pop")
    inst:RemoveTag("medal_spore")
end

--定期检测当前周围是不是有太多“同孢”了，有的话就直接爆炸
local SPORE_TAGS = {"medal_spore"}
local function checkforcrowding(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local spores = TheSim:FindEntities(x,y,z, TUNING_MEDAL.MEDAL_ORIGIN_MUSHGNOME_SPORE_MAX_DENSITY_RAD, SPORE_TAGS)
    if #spores > TUNING_MEDAL.MEDAL_ORIGIN_MUSHGNOME_SPORE_MAX_DENSITY then
        inst.components.perishable:SetPercent(0)
    else
        inst.crowdingtask = inst:DoTaskInTime(TUNING_MEDAL.MEDAL_ORIGIN_MUSHGNOME_SPORE_DENSITY_CHECK_TIME + math.random()*TUNING_MEDAL.MEDAL_ORIGIN_MUSHGNOME_SPORE_DENSITY_CHECK_VAR, checkforcrowding)
    end
end

local AREAATTACK_EXCLUDETAGS = { "spore", "medal_spore", "INLIMBO", "notarget", "noattack", "flight", "invisible", "playerghost", "shadow", "brightmare", "moon_spore_protection", "chaos_creature"}
--爆炸
local function onpopped(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/balloon_pop")
    inst.components.combat:DoAreaAttack(inst, TUNING_MEDAL.MEDAL_ORIGIN_MUSHGNOME_SPORE_ATTACK_RANGE, nil, nil, nil, AREAATTACK_EXCLUDETAGS)
end

--加载
local function onload(inst)
    inst.Light:Enable(true)--开灯
    inst.DynamicShadow:Enable(true)
end

local PROXIMITY_MUSTHAVE = { "_combat" }
local PROXIMITY_ONEOF = { "player", "monster", "character" }
--定期检测与目标距离
local function do_proximity_test(inst)
    if inst.sg:HasStateTag("busy") then
        return
    end
    --确保当前有追踪目标，且还活着，且不能距离过远；否则重新在附近找个新目标
    if inst.followtarget == nil or not inst.followtarget:IsValid() or IsEntityDeadOrGhost(inst.followtarget) or not inst:IsNear(inst.followtarget,15) then
        inst.followtarget = FindEntity(inst, 15, nil, PROXIMITY_MUSTHAVE, AREAATTACK_EXCLUDETAGS, PROXIMITY_ONEOF)
    end
    
    if inst.followtarget ~= nil then
        --距离足够近了,爆炸
        if inst:IsNear(inst.followtarget,TUNING_MEDAL.MEDAL_ORIGIN_MUSHGNOME_SPORE_ATTACK_PROXIMITY) then
            stop_testing(inst)
            --是玩家的话会有前摇给玩家反应时间,非玩家则直接爆了
            inst:PushEvent(inst.followtarget:HasTag("player") and "preparedpop" or "pop")
        --不够近并且当前没在动，那就动起来
        elseif inst.components.locomotor and not inst.components.locomotor:WantsToMoveForward() then
            inst.components.locomotor:GoToEntity(inst.followtarget)
        end
    end
end
--离开加载范围
local function spore_entity_sleep(inst)
    do_proximity_test(inst)
    stop_testing(inst)
end
--开始做定时任务
local PROXIMITY_TEST_TIME = 15 * FRAMES
local function schedule_testing(inst)
    stop_testing(inst)
    inst._prox_task = inst:DoPeriodicTask(PROXIMITY_TEST_TIME, do_proximity_test)
end
--进入加载范围
local function spore_entity_wake(inst)
    schedule_testing(inst)
    do_proximity_test(inst)
end

local COLOUR_R, COLOUR_G, COLOUR_B = 227/255, 227/255, 227/255
local ZERO_VEC = Vector3(0,0,0)
local function spore_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    MakeCharacterPhysics(inst, 1, .5)

    inst.AnimState:SetBuild("mushroom_spore_moon")
    inst.AnimState:SetBank("spore_moon")
    inst.AnimState:PlayAnimation("idle_flight_loop", true)

    inst.DynamicShadow:Enable(false)

    inst.Light:SetColour(COLOUR_R, COLOUR_G, COLOUR_B)
    inst.Light:SetIntensity(0.5)
    inst.Light:SetFalloff(0.75)
    inst.Light:SetRadius(0.5)
    inst.Light:Enable(false)

    inst.DynamicShadow:SetSize(.8, .5)

    inst:AddTag("medal_spore")--仅用于判断周围是否有太多“同孢”

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst.scrapbook_anim = "idle_flight_loop"
    inst.scrapbook_animoffsety = 65
    inst.scrapbook_animpercent = 0.36

    inst:AddComponent("inspectable")
    -- inst:AddComponent("knownlocations")

    inst:AddComponent("locomotor")
    inst.components.locomotor:EnableGroundSpeedMultiplier(false)
    inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor.walkspeed = 10

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.NET)
    inst.components.workable:SetWorkLeft(1)
    inst.components.workable:SetOnFinishCallback(onworked)

    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(TUNING_MEDAL.MEDAL_ORIGIN_MUSHGNOME_SPORE_PERISH_TIME)
    inst.components.perishable:StartPerishing()
    inst.components.perishable:SetOnPerishFn(depleted)

    inst:AddComponent("stackable")

    -- inst:AddComponent("burnable")
    -- inst.components.burnable:SetFXLevel(1)
    -- inst.components.burnable:SetBurnTime(1)
    -- inst.components.burnable:AddBurnFX("fire", ZERO_VEC, "spore_body")
    -- inst.components.burnable:SetOnIgniteFn(DefaultBurnFn)
    -- inst.components.burnable:SetOnBurntFn(DefaultBurntFn)
    -- inst.components.burnable:SetOnExtinguishFn(DefaultExtinguishFn)

    -- inst:AddComponent("propagator")
    -- inst.components.propagator.acceptsheat = true
    -- inst.components.propagator:SetOnFlashPoint(DefaultIgniteFn)
    -- inst.components.propagator.flashpoint = 1
    -- inst.components.propagator.decayrate = 0.5
    -- inst.components.propagator.damages = false

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING_MEDAL.MEDAL_ORIGIN_MUSHGNOME_SPORE_DAMAGE)
    inst:AddComponent("medal_chaosdamage")--混沌伤害
    inst.components.medal_chaosdamage:SetBaseDamage(TUNING_MEDAL.MEDAL_ORIGIN_MUSHGNOME_SPORE_CHAOS_DAMAGE)

    MakeHauntablePerish(inst, .5)

    inst:ListenForEvent("popped", onpopped)

    inst:SetStateGraph("SGmedal_origin_mushgnome_spore")
    -- inst:SetBrain(spore_brain)

    --第一次检测会快一点
    inst.crowdingtask = inst:DoTaskInTime(1 + math.random()*TUNING_MEDAL.MEDAL_ORIGIN_MUSHGNOME_SPORE_DENSITY_CHECK_VAR, checkforcrowding)

    inst.OnLoad = onload
    inst.OnEntitySleep = spore_entity_sleep
    inst.OnEntityWake = spore_entity_wake

    inst:DoTaskInTime(0, schedule_testing)

    return inst
end

------------------------------------------------------叶片------------------------------------------------------

--叶片
local function leaf_fx_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst:AddTag("CLASSIFIED")
    inst:AddTag("DECOR")
    inst:AddTag("NOCLICK")

    inst.AnimState:SetBank("alterguardian_phase3")
    inst.AnimState:SetBuild("alterguardian_phase3")
    inst.AnimState:PlayAnimation("attk_stab2_loop",true)
    inst.AnimState:SetScale(.5, .5)
    inst.AnimState:HideSymbol("p3_moon_base")
    inst.AnimState:HideSymbol("p3_moon_arms")
    inst.AnimState:HideSymbol("p3_fx_ball_centre")
    inst.AnimState:HideSymbol("p3_fx_top_loop")
    inst.AnimState:HideSymbol("p3_eye_fx")
    inst.AnimState:HideSymbol("p3_fx_puff")

    -- inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    -- inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    return inst
end

return Prefab("medal_origin_mushgnome", normal_fn, assets, prefabs),
    Prefab("medal_origin_mushgnome_spore", spore_fn, spore_assets),
    Prefab("medal_origin_mushgnome_leaf_fx", leaf_fx_fn, leaf_assets)

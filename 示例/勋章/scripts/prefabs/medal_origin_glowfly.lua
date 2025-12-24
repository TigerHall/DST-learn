local assets =
{
    Asset("ANIM", "anim/medal_origin_glowfly.zip"),
}

local prefabs =
{
    "medal_weed_seeds",
    "seeds",
}

local brain = require("brains/medal_origin_glowflybrain")

local sounds =
{
	takeoff = "dontstarve/creatures/mosquito/mosquito_takeoff",
	attack = "dontstarve/creatures/mosquito/mosquito_attack",
	explode = "dontstarve/creatures/mosquito/mosquito_explo",
    -- hit = "dontstarve_DLC003/creatures/glowfly/hit",--哈姆雷特的资源,暂时屏蔽,后续挪了再用
	-- death = "dontstarve_DLC003/creatures/glowfly/death",--哈姆雷特的资源,暂时屏蔽,后续挪了再用
    hit = "dontstarve/creatures/mosquito/mosquito_hurt",
    death = "dontstarve/creatures/mosquito/mosquito_death",
}

SetSharedLootTable( 'medal_origin_glowfly',
{
    {'medal_weed_seeds', 0.1},--杂草种子
    {'seeds', 0.2},--种子
})

-- local function OnLoad(inst, data)
--     if data then
--         inst.pollination_times = data.pollination_times
--     end
-- end

local function OnSave(inst, data)
    -- data.pollination_times = inst.pollination_times
    data.is_origin_insect = inst.is_origin_insect
end

--后加载
local function OnLoadPostPass(inst, newents, data)
    if data ~= nil and data.is_origin_insect ~= nil then
        if TheWorld and TheWorld.medal_origin_tree ~= nil and TheWorld.medal_origin_tree.RegisterOriginInsect ~= nil then
            TheWorld.medal_origin_tree:RegisterOriginInsect(inst)--加入本源之树列表
        end
    end
end

--挨揍
local function OnAttacked(inst, data)
    local attacker = data ~= nil and data.attacker or nil
    if attacker == nil then return end
    inst.components.combat:SetTarget(attacker)
    --把仇恨共享给其他本源昆虫
    inst.components.combat:ShareTarget(data.attacker, 30, 
		function(dude)
			return dude:HasTag("medal_insect")
				and not dude.components.health:IsDead()
		end, 10)
end

--设置化茧时间
local function SetCocoonTime(inst,time)
    if inst.components.timer then
        local phase = TheWorld and TheWorld.medal_origin_tree and TheWorld.medal_origin_tree.phase or 1
        time = time or TUNING_MEDAL.MEDAL_ORIGIN_GLOWFLY_COCOON_TIME[phase]
        --已经有计时器了则修改时间
        if inst.components.timer:TimerExists("wantstococoon") then
            inst.components.timer:SetTimeLeft("wantstococoon", time)
        else--没计时器则开始新的
            inst.components.timer:StartTimer("wantstococoon", time)
        end
    end
end

--化茧
local function ChangeToCocoon(inst)                        
    local cocoon = SpawnPrefab("medal_origin_cocoon")
    if cocoon ~= nil then
        cocoon.Transform:SetPosition(inst.Transform:GetWorldPosition())
        cocoon.sg:GoToState("cocoon_pre") 
    end
    inst:Remove()
end

--捕捉(概率成功)
local function onworked(inst, worker, workleft)
    if workleft and workleft>0 then
        if math.random() < (TUNING_MEDAL.MEDAL_ORIGIN_GLOWFLY_WORKLEFT-workleft)/TUNING_MEDAL.MEDAL_ORIGIN_GLOWFLY_WORKLEFT then
            inst.components.workable.workleft=0
        end
    end
end
--成功捕捉
local function onfinished(inst, worker)
    if worker and worker.components.inventory ~= nil and inst.components.lootdropper then
        local prefabs = inst.components.lootdropper:GenerateLoot()
        for k, v in pairs(prefabs) do
            local item = SpawnPrefab(v)
            if item then
                worker.components.inventory:GiveItem(item, nil, inst:GetPosition())
            end
        end
        -- worker.SoundEmitter:PlaySound("dontstarve/common/butterfly_trap")
        inst:Remove()
    end
end

--孵化
local function OnHaunt(inst, haunter)
	inst:PushEvent("hatch")--孵化
    return true
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()
    inst.Transform:SetSixFaced()

    -- MakeGhostPhysics(inst, 1, 0.5)
    MakeTinyFlyingCharacterPhysics(inst, 1, .5)

    inst.DynamicShadow:SetSize(.8, .5)

    inst.sounds = sounds

    inst.AnimState:SetBank("lantern_fly")
    inst.AnimState:SetBuild("lantern_fly")
    inst.AnimState:PlayAnimation("idle")

    inst.Transform:SetScale(0.6, 0.6, 0.6)

    inst:AddTag("flying")
    inst:AddTag("ignorewalkableplatformdrowning")
    inst:AddTag("insect")
    inst:AddTag("smallcreature")
    -- inst:AddTag("glowfly")
    inst:AddTag("hostile")
    inst:AddTag("chaos_creature")--混沌生物

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    -- inst.pollination_times = 0--授粉次数

    inst:AddComponent("inspectable")

    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = TUNING_MEDAL.MEDAL_ORIGIN_GLOWFLY_WALKSPEED
    inst.components.locomotor.pathcaps = {allowocean = true}

    inst:AddComponent("follower")

    inst:AddComponent("timer")--定时器
    SetCocoonTime(inst)--存活一定时间后结茧

    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "body"
    -- inst.components.combat.battlecryenabled = false
    -- inst.components.combat:SetAttackPeriod(TUNING_MEDAL.MEDAL_ORIGIN_FRUITFLY_ATTACK_PERIOD)
    -- inst.components.combat:SetDefaultDamage(TUNING_MEDAL.MEDAL_ORIGIN_FRUITFLY_DAMAGE)
    -- inst.components.combat:SetRange(TUNING_MEDAL.MEDAL_ORIGIN_FRUITFLY_ATTACK_DIST)
    -- inst.components.combat:SetRetargetFunction(3, RetargetFn)
    -- inst.components.combat:SetKeepTargetFunction(ShouldKeepTarget)

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING_MEDAL.MEDAL_ORIGIN_GLOWFLY_HEALTH)

    inst:AddComponent("planarentity")--实体抵抗
    inst.ChaosDeathTimesKey = "medal_origin_tree"--死亡次数以本源之树的为准
    -- inst:AddComponent("medal_chaosdamage")--混沌伤害
    -- inst.components.medal_chaosdamage:SetBaseDamage(TUNING_MEDAL.MEDAL_ORIGIN_FRUITFLY_CHAOS_DAMAGE)

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable('medal_origin_glowfly')

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.NET)
    inst.components.workable:SetWorkLeft(TUNING_MEDAL.MEDAL_ORIGIN_GLOWFLY_WORKLEFT)--捕捉次数
    inst.components.workable:SetOnWorkCallback(onworked)
    inst.components.workable:SetOnFinishCallback(onfinished)

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_MED

    inst:AddComponent("knownlocations")--记录坐标点组件

    inst:SetBrain(brain)
    inst:SetStateGraph("SGmedal_origin_glowfly")

    inst:ListenForEvent("attacked", OnAttacked)--被攻击

    -- inst.CanTargetAndAttack = CanTargetAndAttack
    inst.SetCocoonTime = SetCocoonTime
    inst.ChangeToCocoon = ChangeToCocoon

    MakeHauntablePanic(inst)

    -- inst.OnLoad = OnLoad
    inst.OnSave = OnSave
    inst.OnLoadPostPass = OnLoadPostPass

    return inst
end

local function cocoonfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    -- inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()
    inst.Transform:SetSixFaced()

    -- MakeGhostPhysics(inst, 1, 0.5)
    MakeTinyFlyingCharacterPhysics(inst, 1, .5)

    -- inst.DynamicShadow:SetSize(.8, .5)

    inst.sounds = sounds

    inst.AnimState:SetBank("lantern_fly")
    inst.AnimState:SetBuild("lantern_fly")
	inst.AnimState:PlayAnimation("idle")
	-- inst.AnimState:PushAnimation("cocoon_idle_loop")	

    inst.Transform:SetScale(0.6, 0.6, 0.6)

    inst:AddTag("flying")
    inst:AddTag("ignorewalkableplatformdrowning")
    inst:AddTag("insect")
    inst:AddTag("smallcreature")
    inst:AddTag("cocoon")
    inst:AddTag("hostile")
    inst:AddTag("chaos_creature")--混沌生物

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    -- inst.pollination_times = 0--授粉次数

    inst:AddComponent("inspectable")

    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "body"

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING_MEDAL.MEDAL_ORIGIN_GLOWFLY_HEALTH)

    -- inst:AddComponent("planarentity")--实体抵抗
    -- inst.ChaosDeathTimesKey = "medal_origin_tree"--死亡次数以本源之树的为准

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable('medal_origin_glowfly')

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_MED

    inst:SetStateGraph("SGmedal_origin_glowfly")

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetOnHauntFn(OnHaunt)

    inst.hatchtask = inst:DoTaskInTime(math.random(TUNING_MEDAL.MEDAL_ORIGIN_COCOON_HATCH_TIME_MIN,TUNING_MEDAL.MEDAL_ORIGIN_COCOON_HATCH_TIME_MAX),function(inst) 
        inst:PushEvent("hatch")--孵化
    end)

    -- inst.OnLoad = OnLoad
    -- inst.OnSave = OnSave
    -- inst.OnLoadPostPass = OnLoadPostPass

    return inst
end

return Prefab("medal_origin_glowfly", fn, assets, prefabs),
        Prefab("medal_origin_cocoon", cocoonfn, assets, prefabs)
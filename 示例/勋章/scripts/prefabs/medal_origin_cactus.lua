local brain = require "brains/medal_origin_cactusbrain"

local RETARGET_CANT_TAGS = { "chaos_creature"}--不会被攻击的目标()

local assets =
{
	Asset("ANIM", "anim/medal_origin_cactus.zip"),
	-- Asset("MINIMAP_IMAGE", "cactus_volcano"),
}

local prefabs = 
{
	-- "needle_dart",
	-- "blowdart_pipe",
	-- "needlespear",
	"twigs",
}

SetSharedLootTable( 'medal_origin_cactus',
{
    {'twigs', 1},--树枝
    {'twigs', 1},--树枝
})
---------------------------------仙人掌-----------------------------------
--重选目标
local function retargetfn(inst)
	local newtarget = FindEntity(inst, TUNING_MEDAL.MEDAL_ORIGIN_CACTUS_RANGE, function(guy)
			return guy.components.health and not IsEntityDeadOrGhost(guy)
	end, nil, {"chaos_creature", "FX", "NOCLICK"})

	return newtarget
end
--保持目标
local function shouldKeepTarget(inst, target)
	if target and target:IsValid() and
		(target.components.health and not IsEntityDeadOrGhost(target)) then
		local distsq = target:GetDistanceSqToInst(inst)
		return distsq < TUNING_MEDAL.MEDAL_ORIGIN_CACTUS_RANGE*TUNING_MEDAL.MEDAL_ORIGIN_CACTUS_RANGE
	else
		return false
	end
end
--长刺
local function ontimerdone(inst, data)
	if data.name == "SPIKE" then
		inst.has_spike = true
		inst:PushEvent("growspike")
	end
end
--反伤
local function OnBlocked(owner, data) 
	if      (data.weapon == nil or (not data.weapon:HasTag("projectile") and not data.weapon.projectile))
		and data.attacker and data.attacker.components.combat and data.stimuli ~= "thorns" and not data.attacker:HasTag("thorny")
		and ((data.damage and data.damage > 0) or (data.attacker.components.combat and data.attacker.components.combat.defaultdamage > 0)) then
		data.attacker.components.combat:GetAttacked(owner, TUNING_MEDAL.MEDAL_ORIGIN_CACTUS_REBOUND_DAMAGE, nil, "thorns")
		-- owner.SoundEmitter:PlaySound("dontstarve_DLC002/common/armour/cactus")
	end
end
--变成根
local function ChangeToStump(inst)
	local stump = SpawnPrefab("medal_origin_cactus_stump")
	if stump then 
		stump.Transform:SetPosition(inst.Transform:GetWorldPosition())
		if inst.origin_plant_idx ~= nil and TheWorld and TheWorld.medal_origin_tree ~= nil and TheWorld.medal_origin_tree.UpdateOriginPlant ~= nil then
            TheWorld.medal_origin_tree:UpdateOriginPlant(inst,stump)--更新本源之树绑定的目标
        end
	end
	inst:Remove()
end

--授粉
local function DoOriginPollination(inst)
    inst.pollination_times = (inst.pollination_times or 0) + 1--授粉次数+1
	--授粉次数达到上限，变成本源守卫
	if inst.pollination_times >= 4 then
		local guard = SpawnPrefab("medal_origin_tree_guard")
		if guard ~= nil then
			guard.Transform:SetPosition(inst.Transform:GetWorldPosition())
			if guard.playSpawnAnimation ~= nil then
				guard:playSpawnAnimation()
			end

			if inst.origin_plant_idx ~= nil and TheWorld and TheWorld.medal_origin_tree ~= nil and TheWorld.medal_origin_tree.UpdateOriginPlant ~= nil then
				TheWorld.medal_origin_tree:UpdateOriginPlant(inst,guard)--更新本源之树绑定的目标
			end
			
			inst:Remove()
		end
	end
end

--播放生成动画
local function playSpawnAnimation(inst)
	inst.AnimState:PlayAnimation("regrow")
	inst.AnimState:PushAnimation("idle_spike")
end

---------------------------------根-----------------------------------
--挖掘
local function dig_up(inst, chopper)
	inst.components.lootdropper:SpawnLootPrefab("twigs")
	inst.components.lootdropper:SpawnLootPrefab("twigs")
	
	inst:Remove()
end
--催熟
local function DoOriginGrowth(inst)
    local cactus = SpawnPrefab("medal_origin_cactus")
    if cactus ~= nil then
        cactus.Transform:SetPosition(inst.Transform:GetWorldPosition())
        if inst.origin_plant_idx ~= nil and TheWorld and TheWorld.medal_origin_tree ~= nil and TheWorld.medal_origin_tree.UpdateOriginPlant ~= nil then
            TheWorld.medal_origin_tree:UpdateOriginPlant(inst,cactus)--更新本源之树绑定的目标
        end
		if cactus.playSpawnAnimation ~= nil then
			cactus:playSpawnAnimation()
		end
        inst:Remove()
    end
    return true
end
--授粉
local function DoOriginPollination_S(inst)
    DoOriginGrowth(inst)--直接催熟
end

---------------------------------共用-----------------------------------
--保存
local function onsave(inst, data)
	data.has_spike = inst.has_spike
	data.origin_plant_idx = inst.origin_plant_idx
	if inst.pollination_times then
		data.pollination_times = inst.pollination_times
	end
end
--加载
local function onload(inst, data)
	inst.has_spike = data.has_spike
	inst.pollination_times = data.pollination_times
end
--后加载
local function OnLoadPostPass(inst, newents, data)
    if data ~= nil and data.origin_plant_idx ~= nil then
        if TheWorld and TheWorld.medal_origin_tree ~= nil and TheWorld.medal_origin_tree.AddOriginPlant ~= nil then
            TheWorld.medal_origin_tree:AddOriginPlant(inst,data.origin_plant_idx)--加入本源之树列表
        end
    end
end
--移除
local function OnRemoveEntity(inst)
    if inst.origin_plant_idx ~= nil and TheWorld and TheWorld.medal_origin_tree ~= nil and TheWorld.medal_origin_tree.RemoveOriginPlant ~= nil then
        TheWorld.medal_origin_tree:RemoveOriginPlant(inst)--从本源之树植物列表中移除
    end
end


local function fn()
	local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
	-- inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 1)

    -- inst.MiniMapEntity:SetIcon("medal_origin_cactus.tex")

    inst.AnimState:SetBank("cactus_volcano")
    inst.AnimState:SetBuild("cactus_volcano")
	inst.AnimState:PlayAnimation("idle_spike")
	inst.AnimState:SetTime(math.random()*2)

	inst:AddTag("thorny")
	inst:AddTag("chaos_creature")--混沌生物
	inst:AddTag("origin_flower")--本源之花(可生成昆虫)
    inst:AddTag("origin_pollinationable")--可授粉
	-- inst:AddTag("elephantcactus")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	inst.origin_chop_absorb = TUNING_MEDAL.MEDAL_ORIGIN_CACTUS_CHOP_ABSORB--给本源之树减伤

	inst:AddComponent("inspectable")
	
	MakeLargeFreezableCharacter(inst)

	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetChanceLootTable('medal_origin_cactus')

	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(TUNING_MEDAL.MEDAL_ORIGIN_CACTUS_HEALTH)

	inst:AddComponent("combat")
	inst.components.combat:SetRange(TUNING_MEDAL.MEDAL_ORIGIN_CACTUS_RANGE)
	inst.components.combat:SetDefaultDamage(TUNING_MEDAL.MEDAL_ORIGIN_CACTUS_DAMAGE)
	inst.components.combat:SetAreaDamage(TUNING_MEDAL.MEDAL_ORIGIN_CACTUS_RANGE, 1)
	inst.components.combat:SetAttackPeriod(1)
	inst.components.combat:SetRetargetFunction(1, retargetfn)
	inst.components.combat:SetKeepTargetFunction(shouldKeepTarget)
	inst.components.combat:SetNoAggroTags(RETARGET_CANT_TAGS)
	-- inst.components.combat:SetHurtSound("dontstarve_DLC002/creatures/volcano_cactus/hit")

	inst:AddComponent("planarentity")--实体抵抗
    inst.ChaosDeathTimesKey = "medal_origin_tree"--死亡次数以本源之树的为准
	inst:AddComponent("medal_chaosdamage")--混沌伤害
	inst.components.medal_chaosdamage:SetBaseDamage(TUNING_MEDAL.MEDAL_ORIGIN_CACTUS_CHAOS_DAMAGE)

	inst:AddComponent("timer")
	inst:ListenForEvent("timerdone", ontimerdone)

	inst:ListenForEvent("blocked", OnBlocked)
	inst:ListenForEvent("attacked", OnBlocked)

	inst.has_spike = true

	inst:SetBrain(brain)
	inst:SetStateGraph("SGmedal_origin_cactus")
	inst.sg:GoToState("grow_spike")

	inst.OnLoad = onload
	inst.OnSave = onsave
    inst.OnLoadPostPass = OnLoadPostPass
    -- inst.DoOriginGrowth = DoOriginGrowth--催熟
	inst.DoOriginPollination = DoOriginPollination--授粉
	inst.playSpawnAnimation = playSpawnAnimation--播放成长动画
	inst.ChangeToStump = ChangeToStump
    inst.OnRemoveEntity = OnRemoveEntity

	return inst
end

local function stumpfn(Sim)
	local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
	-- inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    -- inst.MiniMapEntity:SetIcon("medal_origin_cactus.tex")

    inst.AnimState:SetBank("cactus_volcano")
    inst.AnimState:SetBuild("cactus_volcano")
	inst.AnimState:PlayAnimation("idle_underground")

    inst:AddTag("origin_pollinationable")--可授粉

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	inst.origin_chop_absorb = TUNING_MEDAL.MEDAL_ORIGIN_CACTUS_STUMP_CHOP_ABSORB--给本源之树减伤
	
	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.DIG)
    inst.components.workable:SetWorkLeft(TUNING_MEDAL.MEDAL_ORIGIN_CACTUS_STUMP_WORKLEFT)--需要挖十下
	inst.components.workable:SetOnFinishCallback(dig_up)
	
	inst:AddComponent("inspectable")

	inst:AddComponent("lootdropper")

	inst.OnSave = onsave
    inst.OnLoadPostPass = OnLoadPostPass
    inst.DoOriginGrowth = DoOriginGrowth--催熟
	inst.DoOriginPollination = DoOriginPollination_S--授粉
    inst.OnRemoveEntity = OnRemoveEntity

	return inst
end

return Prefab("medal_origin_cactus", fn, assets, prefabs),
	   Prefab("medal_origin_cactus_stump", stumpfn, assets, prefabs)

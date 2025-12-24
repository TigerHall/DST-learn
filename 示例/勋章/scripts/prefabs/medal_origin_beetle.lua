local assets =
{
    Asset("ANIM", "anim/medal_origin_beetle.zip"),
}

local prefabs =
{
    "weevole_carapace",
    "monstermeat",
}

SetSharedLootTable("medal_origin_beetle",
{
    {'monstermeat',      0.25},
})

local brain = require "brains/medal_origin_beetlebrain"

local sounds =
{
	--哈姆雷特的资源,暂时屏蔽,后续挪了再用
    -- idle = "dontstarve_DLC003/creatures/enemy/weevole/idle",
    -- walk = "dontstarve_DLC003/creatures/enemy/weevole/walk",
    -- death = "dontstarve_DLC003/creatures/enemy/weevole/death",
    -- buzz = "dontstarve_DLC003/creatures/enemy/weevole/fly_LP",
    -- move = "dontstarve_DLC003/creatures/enemy/weevole/burrow",
    -- attack = "dontstarve_DLC003/creatures/enemy/weevole/attack",
    -- hit = "dontstarve_DLC003/creatures/enemy/weevole/hit",
    -- taunt = "dontstarve_DLC003/creatures/enemy/weevole/taunt",

    idle = "dontstarve/creatures/spider/walk_spider",
    walk = "dontstarve/creatures/spider/walk_spider",
    death = "dontstarve/creatures/mosquito/mosquito_death",
    buzz = "dontstarve/creatures/mosquito/mosquito_fly_LP",
    move = "dontstarve_DLC001/creatures/mole/move",
    attack = "dontstarve/creatures/mosquito/mosquito_attack",
    hit = "dontstarve/creatures/mosquito/mosquito_hurt",
    taunt = "dontstarve_DLC001/creatures/mole/sniff",
}

local NOTAGS = {"FX", "NOCLICK","INLIMBO", "wall", "structure", "aquatic","chaos_creature"}
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
	local dist = TUNING_MEDAL.MEDAL_ORIGIN_BEETLE_TARGET_DIST
    
    return FindEntity(inst, dist, function(guy)
        return  inst.components.combat:CanTarget(guy)
    end, nil, NOTAGS)
end

local function keeptargetfn(inst, target)
   return target ~= nil
        and target.components.combat ~= nil
        and not IsEntityDeadOrGhost(target)
end
--挨打
local function OnAttacked(inst, data)
    inst.components.combat:SetTarget(data.attacker)
    inst.components.combat:ShareTarget(data.attacker, 30, 
		function(dude)
			return dude:HasTag("medal_insect")
				and not dude.components.health:IsDead()
		end, 10)
end

local function OnFlyIn(inst)
    inst.DynamicShadow:Enable(false)
    inst.components.health:SetInvincible(true)
    local x,y,z = inst.Transform:GetWorldPosition()
    inst.Transform:SetPosition(x,15,z)
end

--后加载
local function OnLoadPostPass(inst, newents, data)
    if TheWorld and TheWorld.medal_origin_tree ~= nil and TheWorld.medal_origin_tree.components.commander then
        TheWorld.medal_origin_tree.components.commander:AddSoldier(inst)--加入本源之树守卫列表
    end
end

local function fn()
    local inst = CreateEntity()
    
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    MakeCharacterPhysics(inst, 10, .5)

    inst.sounds = sounds

    inst.DynamicShadow:SetSize(1.5, .5)
    inst.Transform:SetSixFaced()

    inst:AddTag("scarytoprey")
    inst:AddTag("monster")
    inst:AddTag("insect")
    inst:AddTag("hostile")
    -- inst:AddTag("canbetrapped")
    inst:AddTag("smallcreature")
    -- inst:AddTag("weevole")
    inst:AddTag("animal")
    inst:AddTag("medal_insect")
    inst:AddTag("chaos_creature")--混沌生物

    inst.AnimState:SetBank("weevole")
    inst.AnimState:SetBuild("weevole")
    inst.AnimState:PlayAnimation("idle")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
		return inst
	end	

    -- locomotor must be constructed before the stategraph!
    inst:AddComponent("locomotor")
    inst.components.locomotor:SetSlowMultiplier(1)
    inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor.pathcaps = { ignorecreep = true }
    inst.components.locomotor.walkspeed = TUNING_MEDAL.MEDAL_ORIGIN_BEETLE_WALK_SPEED
    inst.components.locomotor:SetAllowPlatformHopping(true)--可以上船
    inst:AddComponent("embarker")
    inst:AddComponent("drownable")

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("medal_origin_beetle")

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING_MEDAL.MEDAL_ORIGIN_BEETLE_HEALTH)

    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "body"
    inst.components.combat:SetKeepTargetFunction(keeptargetfn)
    inst.components.combat:SetRetargetFunction(3, retargetfn)
    inst.components.combat:SetDefaultDamage(TUNING_MEDAL.MEDAL_ORIGIN_BEETLE_DAMAGE)
    inst.components.combat:SetAttackPeriod(GetRandomMinMax(TUNING_MEDAL.MEDAL_ORIGIN_BEETLE_PERIOD_MIN, TUNING_MEDAL.MEDAL_ORIGIN_BEETLE_PERIOD_MAX))
    inst.components.combat:SetRange(TUNING_MEDAL.MEDAL_ORIGIN_BEETLE_ATTACK_RANGE, TUNING_MEDAL.MEDAL_ORIGIN_BEETLE_HIT_RANGE)
	
	inst:AddComponent("planarentity")--实体抵抗
    inst.ChaosDeathTimesKey = "medal_origin_tree"--死亡次数以本源之树的为准
    inst:AddComponent("medal_chaosdamage")--混沌伤害
    inst.components.medal_chaosdamage:SetBaseDamage(TUNING_MEDAL.MEDAL_ORIGIN_BEETLE_CHAOS_DAMAGE)

    inst:AddComponent("knownlocations")
    inst:AddComponent("inspectable")

    inst:ListenForEvent("attacked", OnAttacked)

    -- inst:AddComponent("eater")
    -- inst.components.eater.foodprefs = { "WOOD","SEEDS","ROUGHAGE" }
    -- inst.components.eater.ablefoods = { "WOOD","SEEDS","ROUGHAGE" }
    
    inst:SetStateGraph("SGmedal_origin_beetle")
    inst:SetBrain(brain)

    -- MakeSmallBurnableCharacter(inst, "body")
    -- MakeSmallFreezableCharacter(inst, "body")

	inst:ListenForEvent("fly_in", OnFlyIn)--跳船
    inst.OnLoadPostPass = OnLoadPostPass

    return inst
end

return Prefab("medal_origin_beetle", fn, assets, prefabs)
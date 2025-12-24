--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[


]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 加载项
	local this_prefab = "tbat_animal_snow_plum_chieftain"
	local brain = require("brains/02_tbat_animal_snow_plum_chieftain")
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 素材
	local assets = 
	{
		Asset("ANIM", "anim/pog_basic.zip"),
		Asset("ANIM", "anim/pog_actions.zip"),
		Asset("ANIM", "anim/pog_feral_build.zip"),

		Asset("ANIM", "anim/tbat_animal_snow_plum_chieftain.zip"),
		--Asset("SOUND", "sound/catcoon.fsb"),
	}
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 参数
	local ANIM_SCALE = 1.5	--- 素材缩放倍数
	local SCALE = 1.2		--- 其他缩放倍数

	local POG_ATTACK_RANGE = 3 * SCALE
	local POG_MELEE_RANGE = 2.5 * SCALE
	local POG_TARGET_DIST = 20
	local POG_WALK_SPEED = 2 * ANIM_SCALE
	local POG_RUN_SPEED = 4.5 *ANIM_SCALE
	local POG_DAMAGE = 60
	local POG_HEALTH = 1200
	local POG_ATTACK_PERIOD = 2

	local MIN_POGNAP_INTERVAL = 30
	local MAX_POGNAP_INTERVAL = 120
	local MIN_POGNAP_LENGTH = 20
	local MAX_POGNAP_LENGTH = 40

	local POG_LOYALTY_MAXTIME = 480
	local POG_LOYALTY_PER_ITEM = 480*.1
	local POG_EAT_DELAY = 0.5
	local POG_SEE_FOOD = 20

	local MAX_TARGET_SHARES = 5
	local SHARE_TARGET_DIST = 30
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 掉落列表
	SetSharedLootTable( "tbat_animal_snow_plum_chieftain",
	{
		{"tbat_material_snow_plum_wolf_hair", 1.00},
		{"tbat_material_snow_plum_wolf_hair", 1.00},
		{"tbat_food_raw_meat", 1.00},
		{"tbat_food_raw_meat", 1.00},
		{"tbat_food_raw_meat", 1.00},
		{"tbat_food_raw_meat", 1.00},
		{"tbat_food_raw_meat", 1.00},
		{"tbat_food_raw_meat", 1.00},
		{"tbat_food_raw_meat", 1.00},
		{"tbat_food_raw_meat", 1.00},
		{"tbat_material_snow_plum_wolf_heart", TBAT.DEBUGGING and 1 or 0.7},
		{"tbat_building_snow_plum_pet_house_blueprint2", TBAT.DEBUGGING and 1 or 0.1},
		{"tbat_item_snow_plum_wolf_kit_blueprint2", TBAT.DEBUGGING and 1 or 0.05},
	})
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 战斗攻击
	local function OnAttacked(inst, data)
		local attacker = data.attacker
		inst:ClearBufferedAction()

		if inst.components.combat and not inst.components.combat.target then
		--	inst.sg:GoToState("hiss")
		end
		if inst.components.combat then 
			inst.components.combat:SetTarget(data.attacker) 
			inst.components.combat:ShareTarget(attacker, SHARE_TARGET_DIST, function(dude) return dude:HasTag("tbat_animal_snow_plum_chieftain") end, MAX_TARGET_SHARES)
		end		
	end
	local function get_leader(inst)
		return inst.components.follower and inst.components.follower.leader or nil
	end
	local function get_player_leader(inst)
		local eyebone = get_leader(inst)
		if eyebone and eyebone.components.inventoryitem then
			return eyebone.components.inventoryitem:GetGrandOwner()
		end
		return nil
	end	
	local RETARGET_TAGS = {"_health"}
    local RETARGET_NO_TAGS = {"INLIMBO", "notarget", "invisible","companion" }
	-- 检查目标是否有效（有健康组件且未死亡）
	local function IsValidTarget(target)
		return target and target.components.health and not target.components.health:IsDead()
	end
	-- 检查是否为雪莓酋长
	local function IsSnowPlumChieftain(target)
		return target:HasTag("tbat_animal_snow_plum_chieftain")
	end
	-- 检查是否是同一个实体（避免领导者指向自身）
	local function IsSameEntity(entityA, entityB)
		return entityA == entityB
	end
	-- 检查是否是同领导者（安全处理nil）
	local function IsSameLeader(inst, target)
		local instLeader = get_leader(inst)
		local targetLeader = get_leader(target)
		return instLeader ~= nil and targetLeader ~= nil and instLeader == targetLeader
	end
	-- 检查目标是否可作为战斗目标
	local function KeepTargetFn(inst, target)
		-- 基础有效性检查
		if not IsValidTarget(target) then
			return false
		end
		-- 雪莓酋长的特殊规则（同类目标）
		if IsSnowPlumChieftain(target) then
			-- 排除同领导者（inst的领导者和target的领导者相同）
			if IsSameLeader(inst, target) then
				return false
			end			
			-- 排除inst的领导者指向target（target是inst的领导者）
			local instLeader = get_leader(inst)
			if instLeader and IsSameEntity(instLeader, target) then
				return false
			end			
			return true
		end
		-- 普通目标规则
		local instLeader = get_leader(inst)
		local playerLeader = get_player_leader(inst)  -- 原始代码中的函数
		-- 排除inst的领导者指向target
		if instLeader and IsSameEntity(instLeader, target) then
			return false
		end		
		-- 排除玩家领导者指向target
		if playerLeader and IsSameEntity(playerLeader, target) then
			return false
		end
		--- 怪物玩家处理
		if not TBAT.PET_MODULES:ThisIsWildAnimal(inst) and target:HasTag("player") then
			return false
		end
		--- 非野生处理（同是家养、禁止打架）
		if not TBAT.PET_MODULES:ThisIsWildAnimal(inst) and not TBAT.PET_MODULES:ThisIsWildAnimal(target) then
			return false
		end
		return true
	end
	-- 重定向目标过滤器
	local function RetargetFn(inst)
		return FindEntity(inst, POG_TARGET_DIST,
			function(guy)
				-- 排除非目标类型
				if not (guy:HasTag("monster") or guy:HasTag("smallcreature")) then
					return false
				end				
				-- 排除雪莓酋长
				if IsSnowPlumChieftain(guy) then
					return false
				end				
				-- 健康状态检查
				if not IsValidTarget(guy) then
					return false
				end				
				-- 战斗目标检查
				if not inst.components.combat:CanTarget(guy) then
					return false
				end				
				-- 排除abigail目标（当inst有领导者时）
				local instLeader = get_leader(inst)
				if instLeader and guy:HasTag("abigail") then
					return false
				end				
				-- 排除同领导者目标
				if IsSameLeader(inst, guy) then
					return false
				end				
				-- 排除领导者拥有者冲突（guy的领导者是inst的拥有者）
				local guyLeader = get_leader(guy)
				if instLeader and guyLeader and guyLeader.components.inventoryitem then
					local owner = guyLeader.components.inventoryitem.owner
					if owner and instLeader == owner then
						return false
					end
				end				
				-- 排除玩家领导者指向guy
				local playerLeader = get_player_leader(inst)
				if playerLeader and IsSameEntity(playerLeader, guy) then
					return false
				end
				--- 怪物玩家处理
				if not TBAT.PET_MODULES:ThisIsWildAnimal(inst) and guy:HasTag("player") then
					return false
				end
				--- 非野生处理（同是家养、禁止打架）
                if not TBAT.PET_MODULES:ThisIsWildAnimal(inst) and not TBAT.PET_MODULES:ThisIsWildAnimal(guy) then
                    return false
                end
				return true
			end,
			RETARGET_TAGS,
			RETARGET_NO_TAGS
		)
	end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 睡觉
	local function SleepTest(inst)
		if inst.components.follower and inst.components.follower.leader then return end
		if inst.components.combat and inst.components.combat.target then return end
		if inst.components.playerprox:IsPlayerClose() then return end
		if not inst.sg:HasStateTag("busy") and (not inst.last_wake_time or GetTime() - inst.last_wake_time >= inst.nap_interval) then
			inst.nap_length = math.random(MIN_POGNAP_LENGTH, MAX_POGNAP_LENGTH)
			inst.last_sleep_time = GetTime()
			return true
		end
	end

	local function WakeTest(inst)
		if not inst.last_sleep_time or GetTime() - inst.last_sleep_time >= inst.nap_length then
			inst.nap_interval = math.random(MIN_POGNAP_INTERVAL, MAX_POGNAP_INTERVAL)
			inst.last_wake_time = GetTime()
			return true
		end
	end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 物品接受
	local function ShouldAcceptItem(inst, item)
		if inst.components.health and inst.components.health:IsDead() then return false end

		if item.components.edible and (
			item.components.edible.foodtype == "MEAT" or 
			item.components.edible.foodtype == "VEGGIE" or 
			item.components.edible.foodtype == "SEEDS" or
			item.components.edible.foodtype == "INSECT" or
			item.components.edible.foodtype == "GENERIC") then
			return true
		end

		return false
	end

	local function OnGetItemFromPlayer(inst, giver, item)
		if inst.components.sleeper:IsAsleep() then
			inst.components.sleeper:WakeUp()
		else
			if inst.components.combat.target and inst.components.combat.target == giver then
				inst.components.combat:SetTarget(nil)
				inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/catcoon/pickup")
			elseif giver.components.leader then
				inst.SoundEmitter:PlaySound("dontstarve/common/makeFriend")
				-- giver.components.leader:AddFollower(inst)
				-- inst.components.follower:AddLoyaltyTime(POG_LOYALTY_PER_ITEM)
			end       
		end
		
	end

	local function OnRefuseItem(inst, giver, item)	
		if inst.components.sleeper:IsAsleep() then
			inst.components.sleeper:WakeUp()
		elseif not inst.sg:HasStateTag("busy") then    
			inst:FacePoint(giver.Transform:GetWorldPosition())
			inst.sg:GoToState("refuse")
		end
	end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 招募 workable_install
    local workable_com_install = require("prefabs/11_tbat_animals/00_pet_workable_com_install")
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 翻找箱子
	local function item_test_event(inst,call_back_table)
		if inst.GetFollowingPlayer and inst:GetFollowingPlayer() then
			call_back_table.flag = false
			return
		end
		local item = call_back_table and call_back_table.item
		if item and item:HasTag("nosteal") then
			call_back_table.flag = false
			return
		end
		call_back_table.flag = true
	end
	local function toss_container_event_installer(inst)
		inst:ListenForEvent("can_steal_item",item_test_event)
	end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 主体
	local function fn()
		local inst = CreateEntity()
		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddSoundEmitter()
		inst.entity:AddDynamicShadow()

		inst.DynamicShadow:SetSize(2,0.75)
		inst.Transform:SetFourFaced()
		inst.entity:AddNetwork()

		MakeCharacterPhysics(inst, 1, 0.5)
		if TBAT.CONFIG.ANIMAL_PHYSICS_REMOVE then
			RemovePhysicsColliders(inst)
		end

		inst.AnimState:SetBank("pog")
		-- inst.AnimState:SetBuild("pog_actions")
		inst.AnimState:SetBuild("tbat_animal_snow_plum_chieftain")
		inst.AnimState:PlayAnimation("idle_loop")
		inst.AnimState:SetScale(ANIM_SCALE,ANIM_SCALE,ANIM_SCALE)

		-- inst:AddTag("smallcreature")
		inst:AddTag("animal")
		inst:AddTag("tbat_animal_snow_plum_chieftain")
		inst:AddTag("scarytoprey")

		inst.entity:SetPristine()
		-------------------------------------------------
		--- 可交互
			workable_com_install(inst)
		-------------------------------------------------
		if not TheWorld.ismastersim then
			return inst
		end	
		-------------------------------------------------
		--- 检查
			inst:AddComponent("inspectable")
		-------------------------------------------------
		--- 生命
			inst:AddComponent("health")
			inst.components.health:SetMaxHealth(POG_HEALTH)
		-------------------------------------------------
		--- 战斗
			inst:AddComponent("combat")
			inst.components.combat:SetDefaultDamage(POG_DAMAGE)
			inst.components.combat:SetRange(POG_ATTACK_RANGE,POG_ATTACK_RANGE)
			inst.components.combat:SetAttackPeriod(POG_ATTACK_PERIOD)
			inst.components.combat:SetKeepTargetFunction(KeepTargetFn)
			inst.components.combat:SetRetargetFunction(3, RetargetFn)
			inst.components.combat:SetHurtSound("dontstarve_DLC003/creatures/pog/hit")
			inst:ListenForEvent("attacked", OnAttacked)
			inst.components.combat.battlecryinterval = 20
		-------------------------------------------------
		--- 名字
			inst:AddComponent("named")
		-------------------------------------------------
		--- 掉落物
			inst:AddComponent("lootdropper")
			-- inst.components.lootdropper:SetChanceLootTable('pog') 
			inst.components.lootdropper:SetChanceLootTable("tbat_animal_snow_plum_chieftain")
		-------------------------------------------------
		--- 跟随
			inst:AddComponent("follower")
			inst.components.follower.maxfollowtime = POG_LOYALTY_MAXTIME
		-------------------------------------------------
		--- 吃
			inst:AddComponent("eater")
			inst.components.eater:SetCanEatHorrible()
			inst.components.eater.strongstomach = true -- can eat monster meat!
		-------------------------------------------------
		-- 贸易
			inst:AddComponent("inventory")
			inst:AddComponent("trader")
			inst.components.trader:SetAcceptTest(ShouldAcceptItem)
			inst.components.trader.onaccept = OnGetItemFromPlayer
			inst.components.trader.onrefuse = OnRefuseItem
			inst.components.trader.deleteitemonaccept = false
		-------------------------------------------------
		--- 玩家靠近、远离
			inst:AddComponent("playerprox")
			inst.components.playerprox:SetDist(4,6)
			inst.components.playerprox:SetOnPlayerNear(function(inst)
				inst:AddTag("can_beg")
				if inst.components.sleeper:IsAsleep() then
					inst.components.sleeper:WakeUp()
				end
			end)
			inst.components.playerprox:SetOnPlayerFar(function(inst)
				inst:RemoveTag("can_beg")
			end)
		-------------------------------------------------
		--- 睡眠
			inst:AddComponent("sleeper")
			--inst.components.sleeper:SetResistance(3)
			inst.components.sleeper.testperiod = GetRandomWithVariance(6, 2)
			inst.last_sleep_time = nil
			inst.last_wake_time = GetTime()
			inst.nap_interval = math.random(MIN_POGNAP_INTERVAL, MAX_POGNAP_INTERVAL)
			inst.nap_length = math.random(MIN_POGNAP_LENGTH, MAX_POGNAP_LENGTH)
			inst.components.sleeper:SetWakeTest(WakeTest)
			inst.components.sleeper:SetSleepTest(SleepTest)
		-------------------------------------------------
		--- 走路控制器
			inst:AddComponent("locomotor")
			inst.components.locomotor.walkspeed = POG_WALK_SPEED
			inst.components.locomotor.runspeed = POG_RUN_SPEED
		-------------------------------------------------
		--- 登船控制
			-- boat hopping setup
			inst.components.locomotor:SetAllowPlatformHopping(true)
			inst:AddComponent("embarker")		
		-------------------------------------------------
		--- 族群即 坐标记录器
			inst:AddComponent("knownlocations")
			inst:AddComponent("herdmember")
		-------------------------------------------------
		--- home 寻找
			inst:AddComponent("homeseeker")
		-------------------------------------------------
		--- 可燃可冻结
			MakeSmallBurnableCharacter(inst, "pog_chest", Vector3(1,0,1))
			MakeSmallFreezableCharacter(inst)
		-------------------------------------------------
		--- 头脑AI 和 SG
			inst:SetBrain(brain)
			inst:SetStateGraph("SGtbat_animal_snow_plum_chieftain")
		-------------------------------------------------
		---
			toss_container_event_installer(inst)
		-------------------------------------------------
		return inst
	end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, fn, assets)
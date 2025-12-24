--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 加载
	local this_prefab = "tbat_animal_maple_squirrel"
	local brain = require "brains/04_tbat_animal_maple_squirrel_brain"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 参数组
	local ANIM_SCALE = 2

	local INTENSITY = .5
	local PIKO_HEALTH = 280
	local PIKO_RESPAWN_TIME = 300*4
	local PIKO_RUN_SPEED = 4 * 1.5

	local PIKO_DAMAGE = 15
	local PIKO_ATTACK_PERIOD = 2
	local PIKO_ATTACK_RANGE = 2

	local PIKO_TARGET_DIST = 20
	local PIKO_RABID_SANITY_THRESHOLD = 0.8
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 素材
	local assets =
	{
		Asset("ANIM", "anim/ds_squirrel_basic.zip"),
		Asset("ANIM", "anim/squirrel_cheeks_build.zip"),
		Asset("ANIM", "anim/squirrel_build.zip"),
		Asset("ANIM", "anim/tbat_animal_maple_squirrel.zip"),
		Asset("ANIM", "anim/tbat_animal_maple_squirrel_with_cheeks.zip"),
	}
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 掉落物
    SetSharedLootTable(this_prefab,
    {
        {"tbat_item_holo_maple_leaf",             1.00},
        {"tbat_item_holo_maple_leaf",             1.00},
        {"tbat_material_liquid_of_maple_leaves",             1.00},
        {"tbat_food_raw_meat",             1.00},
        {"tbat_plant_crimson_maple_tree_kit",             TBAT.DEBUGGING and 1 or 0.2},
        {"tbat_building_maple_squirrel_pet_house_blueprint2",             TBAT.DEBUGGING and 1 or 0.1},
        {"tbat_item_maple_squirrel_kit_blueprint2",             TBAT.DEBUGGING and 1 or 0.05},
    })
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 音效
	local pikosounds = 
	{
		scream = "dontstarve/rabbit/scream",
		hurt = "dontstarve/rabbit/scream_short",
	}
	local function getmurdersound(inst)
		return pikosounds.hurt
	end
	local function getincineratesound(inst)
		return pikosounds.scream
	end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 从背包丢出来
	local function OnDrop(inst)
		inst.sg:GoToState("stunned")
	end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 烹饪
	local function GetCookProductFn(inst, cooker, chef)
		return "cookedsmallmeat"
	end
	local function OnCookedFn(inst, cooker, chef)
		return inst.sounds.hurt
	end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 加载范围
	local function OnWake(inst)
		-- TODO: Decide what happens when a piko wakes.
	end

	local function OnSleep(inst)
		if inst.checktask then
			inst.checktask:Cancel()
			inst.checktask = nil
		end
	end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 战斗
	local function OnAttacked(inst, data)
		local attacker = data and data.attacker
		if attacker and attacker.prefab == inst.prefab then
			return
		end
		inst.components.combat:SetTarget(attacker)
		local x, y, z = inst.Transform:GetWorldPosition()
		local ents = TheSim:FindEntities(x, y, z, 30, {"tbat_animal_maple_squirrel"})
		for k, v in pairs(ents) do
			v.components.combat:SuggestTarget(attacker)
		end
	end
	local function Retarget(inst)  --- 自动寻找目标。
		local target = inst.components.combat.target
		if target and target:IsValid() and target.components.health and not target.components.health:IsDead() then
			local following_player = inst.GetFollowingPlayer and inst:GetFollowingPlayer()
			if following_player == target then
				return
			end
			--- 非野生处理（同是家养、禁止打架）
			if not TBAT.PET_MODULES:ThisIsWildAnimal(inst) and not TBAT.PET_MODULES:ThisIsWildAnimal(target) then
				return
			end
			return target
		end

		-- local dist = PIKO_TARGET_DIST
		-- return FindEntity(inst, dist, function(guy) 
		-- 	return not guy:HasTag("piko") and inst.components.combat:CanTarget(guy) and guy.components.inventory and (guy.components.inventory:NumItems() > 0)
		-- end)
	end

	local function KeepTarget(inst, target)
		--- 非野生处理（同是家养、禁止打架）
		if not TBAT.PET_MODULES:ThisIsWildAnimal(inst) and not TBAT.PET_MODULES:ThisIsWildAnimal(target) then
			return false
		end
		return inst.components.combat:CanTarget(target)
	end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 回家
	local function OnWentHome(inst)
		local tree = inst.components.homeseeker and inst.components.homeseeker.home or nil
		if not tree then return end
		if tree.components.inventory then
			inst.components.inventory:TransferInventory(tree)        
		end
	end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 
	local function OnPickup(inst)

	end

	local function OnStolen(inst, victim, item)
		-- TODO: Sort out if anything needs to happen when a piko steals from another entity.
	end

	local function ontrapped(inst) -- 被陷阱抓，往房子发送事件。
		local leader = inst.components.follower and inst.components.follower:GetLeader()
		if leader and leader:IsValid() then
			leader:PushEvent("follower_trapped",inst)
		end
	end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 招募 workable_install
    local workable_com_install = require("prefabs/11_tbat_animals/00_pet_workable_com_install")
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- talker
	local function talk_sound_kill(inst)
		inst.SoundEmitter:KillSound("talk")
	end
	local function talk_cd(inst)
		inst.__talk_cd = nil
	end
	local function talk_event(inst,str)
		if inst.__talk_cd then
			return
		end
		inst.components.talker:Say(str)
		inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/piko/scream","talk")
		inst:DoTaskInTime(5,talk_sound_kill)
		inst.__talk_cd = inst:DoTaskInTime(4,talk_cd)
	end
	local function following_player_in_danger_talk(inst)
		local str_table = TBAT:GetString2(this_prefab,"following_player_in_danger_talk") or {}
		local str = str_table[math.random(#str_table)]
		if str then
			talk_event(inst,str)
		end
	end
	local function talker_com_install(inst)
		inst:AddComponent("talker")
		inst.components.talker.fontsize = 30
		inst.components.talker.font = TALKINGFONT
		-- inst.components.talker.colour = Vector3(165/255, 180/255, 200/255)
		inst.components.talker.colour = Vector3(255/255, 153/255, 51/255)
		inst.components.talker.offset = Vector3(0,-180,0)
		inst:ListenForEvent("talk",talk_event)
		inst:ListenForEvent("following_player_in_danger_talk",following_player_in_danger_talk)
	end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 物品拾取检查
	local function item_pickup_event_checker(inst,data)
		local item =  data and data.item
		if item and item:IsValid() and item == inst.__brain_pickup_action_item then			
			-- print("松鼠拾取并销毁物品",item)
			local saved_record = item:GetSaveRecord()
			item:Remove()
			local item_records = inst.components.tbat_data:Get("item_records",{})
			table.insert(item_records,saved_record)
			inst.components.tbat_data:Set("item_records",item_records)
		end
	end
	local old_DropLoot = nil
	local function new_DropLoot(self,...)
		if old_DropLoot then
			old_DropLoot(self,...)
		end
		local inst = self.inst
		local item_records = inst.components.tbat_data:Get("item_records",{})
		local x,y,z = self.inst.Transform:GetWorldPosition()
		for k, record in pairs(item_records) do
			local item = SpawnSaveRecord(record)
			item.Transform:SetPosition(x,y,z)
			item.components.inventoryitem:DoDropPhysics(x,y,z)
		end
	end
	local function hook_loot_dropper_for_item_pick(inst)
		old_DropLoot = old_DropLoot or inst.components.lootdropper.DropLoot
		inst.components.lootdropper.DropLoot = new_DropLoot		
	end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 嘴巴脸颊控制
	local function show_cheeks_event(inst,show)
		if show then
			inst.AnimState:OverrideSymbol("mouth","tbat_animal_maple_squirrel_with_cheeks","mouth")
		else
			inst.AnimState:ClearOverrideSymbol("mouth")
		end
	end
	local function cheeks_sg_event(inst)
		if inst.components.inventory:NumItems() > 0 then
			inst:PushEvent("show_cheeks",true)
		else
			inst:PushEvent("show_cheeks",false)
		end
	end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 主体
	local function fn()
		local inst = CreateEntity()
		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddPhysics()
		inst.entity:AddSoundEmitter()
		inst.entity:AddDynamicShadow()
		inst.entity:AddNetwork()
		
		inst.DynamicShadow:SetSize(1, 0.75)
		

		inst.Transform:SetFourFaced()

		MakeCharacterPhysics(inst, 1, 0.12)
		if TBAT.CONFIG.ANIMAL_PHYSICS_REMOVE then
			RemovePhysicsColliders(inst)
		end
		inst.AnimState:SetBank("squirrel")
		inst.AnimState:SetBuild("tbat_animal_maple_squirrel")
		inst.AnimState:PlayAnimation("idle", true)
		inst.AnimState:SetScale(ANIM_SCALE,ANIM_SCALE,ANIM_SCALE)
		--------------------------------------------------------------------------------------------------------
		-- tag
			inst:AddTag("animal")
			inst:AddTag("tbat_animal_maple_squirrel")
			inst:AddTag("smallcreature")
			inst:AddTag("canbetrapped")
		--------------------------------------------------------------------------------------------------------
			inst.entity:SetPristine()
		--------------------------------------------------------------------------------------------------------
		--- 交互
			workable_com_install(inst)
		--------------------------------------------------------------------------------------------------------
		--- talker
			talker_com_install(inst)
		--------------------------------------------------------------------------------------------------------
			if not TheWorld.ismastersim then
				return inst
			end	
			inst.data = {}
		--------------------------------------------------------------------------------------------------------
		--- 行动
			inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
			inst.components.locomotor.runspeed = PIKO_RUN_SPEED	
		--------------------------------------------------------------------------------------------------------
		--- 可吃东西
			inst:AddComponent("eater")
			-- inst.components.eater:SetDiet({ FOODTYPE.SEEDS }, { FOODTYPE.SEEDS })
			inst.components.eater:SetDiet({ FOODTYPE.SEEDS,FOODTYPE.VEGGIE,FOODTYPE.GOODIES })
		--------------------------------------------------------------------------------------------------------
		--- 背包
			inst:AddComponent("inventory")
		--------------------------------------------------------------------------------------------------------
		--- 光环
			inst:AddComponent("sanityaura")
		--------------------------------------------------------------------------------------------------------
		--- 可被拾取
			inst:AddComponent("inventoryitem")
			inst.components.inventoryitem.nobounce = true
			inst.components.inventoryitem.canbepickedup = false
			inst.components.inventoryitem.canbepickedupalive = true
			inst.components.inventoryitem:SetSinks(true)
        	inst.components.inventoryitem:TBATInit("tbat_animal_maple_squirrel","images/inventoryimages/tbat_animal_maple_squirrel.xml")

		--------------------------------------------------------------------------------------------------------
		--- 可被烹饪
			inst:AddComponent("cookable")
			inst.components.cookable.product = GetCookProductFn
			inst.components.cookable:SetOnCookedFn(OnCookedFn)
		--------------------------------------------------------------------------------------------------------
		--- 坐标记录器
			inst:AddComponent("knownlocations")
		--------------------------------------------------------------------------------------------------------
		--- 战斗
			inst:AddComponent("combat")
			inst.components.combat:SetDefaultDamage(PIKO_DAMAGE)
			inst.components.combat:SetAttackPeriod(PIKO_ATTACK_PERIOD)
			inst.components.combat:SetRange(PIKO_ATTACK_RANGE,PIKO_ATTACK_RANGE)
			inst.components.combat:SetRetargetFunction(3, Retarget)
			inst.components.combat:SetKeepTargetFunction(KeepTarget)
			-- inst.components.combat.hiteffectsymbol = "chest"
			-- inst.components.combat.onhitotherfn = function(inst, other, damage) inst.components.thief:StealItem(other) end
		--------------------------------------------------------------------------------------------------------
		--- 名字
			inst:AddComponent("named")
		--------------------------------------------------------------------------------------------------------
		--- 偷窃
			inst:AddComponent("thief")
			inst.components.thief:SetOnStolenFn(OnStolen)
		--------------------------------------------------------------------------------------------------------
		--- 血量
			inst:AddComponent("health")
			inst.components.health:SetMaxHealth(PIKO_HEALTH)
			inst.components.health.murdersound = getmurdersound
    		inst.incineratesound = getincineratesound
		--------------------------------------------------------------------------------------------------------
		--- 冰冻、可燃
			MakeSmallBurnableCharacter(inst, "chest")
			MakeTinyFreezableCharacter(inst, "chest")
		--------------------------------------------------------------------------------------------------------
		--- 掉落物
			inst:AddComponent("tbat_data")
			inst:AddComponent("lootdropper")
			-- inst.components.lootdropper:SetLoot({"smallmeat"})
            inst.components.lootdropper:SetChanceLootTable(this_prefab)
			hook_loot_dropper_for_item_pick(inst)
		--------------------------------------------------------------------------------------------------------
		--- 可给东西
			inst:AddComponent("tradable")
		--------------------------------------------------------------------------------------------------------
		--- 房子寻找
			inst:AddComponent("homeseeker")
		--------------------------------------------------------------------------------------------------------
		--- 跟随
			inst:AddComponent("follower")
		--------------------------------------------------------------------------------------------------------
		--- 可被观察、睡眠
			inst:AddComponent("inspectable")
			inst:AddComponent("sleeper")
		--------------------------------------------------------------------------------------------------------
		--- 音效、加载范围
			inst.sounds = pikosounds
			inst.OnEntityWake = OnWake
			inst.OnEntitySleep = OnSleep   
		--------------------------------------------------------------------------------------------------------
		--- sg 和 ai
			inst:SetStateGraph("SGtbat_animal_maple_squirrel")
			inst:SetBrain(brain)	
		--------------------------------------------------------------------------------------------------------
		--- event
			-- inst:ListenForEvent("death", OnDeath)
			inst:ListenForEvent("attacked", OnAttacked)		-- 被攻击
			inst:ListenForEvent("onwenthome", OnWentHome)	-- 回家
			inst:ListenForEvent("onpickup", OnPickup)		-- 被捡起来
			inst:ListenForEvent("ontrapped", ontrapped)		-- 被陷阱抓
			inst:ListenForEvent("itemget", item_pickup_event_checker) -- 物品获取 event
			inst:ListenForEvent("show_cheeks",show_cheeks_event)	-- 脸颊控制。
			inst:ListenForEvent("newstate",cheeks_sg_event)	-- 脸颊控制。
		--------------------------------------------------------------------------------------------------------
		--- 
			MakeFeedablePet(inst, 480*2, nil, OnDrop)
		--------------------------------------------------------------------------------------------------------
		-- MakeSmallBurnableCharacter(inst)
		-- MakeSmallFreezableCharacter(inst)
		-- MakeHauntablePanicAndIgnite(inst)

		return inst
	end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return  Prefab(this_prefab, fn, assets)

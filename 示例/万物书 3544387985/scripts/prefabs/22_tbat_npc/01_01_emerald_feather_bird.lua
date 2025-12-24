--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

	翠羽鸟

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 素材
	local assets =
	{
		Asset("ANIM", "anim/carnival_host.zip"),
		Asset("ANIM", "anim/tbat_npc_emerald_feather_bird.zip"),
	}
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 脑子、参数
	local this_prefab = "tbat_npc_emerald_feather_bird"
	local brain = require "brains/01_tbat_npc_emerald_feather_bird_brian"
	local MAX_WANDER_DIST_SQ = 15*15
	local PLAYER_NEAR_DIST = 5
	local PLAYER_FAR_DIST = 6

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---- 随机话语
	local function random_talk(inst)
		if inst.force_talking then
			return
		end
		local call_back = {}
		inst:PushEvent("get_random_wander_talk",call_back)
		inst.components.talker:Say(tostring(call_back[1]))

		local player = inst:GetNearestPlayer(true)
		if player then
			inst:ForceFacePoint(player.Transform:GetWorldPosition())
		end
	end
	local function stop_near_talk_task(inst)
		if inst.__near_talk_task then
			inst.__near_talk_task:Cancel()
		end
		inst.__near_talk_task = nil
	end
	local function start_near_talk_task(inst,skip_zero)
		stop_near_talk_task(inst)
		if not skip_zero then
			random_talk(inst)
		end
		inst.__near_talk_task = inst:DoPeriodicTask(10, random_talk,math.random(2,8))
	end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 靠近、远离。
	local function onnear(inst,player)
		inst.components.locomotor:StopMoving()
		inst:StopBrain()
		start_near_talk_task(inst)
		if player then
			inst:ForceFacePoint(player.Transform:GetWorldPosition())
		end
	end
	local function onfar(inst,player)
		inst:RestartBrain()
		local x,y,z = inst.Transform:GetWorldPosition()
		local ents = TheSim:FindEntities(x,y,z,PLAYER_NEAR_DIST,{"player"})
		if #ents == 0 then
			stop_near_talk_task(inst)
		end
	end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---- force talk
	local function force_talk(inst,str)
		inst.components.talker:Say(str)
		start_near_talk_task(inst,true)
	end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 锚点绑定
	local function location_link_target(inst,target)
		if target and target:IsValid() then
			inst.components.knownlocations:RememberLocation("home", Vector3(target.Transform:GetWorldPosition()))
		end
	end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 给brain 调用。
	local function get_random_wander_talk(inst,callback)
		local str_table = TBAT:GetString2(this_prefab,"wander_talk")
		local str = str_table[math.random(#str_table)]
		table.insert(callback,str)
	end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 交易核心逻辑
    local main_logic_install = require("prefabs/22_tbat_npc/01_02_item_accept_com")
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 声音替换
    local sound_hook = require("prefabs/22_tbat_npc/01_04_sound_hook")
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
	local function fn()
		local inst = CreateEntity()

		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddSoundEmitter()
		inst.entity:AddDynamicShadow()
		inst.entity:AddMiniMapEntity()
		inst.entity:AddNetwork()

		-- MakeCharacterPhysics(inst, 100, .5)
		MakeCharacterPhysics(inst, 100, .5)
		RemovePhysicsColliders(inst)

		inst.DynamicShadow:SetSize(1.5, .75)
		inst.Transform:SetSixFaced()

		inst.AnimState:SetBank("carnival_host")
		inst.AnimState:SetBuild("tbat_npc_emerald_feather_bird")

		inst:AddComponent("talker")
		inst.components.talker.fontsize = 30
		inst.components.talker.font = TALKINGFONT
		-- inst.components.talker.colour = Vector3(165/255, 180/255, 200/255)
		inst.components.talker.colour = Vector3(0/255, 180/255, 0/255)
		inst.components.talker.offset = Vector3(0, -620, 0)
		inst.components.talker:MakeChatter()

		inst:AddTag("character")
		inst:AddTag("npc")
		inst:AddTag("tbat_npc_emerald_feather_bird")


		-- inst.MiniMapEntity:SetIcon("carnival_host.png")
		-- inst.MiniMapEntity:SetPriority(5)

		inst.entity:SetPristine()
		inst.persists = false   --- 是否留存到下次存档加载。 -- 存档重新生成时候再重新创建NPC
		main_logic_install(inst)
		if not TheWorld.ismastersim then
			return inst
		end
		-----------------------------------------------------
		--- 
			sound_hook(inst)
		-----------------------------------------------------
		--- 
			local playerprox = inst:AddComponent("playerprox")
			inst.components.playerprox:SetDist(PLAYER_NEAR_DIST,PLAYER_FAR_DIST)
			inst.components.playerprox:SetOnPlayerNear(onnear)
			inst.components.playerprox:SetOnPlayerFar(onfar)
			inst.components.playerprox:SetTargetMode(playerprox.TargetModes.AllPlayers)
        	inst.components.playerprox:SetPlayerAliveMode(playerprox.AliveModes.DeadOrAlive)
		-----------------------------------------------------
		--- 原版都有的模块
			inst:AddComponent("locomotor")
			inst.components.locomotor.walkspeed = 2 -- this is modified throughtout the walk cycle
			inst:AddComponent("knownlocations")
			inst:AddComponent("lootdropper")
			inst:AddComponent("inspectable")
			MakeHauntablePanic(inst)
			inst:SetStateGraph("SGcarnival_host")
			inst:SetBrain(brain)
		-----------------------------------------------------
		--- 事件绑定
			inst:ListenForEvent("link",location_link_target)
			inst:ListenForEvent("get_random_wander_talk",get_random_wander_talk)
			inst:ListenForEvent("force_talk",force_talk)
		-----------------------------------------------------
		return inst
	end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, fn, assets)

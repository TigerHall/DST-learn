-- 三叉戟无法攻击飞行单位
AddPrefabPostInit("trident", function(inst)
    if not TheWorld.ismastersim then return end
    local _DoWaterExplosionEffect = inst.DoWaterExplosionEffect
    inst.DoWaterExplosionEffect = function(inst, v, ...)
        if v and v:IsValid() and (v:HasTag("flying") or v:HasTag("swc2hm") or (v.components.health and v:IsOnValidGround())) then return end
        _DoWaterExplosionEffect(inst, v, ...)
    end
end)
AddStategraphPostInit("wilson", function(sg)
    local chop = sg.states.chop.onenter
    sg.states.chop.onenter = function(inst, ...)
        chop(inst, ...)
        inst.sg.statemem.recoilstate = "gnaw_recoil"
    end
    local dig = sg.states.dig.onenter
    sg.states.dig.onenter = function(inst, ...)
        dig(inst, ...)
        inst.sg.statemem.recoilstate = "gnaw_recoil"
    end
end)

-- 小丑牌堆禁止检测战斗状态
if NON_LIFEFORM_TARGET_TAGS then
	table.insert(NON_LIFEFORM_TARGET_TAGS, 1, "card")
end
AddPrefabPostInit("deck_of_cards", function(inst)
	if not inst:HasTag("card") then inst:AddTag("card") end
end)

-- 流浪商人
TUNING.WANDERINGTRADER_SHOP_REFRESH_INTERVAL = TUNING.WANDERINGTRADER_SHOP_REFRESH_INTERVAL * 5
AddRecipePostInit("wanderingtradershop_gears", function(inst)
    inst.ingredients = {
        Ingredient("pigskin", 3),
        Ingredient("silk", 3),
    }
end)

AddRecipePostInit("wanderingtradershop_pigskin", function(inst)
    inst.ingredients = {
        Ingredient("carrotcake2hm", 1)
    }
    inst.numtogive = 3
end)

AddRecipePostInit("wanderingtradershop_livinglog", function(inst)
    inst.ingredients = {
        Ingredient("pigskin", 3)
    }
end)

-- -- 小丑机掉落削弱，禁止刷新角色牌
-- local BALATRO_UTIL = require("prefabs/balatro_util")
-- local BALATRO_SCORE_UTILS = require("prefabs/balatro_score_utils")

-- local STRING_REWARDS_TYPES = {}
-- for k, v in pairs(STRINGS.BALATRO.JIMBO_REWARD_TYPES) do
--     table.insert(STRING_REWARDS_TYPES, k)
-- end
-- local STRING_REWARDS_TYPES_IDS = table.invert(STRING_REWARDS_TYPES)
-- local REWARDS = {

-- 	{
-- 		{ string = "BEES",      loot = {{"killerbee",   4,  "BEEHIVE_ENABLED" }}    },
--         { string = "HOUNDS",    loot = {{"hound",   2,      "HOUNDMOUND_ENABLED" }} },
--         { string = "SPIDERS",   loot = {{"spider",  3,      "SPIDERDEN_ENABLED" }}  },
--     },

-- 	{ string = "RESOURCES", loot = { {"cutgrass",    1}, {"twigs", 1} }		 },
-- 	{ string = "RESOURCES", loot = { {"cutstone",    1}, {"rope",  1} }		 },
-- 	{ string = "BANANAS",   loot = { {"cave_banana", 2}               }		 },
-- 	{ string = "BANANAS",   loot = { {"bananapop",   2}               }		 },
-- 	{ string = "GOLD",      loot = { {"goldnugget",  2}               }		 },
-- 	{ string = "GOLD",      loot = { {"goldnugget",  8}               }		 },
-- 	{ string = "TREASURE",  loot = { {"redgem",      1}, {"bluegem", 1}, {"goldnugget", 12} }		 },

--     -- Run away prizes, keep at the bottom.
-- 	{
-- 		{ string = "MONKEYS",      loot = {{"powder_monkey",   3}}    }
--     },
-- }
-- local function assertreward(reward, i)
--    	assert(STRINGS.BALATRO.JIMBO_REWARD_TYPES[reward.string] ~= nil, string.format("Reward #%d doesn't have an entry at STRINGS.BALATRO.JIMBO_REWARD_TYPES, please add one. %s = \"TODO\"", i, reward.string or ""))
-- end

-- if BRANCH == "dev" then
--     -- Making sure we have everything we need.
--     assert((#REWARDS-1) == BALATRO_UTIL.MAX_SCORE, string.format("We need score rewards definitions for all ranks/scores! %d rewards ~= %d ranks", #REWARDS-1, BALATRO_UTIL.MAX_SCORE))

--     for i, reward in ipairs(REWARDS) do
--         if reward.string then
-- 			assertreward(reward, i)
--         else
--         	for t,subreward in ipairs(reward)do
--         		assertreward(subreward, i)
--         	end
--     	end
--     end
-- end
-- local function SpawnCardRewards(inst, doer, score, target)
--     for i = 1, score do
--         local range = 2+math.random()*0.5
--         local offset = FindWalkableOffset(target, math.random()*360, range, 16)
--         local newx, newy, newz = (target+offset):Get()

--         local reward = TheWorld.components.playingcardsmanager:MakePlayingCard(nil, true)
--         reward.Transform:SetPosition(newx, newy, newz)

--         local fx = SpawnPrefab("die_fx")
--         fx.Transform:SetPosition(newx, newy, newz)
--         fx.Transform:SetScale(0.5,0.5,0.5)
--     end

--     if score > 5 then
--         local range = 2+math.random()*0.5
--         local offset = FindWalkableOffset(target, math.random()*360, range, 16)
--         local newx, newy, newz = (target+offset):Get()

--         local reward = TheWorld.components.playingcardsmanager:MakePlayingCard(nil, true)
--         reward.Transform:SetPosition(newx, newy, newz)

--         local range = 2+math.random()*0.5
--         local offset = FindWalkableOffset(target, math.random()*360, range, 16)
--         local newx, newy, newz = (target+offset):Get()

--         local record = SpawnPrefab("record")
--         record:SetRecord("balatro")
--         record.Transform:SetPosition(newx, newy, newz)

--         local fx = SpawnPrefab("die_fx")
--         fx.Transform:SetPosition(newx, newy, newz)
--         fx.Transform:SetScale(0.5,0.5,0.5)
--     end

--     BALATRO_UTIL.SetLightMode_Idle(inst)
--     inst.components.activatable.inactive = true
--     inst.rewarding = false
-- end

-- local function SpawnCardRewardSequence(inst, doer, score, target)
--     inst.sg:GoToState("talk")
--     inst.components.talker:Chatter("JIMBO_CARDS")

--     inst:DoTaskInTime(2, SpawnCardRewards, doer, score, target)
-- end

-- local function SpawnRewards(inst, doer, score, loot)
--     local pos = inst:GetPosition()

--     local target = pos

--     local pt = Vector3(doer.Transform:GetWorldPosition())

--     local theta = inst:GetAngleToPoint(pt.x,pt.y,pt.z) * DEGREES
--     local radius = 5

--     local offset = FindWalkableOffset(pos, theta, radius, 1, false, true, nil, false, false)

--     if offset then
--         target = pos + offset
--     end

--     for t=1,loot[2] do
--         local range = 1+math.random()*0,5
--         local offset =  FindWalkableOffset(target, math.random()*360, range, 16)
--         if offset then
--             local reward = SpawnPrefab(loot[1])
--             local newpos = target+offset

--             reward.Transform:SetPosition(newpos.x,newpos.y,newpos.z)
-- 			if loot[1] == "powder_monkey" then
-- 				if reward.components.lootdropper then
-- 					reward.components.lootdropper:SetChanceLootTable(nil)
-- 				end
-- 			end
--             if reward.components.combat then
--                 reward.components.combat:SetTarget(inst.doer)
--             end
--             local fx = SpawnPrefab("die_fx")
--             fx.Transform:SetPosition(newpos.x,newpos.y,newpos.z)
--             fx.Transform:SetScale(0.5,0.5,0.5)
--         end
--     end
-- end

-- local function DoDelayedRewards(inst, doer, score)
-- 	inst.sg:GoToState("talk")

--  	local rewards = REWARDS[score]

--     if rewards.string == nil then
--     	rewards = rewards[math.random(1,#rewards)]
--     end
--     for i=1, #rewards.loot do
--     	local loot = rewards.loot[i]

-- 		local enabled = loot[3] and TUNING[loot[3]] or nil
--    		if enabled == nil or enabled then
-- 			inst.components.talker:Chatter("JIMBO_REWARD_"..score, STRING_REWARDS_TYPES_IDS[rewards.string] or 0)
-- 			inst:DoTaskInTime(2, SpawnRewards, doer, score, loot)
-- 		else
-- 			inst.components.talker:Chatter("JIMBO_NO_REWARD")
-- 		    BALATRO_UTIL.SetLightMode_Idle(inst)
-- 		    inst.components.activatable.inactive = true
-- 		    inst.rewarding = false
-- 		end
-- 	end

--   	local pos = inst:GetPosition()
--     local target = pos
--     local pt = Vector3(doer.Transform:GetWorldPosition())
--     local theta = inst:GetAngleToPoint(pt.x,pt.y,pt.z) * DEGREES
--     local radius = 5
--     local offset = FindWalkableOffset(pos, theta, radius, 1, false, true, nil, false, false)
--     if offset then
--         target = pos + offset
--     end

--   	if score > 3 and score ~= 9 and TheWorld.components.playingcardsmanager then
--         inst:DoTaskInTime(3, SpawnCardRewardSequence, doer, score, target)
--     else
--         BALATRO_UTIL.SetLightMode_Idle(inst)
--         inst.components.activatable.inactive = true
--         inst.rewarding = false
--     end
-- end

-- local function StartRewardsSequence(inst, doer, score)
-- 	inst:DoTaskInTime(1, DoDelayedRewards, doer, score)
-- end
-- local function MakeMachineActivatable(inst)
--     inst.components.activatable.inactive = true
--     inst.rewarding = false
-- end

-- local function NoRewardCallback(inst, line, delay)
--     inst.sg:GoToState("talk")
--     inst.components.talker:Chatter(line)

--     inst:DoTaskInTime(delay or 60, MakeMachineActivatable)
-- end
-- local function EndInteraction(inst, doer)
--     if inst._currentgame.user ~= doer then
--         return -- Not our current user!
--     end

--     local score = inst._currentgame.score

--     if score == nil and inst._currentgame.joker ~= nil then
--         -- Game has started, punish people for running away.
--         score = #REWARDS
--     end

--     BALATRO_UTIL.ServerDebugPrint("Final score: ", nil, nil, score)

--     if score ~= nil and REWARDS[score] ~= nil then
--         BALATRO_UTIL.SetLightMode_Blink(inst)
--         StartRewardsSequence(inst, doer, score)
--     else
--         inst:DoTaskInTime(1, NoRewardCallback, "JIMBO_CLOSED")
--     end

--     inst:RemoveEventCallback("onremove", inst.ondoerremoved, doer)
--     inst:RemoveEventCallback("ms_closepopup", inst.onclosepopup, doer)
--     inst:RemoveEventCallback("ms_popupmessage", inst.onpopupmessage, doer)

--     doer.sg:HandleEvent("ms_endplayingbalatro")

--     inst._currentgame = {}
-- end
-- local function OnClosePopup(inst, doer, data)
--     if data.popup == POPUPS.BALATRO then
--         EndInteraction(inst, doer)
--     end
-- end
-- AddPrefabPostInit("balatro_machine", function(inst)
-- 	 if not TheWorld.ismastersim then return end
-- 	 inst.onclosepopup  = function(doer, data) OnClosePopup(inst, doer, data) end
-- end)

-- AddPrefabPostInit("powder_monkey", function(inst)
-- 	if not TheWorld.ismastersim then return end
-- 	local _onsve = inst.OnSave
-- 	inst.OnSave = function(inst, data, ...)
-- 		if _onsve then _onsve(inst, data, ...) end
-- 		if inst.components.lootdropper and inst.components.lootdropper.chanceloottable ~= nil then
-- 			data.loots = inst.components.lootdropper.chanceloottable
-- 		end
-- 	end
-- 	local _onload = inst.OnLoad
-- 	inst.OnLoad = function(inst, data, ...)
-- 		if _onload then _onload(inst, data, ...) end
-- 		if data and data.loots == nil then
-- 			if inst.components.lootdropper then
-- 				inst.components.lootdropper:SetChanceLootTable(data.loots)
-- 			end
-- 		end
-- 	end
-- end)
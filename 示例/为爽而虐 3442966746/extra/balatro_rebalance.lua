local BALATRO_UTIL = require("prefabs/balatro_util")
local BALATRO_SCORE_UTILS = require("prefabs/balatro_score_utils")
local STRING_REWARDS_TYPES = {}

STRINGS.BALATRO.JIMBO_REWARD_TYPES = {
    BEES = TUNING.isCh2hm and "蜜蜂" or "BEES" ,
    HOUNDS = TUNING.isCh2hm and "猎犬" or "HOUNDS" ,
    MONKEYS = TUNING.isCh2hm and "小猴" or "MONKEYS" ,
    RESOURCES = TUNING.isCh2hm and "资源" or "SUPPLIES" ,
    BANANAS = TUNING.isCh2hm and "香蕉" or "BANANAS",
    GOLD = TUNING.isCh2hm and "黄金" or "GOLD" ,
    TREASURE = TUNING.isCh2hm and "宝藏" or "TREASURE" ,
    SPIDERS = TUNING.isCh2hm and "蜘蛛" or "SPIDERS" ,
} 

for k, v in pairs(STRINGS.BALATRO.JIMBO_REWARD_TYPES) do
    table.insert(STRING_REWARDS_TYPES, k)
end

local STRING_REWARDS_TYPES_IDS = table.invert(STRING_REWARDS_TYPES)



local REWARDS = {

	{
		{ string = "BEES",      loot = {{"killerbee",       4,  "BEEHIVE_ENABLED"     }}  },
        { string = "HOUNDS",    loot = {{"hound",           2,  "HOUNDMOUND_ENABLED"  }}  },
        { string = "MONKEYS",   loot = {{"powder_monkey",   1,  "MONKEYHUT_ENABLED"   }}  },
    },

	{ string = "RESOURCES", loot = {{"cutgrass",    2}, {"twigs",  2}  }   },
	{ string = "RESOURCES", loot = {{"rope",        1}, {"boards", 1}  }   },
	{ string = "BANANAS",   loot = {{"cave_banana", 1}                 }	},
	{ string = "BANANAS",   loot = {{"bananapop",   1}                 }	},
	{ string = "GOLD",      loot = {{"goldnugget",  4}, {"gears", 2 },     {"walrus_tusk", 1   }    }   },
	{ string = "GOLD",      loot = {{"goldnugget",  8}, {"gears", 4 },     {"greengem", 1      }    }   },
	{ string = "TREASURE",  loot = {{"goldnugget", 16}, {"greengem", 1 },  {"redgem", 1 }, {"bluegem", 1 }, 
        {"purplegem", 1 }, {"yellowgem", 1 }, {"orangegem", 1 }, {"opalpreciousgem", 1 },{"krampus_sack",1 }}},  

    -- Run away prizes, keep at the bottom.
	{
		{ string = "BEES",      loot = {{"killerbee",       2,      "BEEHIVE_ENABLED"   }}  },
        { string = "HOUNDS",    loot = {{"hound",           1,      "HOUNDMOUND_ENABLED"}}  },
        { string = "SPIDERS",   loot = {{"spider",          1,      "SPIDERDEN_ENABLED" }}  },
        { string = "MONKEYS",   loot = {{"powder_monkey",   1,      "MONKEYHUT_ENABLED" }}  },
    },
}

local function SpawnCardRewards(inst, doer, score, target)
    for i = 1, score do
        local range = 2+math.random()*0.5
        local offset = FindWalkableOffset(target, math.random()*360, range, 16)
        local newx, newy, newz = (target+offset):Get()

        local reward = TheWorld.components.playingcardsmanager:MakePlayingCard(nil, true)
        reward.Transform:SetPosition(newx, newy, newz)

        local fx = SpawnPrefab("die_fx")
        fx.Transform:SetPosition(newx, newy, newz)
        fx.Transform:SetScale(0.5,0.5,0.5)
    end

    if score > 5 then
        local range = 2+math.random()*0.5
        local offset = FindWalkableOffset(target, math.random()*360, range, 16)
        local newx, newy, newz = (target+offset):Get()

        local reward = TheWorld.components.playingcardsmanager:MakePlayingCard(nil, true)
        reward.Transform:SetPosition(newx, newy, newz)

        local range = 2+math.random()*0.5
        local offset = FindWalkableOffset(target, math.random()*360, range, 16)
        local newx, newy, newz = (target+offset):Get()

        local record = SpawnPrefab("record")
        record:SetRecord("balatro")
        record.Transform:SetPosition(newx, newy, newz)

        local fx = SpawnPrefab("die_fx")
        fx.Transform:SetPosition(newx, newy, newz)
        fx.Transform:SetScale(0.5,0.5,0.5)
    end

    BALATRO_UTIL.SetLightMode_Idle(inst)
    inst.components.activatable.inactive = true
    inst.rewarding = false
end
local function SpawnRewards(inst, doer, score, loot)
    local pos = inst:GetPosition()
    local target = pos
    local pt = Vector3(doer.Transform:GetWorldPosition())
    local theta = inst:GetAngleToPoint(pt.x,pt.y,pt.z) * DEGREES
    local radius = 5
    local offset = FindWalkableOffset(pos, theta, radius, 1, false, true, nil, false, false)
    if offset then
        target = pos + offset
    end
    for t=1,loot[2] do
        local range = 1+math.random()*0.5
        local offset =  FindWalkableOffset(target, math.random()*360, range, 16)
        if offset then
            local reward = SpawnPrefab(loot[1])
            local newpos = target+offset

            reward.Transform:SetPosition(newpos.x,newpos.y,newpos.z)
            if reward:IsValid() and reward.components.combat then            -- 活物仇恨玩家
                local player = FindClosestPlayerToInst(reward, 400, true)
                if player then
                    reward.components.combat:SetTarget(player)
                end
            end
            local fx = SpawnPrefab("die_fx")
            fx.Transform:SetPosition(newpos.x,newpos.y,newpos.z)
            fx.Transform:SetScale(0.5,0.5,0.5)
        end
    end
end

local function SpawnCardRewardSequence(inst, doer, score, target)
    inst.sg:GoToState("talk")
    inst.components.talker:Chatter("JIMBO_CARDS")

    inst:DoTaskInTime(2, SpawnCardRewards, doer, score, target)
end

local function DoDelayedRewards(inst, doer, score)
    -- 奖励冷却控制 
    if not inst.last_reward_time then inst.last_reward_time = 0 end
    local current_time = GetTime()
    if current_time - inst.last_reward_time < 15 then
        inst.sg:GoToState("talk")
        inst.components.talker:Say(TUNING.isCh2hm and "奖励冷却中，请稍后再试。" or 
        "Rewards in cooldown, please try later.")
        BALATRO_UTIL.SetLightMode_Idle(inst)
        inst.components.activatable.inactive = true
        inst.rewarding = false
        return
    else
        inst.last_reward_time = current_time -- 更新冷却时间
    end

	inst.sg:GoToState("talk")

 	local rewards = REWARDS[score]

    if rewards.string == nil then
    	rewards = rewards[math.random(1,#rewards)]
    end
    for i=1, #rewards.loot do
    	local loot = rewards.loot[i]

		local enabled = loot[3] and TUNING[loot[3]] or nil
   		if enabled == nil or enabled then
			inst.components.talker:Chatter("JIMBO_REWARD_"..score, STRING_REWARDS_TYPES_IDS[rewards.string] or 0)
			inst:DoTaskInTime(2, SpawnRewards, doer, score, loot)
		else
			inst.components.talker:Chatter("JIMBO_NO_REWARD")
		    BALATRO_UTIL.SetLightMode_Idle(inst)
		    inst.components.activatable.inactive = true
		    inst.rewarding = false
		end
	end

  	local pos = inst:GetPosition()
    local target = pos
    local pt = Vector3(doer.Transform:GetWorldPosition())
    local theta = inst:GetAngleToPoint(pt.x,pt.y,pt.z) * DEGREES
    local radius = 5
    local offset = FindWalkableOffset(pos, theta, radius, 1, false, true, nil, false, false)
    if offset then
        target = pos + offset
    end

  	if score > 3 and score ~= 9 and TheWorld.components.playingcardsmanager then
        inst:DoTaskInTime(3, SpawnCardRewardSequence, doer, score, target)
    else
        BALATRO_UTIL.SetLightMode_Idle(inst)
        inst.components.activatable.inactive = true
        inst.rewarding = false
    end
end

local function MakeMachineActivatable(inst)
    inst.components.activatable.inactive = true
    inst.rewarding = false
end

local function NoRewardCallback(inst, line, delay)
    inst.sg:GoToState("talk")
    inst.components.talker:Chatter(line)
    inst:DoTaskInTime(delay or 2, MakeMachineActivatable)
end

local function StartRewardsSequence(inst, doer, score)
	inst:DoTaskInTime(1, DoDelayedRewards, doer, score)
end

local function CleanupInteraction(inst, doer)
    inst.components.activatable.inactive = true
    inst.rewarding = false
    inst:RemoveEventCallback("onremove", inst.ondoerremoved, doer)
    inst:RemoveEventCallback("ms_closepopup", inst.onclosepopup, doer)
    inst:RemoveEventCallback("ms_popupmessage", inst.onpopupmessage, doer)
    doer.sg:HandleEvent("ms_endplayingbalatro")
    inst._currentgame = {}
end

local function EndInteraction(inst, doer)
    if inst._currentgame.user ~= doer then
        return -- Not our current user!
    end

    local score = inst._currentgame.score

    if score == nil and inst._currentgame.joker ~= nil then
        -- Game has started, punish people for running away.
        score = #REWARDS
    end

    BALATRO_UTIL.ServerDebugPrint("Final score: ", nil, nil, score)

    if score ~= nil and REWARDS[score] ~= nil then
        BALATRO_UTIL.SetLightMode_Blink(inst)
        StartRewardsSequence(inst, doer, score)
    else
        inst:DoTaskInTime(1, NoRewardCallback, "JIMBO_CLOSED")
    end
    CleanupInteraction(inst, doer)
end


local function OnClosePopup(inst, doer, data)
    if data.popup == POPUPS.BALATRO then
        EndInteraction(inst, doer)
    end
end

local function OnPopupMessage(inst, doer, data)
    if data.popup ~= POPUPS.BALATRO then
        return
    end

    if inst._currentgame.user ~= doer then
        return -- Not our current user!
    end

    local args = data ~= nil and data.args or nil

    if args == nil then
        return -- Invalid data.
    end

    local message_id = args[1]

    if not checkuint(message_id) then
        return -- Invalid data.
    end

    if message_id == BALATRO_UTIL.POPUP_MESSAGE_TYPE.DISCARD_CARDS then
        if inst._currentgame.joker == nil then
            return -- Joker hasn't been choosen yet...
        end

        if inst._currentgame.round >= 3 then
            return -- Game is over, don't accept new discards...
        end

        local byte = args[2]

        if byte == nil or not checkuint(byte) then
            return -- Invalid data.
        end

        inst._currentgame.round = inst._currentgame.round + 1

        local discarddata = BALATRO_UTIL.DecodeDiscardData(byte)

        inst._currentgame.joker:OnCardsDiscarded(discarddata)

        if byte ~= 0 then -- Not a skip.
            inst._currentgame._lastselectedcards = shallowcopy(inst._currentgame.selectedcards)

            for i=1, #discarddata do
                if discarddata[i] == true then
                    inst._currentgame.selectedcards[i] = table.remove(inst._currentgame.carddeck, math.random(#inst._currentgame.carddeck))
                end
            end

            inst._currentgame.joker:OnNewCards(inst._currentgame._lastselectedcards, discarddata)

            local data = {}

            for i=1, #inst._currentgame.selectedcards do
                data[i] = BALATRO_UTIL.AVAILABLE_CARD_IDS[inst._currentgame.selectedcards[i]]
            end

            BALATRO_UTIL.ServerDebugPrint("Sending selection back: ", data)

            -- Send back the new selection.
            POPUPS.BALATRO:SendMessageToClient(doer, BALATRO_UTIL.POPUP_MESSAGE_TYPE.NEW_CARDS, unpack(data))
        end

        if inst._currentgame.round >= 3 then -- Game is over.
            inst._currentgame.score = inst._currentgame.joker:GetFinalScoreRank()
        end

    elseif message_id == BALATRO_UTIL.POPUP_MESSAGE_TYPE.CHOOSE_JOKER then
        local joker_id = args[2]

        if joker_id == nil or not checkuint(joker_id) then
            return -- Invalid data.
        end

        if inst._currentgame.joker ~= nil then
            return -- Invalid, joker already selected!
        end

        if not table.contains(inst._currentgame.jokerchoices, BALATRO_UTIL.AVAILABLE_JOKERS[joker_id]) then
            return -- Invalid, not one of the given options...
        end

        local JokerClass = BALATRO_SCORE_UTILS.JOKERS[BALATRO_UTIL.AVAILABLE_JOKERS[joker_id]]

        inst._currentgame.joker = JokerClass(inst._currentgame.selectedcards)
        inst._currentgame.joker:OnGameStarted()

        BALATRO_UTIL.ServerDebugPrint("Setting up joker: ", nil, { joker_id })
    end
end

local function OnActivated(inst, doer)
	inst.components.talker:ShutUp()

	inst.rewarding = true
	
    inst._currentgame.user = doer
    inst._currentgame.round = 1
    inst._currentgame.joker = nil
    -- 暂时禁用沃特
    repeat
        inst._currentgame.jokerchoices = PickSome(BALATRO_UTIL.NUM_JOKER_CHOICES, shallowcopy(BALATRO_UTIL.AVAILABLE_JOKERS))
    until not table.contains(inst._currentgame.jokerchoices, "wurt")
    inst._currentgame.carddeck = shallowcopy(BALATRO_UTIL.AVAILABLE_CARDS) -- These are card IDs, not IDs.
    inst._currentgame.selectedcards = PickSome(BALATRO_UTIL.NUM_SELECTED_CARDS, inst._currentgame.carddeck) -- These are card IDs, not IDs.
    inst._currentgame._lastselectedcards = shallowcopy(inst._currentgame.selectedcards)

    inst:ListenForEvent("onremove", inst.ondoerremoved, doer)
    inst:ListenForEvent("ms_closepopup", inst.onclosepopup, doer)
    inst:ListenForEvent("ms_popupmessage", inst.onpopupmessage, doer)

    doer.sg:GoToState("playingbalatro", { target = inst })

    if BALATRO_UTIL.DEBUG_MODE then
        local cards = {}
        local jokers = {}

        for i=1, #inst._currentgame.jokerchoices do
            jokers[#jokers+1] = BALATRO_UTIL.AVAILABLE_JOKER_IDS[inst._currentgame.jokerchoices[i]]
        end

        for i=1, #inst._currentgame.selectedcards do
            cards[#cards+1] = BALATRO_UTIL.AVAILABLE_CARD_IDS[inst._currentgame.selectedcards[i]]
        end

        BALATRO_UTIL.ServerDebugPrint("Starting game: ", cards, jokers)
    end
end

-- 削弱奖励
AddPrefabPostInit("balatro_machine", function(inst)
    if not TheWorld.ismastersim then return end
    inst.components.activatable.OnActivate = OnActivated
    inst.ondoerremoved = function(doer)         EndInteraction(inst, doer) end
    inst.onclosepopup  = function(doer, data)   OnClosePopup(inst, doer, data) end
    inst.onpopupmessage = function(doer, data)  OnPopupMessage(inst, doer, data) end
end)


-- AddClassPostConstruct("prefabs/balatro_score_utils", function(self)

--     local old_wendy_onnewcards = self.JOKERS.wendy.OnNewCards

--     -- 重写方法
--     function self.JOKERS.wendy:OnNewCards(oldcards)

--         -- old_wendy_onnewcards(self, oldcards)

--         local base_joker = getmetatable(self) -- 获取基类方法
        
--         for i = 1, BALATRO_UTIL.NUM_SELECTED_CARDS do
--             local oldcard = oldcards[i]
--             local newcard = self.cards[i]
            
--             if oldcard ~= newcard then
--                 local oldsuit = base_joker.GetCardSuitByIndex(self, i, oldcard)
--                 local newsuit = base_joker.GetCardSuitByIndex(self, i, newcard)
                
--                 -- 检查是否符合红心/方块 → 黑桃/梅花的转换
--                 if (oldsuit == SUITS.HEARTS or oldsuit == SUITS.DIAMONDS) and 
--                    (newsuit == SUITS.SPADES or newsuit == SUITS.CLUBS) then
--                     self:AddMult(2)  -- 符合条件则增加2倍数
--                 end
--             end
--         end
--     end
--     -- 沃特的人头牌计算得分时可以乘人头数量，官方代码声明非bug
-- end)

-- 防偷看 - 在选择小丑阶段隐藏牌面
AddClassPostConstruct("widgets/redux/balatrowidget", function(self)
    local old_UpdateCardArt = self.UpdateCardArt

    function self:UpdateCardArt(slot, ...)
        -- 在选择小丑阶段隐藏牌面，防止玩家提前看到牌组
        if self.mode == "joker" then
            return
        end
        return old_UpdateCardArt(self, slot, ...)
    end
end)

-------------------------------------------------------------------------------------

AddPrefabPostInit("deck_of_cards", function(inst)
    if not TheWorld.ismastersim then return end
    -- 小丑牌堆禁止检测战斗状态
    if NON_LIFEFORM_TARGET_TAGS then
        table.insert(NON_LIFEFORM_TARGET_TAGS, 1, "card")
    end
	if not inst:HasTag("card") then inst:AddTag("card") end
    
    local function OnPunched2hm(inst, data)
        if data and data.attacker and data.attacker:IsValid() and data.attacker:HasTag("player") then
            local attacker = data.attacker
            
            -- 记录攻击前的状态
            local pre_stats = {
                health = attacker.components.health.currenthealth,
                sanity = attacker.components.sanity.current,
                hunger = attacker.components.hunger.current
            }
            
            -- 直接废除武神激励值（休闲打牌）
            if attacker.components.singinginspiration and attacker.components.singinginspiration:GetPercent() > 0 then
                attacker.components.singinginspiration:SetInspiration(0)
            end
            
            local function onPunishedInfo(attacker)
                if attacker:HasTag("player") and attacker.sg and attacker.sg.currentstate then
                    attacker.sg:GoToState("hit_darkness")
                end
                if attacker.components.talker then
                    attacker.components.talker:Say(TUNING.isCh2hm and "哪怕在赌局外作弊也要受到惩罚！" or 
                    "Cheating the system costs you vitality!")
                end
            end
            
            -- 延迟检测属性变化并施加惩罚
            attacker:DoTaskInTime(0.01, function()
                if not attacker:IsValid() or attacker.components.health.disable_penalty then
                    return
                end
                
                local post_stats = {
                    health = attacker.components.health.currenthealth,
                    sanity = attacker.components.sanity.current,
                    hunger = attacker.components.hunger.current
                }
                
                local cheated = false
                
                -- 检测并惩罚各种作弊行为
                if post_stats.health > pre_stats.health then
                    attacker.components.health:DoDelta(-10, false, inst.prefab)
                    cheated = true
                end
                
                if post_stats.sanity > pre_stats.sanity then
                    attacker.components.sanity:DoDelta(-10, false, inst.prefab)
                    cheated = true
                end
                
                if post_stats.hunger > pre_stats.hunger then
                    attacker.components.hunger:DoDelta(-10, false, inst.prefab)
                    cheated = true
                end
                
                if cheated then
                    onPunishedInfo(attacker)
                end
            end)
        end
        
        -- 受月灵伤害时消失
        if data and data.attacker and data.attacker:IsValid() and data.attacker:HasTag("brightmare") then
            inst:DoTaskInTime(0.2, inst.Remove)
        end
    end
    inst:ListenForEvent("attacked", OnPunched2hm)
    -- 预留方法方便其他代码访问
    inst.OnPunched2hm = OnPunched2hm
    -- 添加可燃组件
    if not inst.components.fuel then
        inst:AddComponent("fuel")
        inst.components.fuel.fuelvalue = TUNING.SMALL_FUEL

        MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
        MakeSmallPropagator(inst)
    end
end)

AddPrefabPostInit("playing_card", function(inst)
    if not TheWorld.ismastersim then return end
    -- 添加可燃组件
    if not inst.components.fuel then
        inst:AddComponent("fuel")
        inst.components.fuel.fuelvalue = TUNING.SMALL_FUEL

        MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
        MakeSmallPropagator(inst)
    end
end)

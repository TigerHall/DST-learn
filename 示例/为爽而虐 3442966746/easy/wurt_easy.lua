local hardmode = TUNING.hardmode2hm and GetModConfigData("role_nerf")

-- 沃特吃食物收买附近鱼人
if GetModConfigData("Wurt Eat Food Lead Wild Merm") then
    local MERM_TAGS = {"merm"}
    local MERM_IGNORE_TAGS = {"FX", "NOCLICK", "DECOR", "INLIMBO", "player", "swc2hm"}
    local function OnEat(inst, data)
        if data.food ~= nil and data.food.components.edible and inst.components.leader then
            local self = inst.components.leader
            local num = 1
            local max
            if inst.components.hunger.current > 101 then
                max = 1 + math.floor((inst.components.hunger.current - 100) / 2)
                if TUNING.maxfollowernum2hm and self.calculaterepeatfollowers2hm then
                    local followers = self:calculaterepeatfollowers2hm()
                    max = math.min(TUNING.maxfollowernum2hm - #followers, max)
                    if max <= 0 then return end
                end
                num = max
            end
            local hasking = TheWorld.components.mermkingmanager and TheWorld.components.mermkingmanager:HasKing() or false
            local x, y, z = inst.Transform:GetWorldPosition()
            local ents = TheSim:FindEntities(x, y, z, 20, nil, MERM_IGNORE_TAGS, MERM_TAGS)
            for k, v in pairs(ents) do
                if v.components.follower and not v.components.follower.leader then
                    self:AddFollower(v)
                    local isguard = v:HasTag("mermguard")
                    local loyalty_max = isguard and TUNING.MERM_GUARD_LOYALTY_MAXTIME or TUNING.MERM_LOYALTY_MAXTIME
                    local loyalty_per_hunger = isguard and TUNING.MERM_GUARD_LOYALTY_PER_HUNGER or TUNING.MERM_LOYALTY_PER_HUNGER
                    if hasking then
                        loyalty_max = loyalty_max + TUNING.MERM_LOYALTY_MAXTIME_KINGBONUS
                        loyalty_per_hunger = loyalty_per_hunger + TUNING.MERM_LOYALTY_PER_HUNGER_KINGBONUS
                    end
                    local loyalty_count = (isguard and TUNING.MERM_GUARD_FOLLOWER_COUNT or TUNING.MERM_FOLLOWER_COUNT) + 1
                    v.components.follower.maxfollowtime = loyalty_max
                    v.components.follower:AddLoyaltyTime(loyalty_per_hunger * loyalty_count)
                    num = num - 1
                    if num <= 0 then break end
                end
            end
            if max and num ~= max and max - num > 1 then inst.components.hunger:DoDelta(-(max - num - 1) * 2) end
        end
    end
    AddPrefabPostInit("wurt", function(inst)
        if not TheWorld.ismastersim then return end
        inst:ListenForEvent("oneat", OnEat)
        if inst.components.hunger then inst.components.hunger.delayoverflow2hm = true end
    end)
end

-- 沃特吃食物提高鱼人随从忠诚
if GetModConfigData("Wurt Eat Food Loyalty Follower") then
    local function OnEat(inst, data)
        if data.food ~= nil and data.food.components.edible and inst.components.leader then
            local num = 1
            local max
            if inst.components.hunger.current > 151 then
                max = 1 + math.floor((inst.components.hunger.current - 150) / 2)
                num = max
            end
            local hasking = TheWorld.components.mermkingmanager and TheWorld.components.mermkingmanager:HasKing() or false
            for follower, v in pairs(inst.components.leader.followers) do
                if follower:HasTag("merm") and not follower:HasTag("swc2hm") and follower.components.follower and
                        not follower.components.follower.neverexpire and follower.components.follower:GetLoyaltyPercent() < 0.3 then
                    local isguard = follower:HasTag("mermguard")
                    local loyalty_per_hunger = isguard and TUNING.MERM_GUARD_LOYALTY_PER_HUNGER or TUNING.MERM_LOYALTY_PER_HUNGER
                    if hasking then loyalty_per_hunger = loyalty_per_hunger + TUNING.MERM_LOYALTY_PER_HUNGER_KINGBONUS end
                    local loyalty_count = (isguard and TUNING.MERM_GUARD_FOLLOWER_COUNT or TUNING.MERM_FOLLOWER_COUNT) + 1
                    for i = 1, 3, 1 do
                        follower.components.follower:AddLoyaltyTime(loyalty_per_hunger * loyalty_count)
                        num = num - 1
                        if follower.components.follower:GetLoyaltyPercent() >= 0.3 or num <= 0 then break end
                    end
                    if num <= 0 then break end
                end
            end
            if max and num ~= max and max - num > 1 then inst.components.hunger:DoDelta(-(max - num - 1) * 2) end
        end
    end
    AddPrefabPostInit("wurt", function(inst)
        if not TheWorld.ismastersim then return end
        inst:ListenForEvent("oneat", OnEat)
        if inst.components.hunger then inst.components.hunger.delayoverflow2hm = true end
    end)
end

-- 鱼人王不再饥饿
if GetModConfigData("Mermking Won't Hungry") then
    TUNING.MERM_KING_HUNGER_RATE = 0
    AddPrefabPostInit("mermking", function(inst)
        if not TheWorld.ismastersim then return end
        if inst.components.hunger then inst.components.hunger:Pause() end
        inst:ListenForEvent("startstarving", function()
            if inst.components.hunger then
                inst.components.hunger:SetPercent(0.5)
                inst.components.hunger:Pause()
            end
        end)
    end)
end

-- 和普通鱼人交易鱼
if GetModConfigData("Trade Fish with Merm") then
    local trading_items = {
        {prefabs = {"kelp"}, min_count = 2, max_count = 4, reset = false, add_filler = false},
        {prefabs = {"kelp"}, min_count = 2, max_count = 3, reset = false, add_filler = false},
        {prefabs = {"seeds"}, min_count = 4, max_count = 6, reset = false, add_filler = false},
        {prefabs = {"tentaclespots"}, min_count = 1, max_count = 1, reset = false, add_filler = true},
        {prefabs = {"cutreeds"}, min_count = 1, max_count = 2, reset = false, add_filler = true},
        {
            prefabs = {
                -- These trinkets are generally good for team play, but tend to be poor for solo play.
                -- Theme
                "trinket_12", -- Dessicated Tentacle
                "trinket_25", -- Air Unfreshener
                -- Team
                "trinket_1", -- Melted Marbles
                -- Fishing
                "trinket_17", -- Bent Spork
                "trinket_8" -- Rubber Bung
            },
            min_count = 1,
            max_count = 1,
            reset = false,
            add_filler = true
        },
        {
            prefabs = {"durian_seeds", "pepper_seeds", "eggplant_seeds", "pumpkin_seeds", "onion_seeds", "garlic_seeds"},
            min_count = 1,
            max_count = 2,
            reset = false,
            add_filler = true
        }
    }
    local trading_filler = {"seeds", "kelp", "seeds", "seeds"}
    local function OnGivenItem(inst, giver, item)
        if giver.trading_items2hm == nil then giver.trading_items2hm = deepcopy(trading_items) end
        inst.SoundEmitter:PlaySound("dontstarve/common/researchmachine_science_gift_recieve")
        local selected_index = math.random(1, #giver.trading_items2hm)
        local selected_item = giver.trading_items2hm[selected_index]
        local isabigheavyfish = item.components.weighable and item.components.weighable:GetWeightPercent() >= TUNING.WEIGHABLE_HEAVY_WEIGHT_PERCENT or false
        local bigheavyreward = isabigheavyfish and math.random(1, 2) or 0
        local filler_min = 2 -- Not biasing minimum for filler.
        local filler_max = 4 + bigheavyreward
        local reward_count = math.random(selected_item.min_count, selected_item.max_count) + bigheavyreward
        for k = 1, reward_count do
            giver.components.inventory:GiveItem(SpawnPrefab(selected_item.prefabs[math.random(1, #selected_item.prefabs)]), nil, inst:GetPosition())
        end
        if selected_item.add_filler then
            for i = filler_min, filler_max do
                giver.components.inventory:GiveItem(SpawnPrefab(trading_filler[math.random(1, #trading_filler)]), nil, inst:GetPosition())
            end
        end
        if item:HasTag("oceanfish") then
            local goldmin, goldmax, goldprefab = 1, 2, "goldnugget"
            if item.prefab:find("oceanfish_medium_") == 1 then
                goldmin, goldmax = 2, 4
                if item.prefab == "oceanfish_medium_6_inv" or item.prefab == "oceanfish_medium_7_inv" then -- YoT events.
                    goldprefab = "lucky_goldnugget"
                end
            end
            local amt = math.random(goldmin, goldmax) + bigheavyreward
            for i = 1, amt do giver.components.inventory:GiveItem(SpawnPrefab(goldprefab), nil, inst:GetPosition()) end
        end
        -- Cycle out rewards.
        table.remove(giver.trading_items2hm, selected_index)
        if #giver.trading_items2hm == 0 or selected_item.reset then giver.trading_items2hm = deepcopy(trading_items) end
        item:Remove()
    end
    
    -- 鱼类交易逻辑（注意：武器装备功能已在 monster/pigman.lua 中实现）
    AddPrefabPostInit("merm", function(inst)
        if not TheWorld.ismastersim then return end
        if inst.components.trader then
            local onaccept = inst.components.trader.onaccept
            inst.components.trader.onaccept = function(inst, giver, item, ...)
                if onaccept then onaccept(inst, giver, item, ...) end
                -- 鱼类交易（每天一次）
                if (giver:HasTag("merm") or giver:HasTag("mermdisguise")) and 
                   item:HasTag("fish") and 
                   not inst.components.combat:TargetIs(giver) and
                   (inst.fishtradecycle2hm or 0) < TheWorld.state.cycles then
                    inst.fishtradecycle2hm = TheWorld.state.cycles
                    OnGivenItem(inst, giver, item)
                end
            end
        end
    end)
end
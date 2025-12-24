local hardmode = TUNING.hardmode2hm and GetModConfigData("role_nerf")

-- 韦伯吃肉收买蜘蛛
if GetModConfigData("Webber Eat Meat Lead Wild Spider") then
    local function OnEat(inst, data)
        if data.food ~= nil and data.food.components.edible and data.food.components.edible.foodtype == FOODTYPE.MEAT and inst.components.leader then
            local self = inst.components.leader
            local num = 1
            local max
            if inst.components.hunger.current > 102 then
                max = 1 + math.floor((inst.components.hunger.current - 100) / 3)
                if TUNING.maxfollowernum2hm and self.calculaterepeatfollowers2hm then
                    local followers = self:calculaterepeatfollowers2hm()
                    max = math.min(TUNING.maxfollowernum2hm - #followers, max)
                    if max <= 0 then return end
                end
                num = max
            end
            local x, y, z = inst.Transform:GetWorldPosition()
            local ents = TheSim:FindEntities(x, y, z, 20, {"spider"}, {"swc2hm"})
            for k, v in pairs(ents) do
                if v.components.follower and not v.components.follower.leader then
                    self:AddFollower(v)
                    num = num - 1
                    if num <= 0 then break end
                end
            end
            if max and num ~= max and max - num > 1 then inst.components.hunger:DoDelta(-(max - num - 1) * 3) end
        end
    end
    AddPrefabPostInit("webber", function(inst)
        if not TheWorld.ismastersim then return end
        inst:ListenForEvent("oneat", OnEat)
        if inst.components.hunger then inst.components.hunger.delayoverflow2hm = true end
    end)
    local function CanEat(self, food)
        return self:TestFood(food, self.caneat) and
                   (not (self.inst.components.follower and self.inst.components.follower.leader and self.inst.components.follower.leader:HasTag("player")) or
                       (food and food.components.inventoryitem and food.components.inventoryitem.owner ~= nil))
    end
    local function OnStartLeashing(inst, data)
        inst:PushEvent("detachchild")
        if inst.components.homeseeker then
            inst.components.homeseeker:SetHome(nil)
            inst:RemoveComponent("homeseeker")
        end
    end
    AddPrefabPostInitAny(function(inst)
        if not TheWorld.ismastersim then return end
        if inst:HasTag("spider") then
            if inst.components.follower then
                inst.components.follower.keepdeadleader = true
                inst:ListenForEvent("startleashing", OnStartLeashing)
            end
            if inst.components.eater then inst.components.eater.CanEat = CanEat end
        end
    end)
end

-- 韦伯吃涂鸦升级蜘蛛
if GetModConfigData("Webber Eat Switcherdoodle Switch Spider") then
    local function delayprocess(new_spider, inst) if new_spider.components.follower then new_spider.components.follower:SetLeader(inst) end end
    local function delaymutate(spider, inst, self)
        spider.mutation_target = self.mutation_target
        spider.mutator_giver = inst
        spider:PushEvent("mutate")
    end
    local function OnEat(inst, data)
        if data.food ~= nil and data.food:HasTag("spidermutator") and data.food.components.spidermutator and data.food.components.spidermutator.mutation_target and
            inst.components.leader and inst.components.leader.followers then
            local num = 1
            local max
            if inst.components.hunger.current >= 125 then
                max = 1 + math.floor((inst.components.hunger.current - 100) / 25)
                num = max
            end
            local self = data.food.components.spidermutator
            for spider, v in pairs(inst.components.leader.followers) do
                if num > 0 and spider.prefab == "spider" and not spider:HasTag("swc2hm") and spider.components.inventoryitem and
                    spider.components.inventoryitem.owner == nil and data.food.components.spidermutator:CanMutate(spider) then
                    spider:DoTaskInTime(0, delaymutate, inst, self)
                    num = num - 1
                end
            end
            local enablefx = false
            if num > 0 then
                for spider, v in pairs(inst.components.leader.followers) do
                    if num > 0 and spider.prefab == "spider" and not spider:HasTag("swc2hm") and spider.components.inventoryitem and
                        spider.components.inventoryitem.owner == inst and data.food.components.spidermutator:CanMutate(spider) then
                        local container = spider.components.inventoryitem.owner.components.inventory
                        if container then
                            local slot = container:GetItemSlot(spider)
                            container:RemoveItem(spider)
                            spider:DoTaskInTime(0, spider.Remove)
                            local new_spider = SpawnPrefab(self.mutation_target)
                            if new_spider.components.inventoryitem then container:GiveItem(new_spider, slot) end
                            new_spider:DoTaskInTime(0, delayprocess, inst)
                            num = num - 1
                            enablefx = true
                        end
                    end
                end
            end
            if num > 0 then
                for spider, v in pairs(inst.components.leader.followers) do
                    if num > 0 and spider.prefab == "spider" and not spider:HasTag("swc2hm") and spider.components.inventoryitem and
                        spider.components.inventoryitem.owner ~= nil and spider.components.inventoryitem:GetGrandOwner() == inst and
                        data.food.components.spidermutator:CanMutate(spider) then
                        local container = spider.components.inventoryitem.owner.components.container
                        if container and container.canbeopened then
                            local slot = container:GetItemSlot(spider)
                            container:RemoveItem(spider)
                            spider:DoTaskInTime(0, spider.Remove)
                            local new_spider = SpawnPrefab(self.mutation_target)
                            if new_spider.components.inventoryitem then container:GiveItem(new_spider, slot) end
                            new_spider:DoTaskInTime(0, delayprocess, inst)
                            num = num - 1
                            enablefx = true
                        end
                    end
                end
            end
            if enablefx then
                local x, y, z = inst.Transform:GetWorldPosition()
                local fx = SpawnPrefab("spider_mutate_fx")
                fx.Transform:SetPosition(x, y, z)
            end
            if max and num ~= max and max - num > 1 then inst.components.hunger:DoDelta(-(max - num - 1) * 25) end
        end
    end
    AddPrefabPostInit("webber", function(inst)
        if not TheWorld.ismastersim then return end
        inst:ListenForEvent("oneat", OnEat)
    end)
end

-- 韦伯谋杀蜘蛛获得涂鸦
if GetModConfigData("Webber Murder Spider Get Switcherdoodle") then
    local needhunger = GetModConfigData("Webber Murder Spider Get Switcherdoodle")
    local function OnMurdered(inst, data)
        if data.victim ~= nil and data.victim:HasTag("spider") and data.victim.prefab ~= "spider" and inst.components.hunger.current >= 150 and
            string.match(data.victim.prefab, "spider_") then
            local persistentdata = inst.components.persistent2hm.data
            if hardmode and (persistentdata.murderspidercd or 0) >= TheWorld.state.cycles + 1 then return end
            local doodle = SpawnPrefab("mutator_" .. string.sub(data.victim.prefab, 8))
            if doodle ~= nil then
                persistentdata.murderspidercd = math.max(persistentdata.murderspidercd or 0, TheWorld.state.cycles) + 0.15
                inst.components.inventory:GiveItem(doodle)
                inst.components.hunger:DoDelta(-needhunger)
            end
        end
    end
    AddPrefabPostInit("webber", function(inst)
        if not TheWorld.ismastersim then return end
        if not inst.components.persistent2hm then inst:AddComponent("persistent2hm") end
        inst:ListenForEvent("murdered", OnMurdered)
    end)
end

-- 韦伯升级三级蜘蛛巢为女皇
if GetModConfigData("Webber Uprade SpiderDen SpiderQueen") then
    local function OnUpgrade(inst, upgrade_doer)
        inst.SoundEmitter:PlaySound("webber2/common/spiderden_upgrade")
        if inst.components.growable:GetStage() < 3 then
            inst.AnimState:PlayAnimation(inst.anims.hit)
            inst.AnimState:PushAnimation(inst.anims.idle)
        else
            inst.AnimState:PlayAnimation(inst.anims.hit_combat)
            inst.AnimState:PushAnimation(inst.anims.idle)
            inst.components.growable:LongUpdate((inst.components.growable.targettime or 0) / 10 + 150 * (1 + 2 * math.random()))
        end
    end
    local function OnStageAdvance(inst)
        if inst.components.upgradeable.stage == 4 then
            inst.components.upgradeable.stage = 3
            if math.random() < 0.45 then inst.components.growable:DoGrowth() end
        else
            inst.components.growable:DoGrowth()
        end
        return true
    end
    local function oneat(inst, data)
        if inst.components.hunger and inst.components.upgradeable and data then
            for i = 1, 4 do
                if inst:IsValid() and inst.components.hunger then
                    if inst.components.hunger.current >= 50 then
                        inst.components.hunger:DoDelta(-50, nil, true)
                        inst.components.upgradeable.numupgrades = inst.components.upgradeable.numupgrades + 1
                        if inst.components.upgradeable.onupgradefn then
                            inst.components.upgradeable.onupgradefn(inst, data.feeder, data.food)
                        end
                        if inst.components.childspawner then
                            inst.components.childspawner:AddChildrenInside(math.random(1, 3))
                            inst.components.childspawner:SpawnChild()
                        end
                        if inst.components.upgradeable.numupgrades >= inst.components.upgradeable.upgradesperstage then
                            inst.components.upgradeable:AdvanceStage()
                        end
                    else
                        if i == 1 then
                            inst.AnimState:PlayAnimation(inst.anims.hit)
                            inst.AnimState:PushAnimation(inst.anims.idle)
                        end
                        break
                    end
                end
            end
        end
    end
    local DIET = {FOODTYPE.MEAT}
    AddPrefabPostInit("spiderden", function(inst)
        if not TheWorld.ismastersim or not inst.components.upgradeable then return end
        inst.components.upgradeable.numstages = 4
        inst.components.upgradeable.onupgradefn = OnUpgrade
        inst.components.upgradeable.onstageadvancefn = OnStageAdvance
        if hardmode and not inst.components.eater and not inst.components.hunger then
            inst.components.upgradeable.upgradetype = "none"
            inst:AddTag("handfed")
            inst:AddTag("fedbyall")
            inst:AddComponent("eater")
            inst.components.eater:SetDiet(DIET, DIET)
            inst.components.eater:SetCanEatHorrible()
            inst.components.eater:SetStrongStomach(true) -- can eat monster meat!
            inst.components.eater:SetCanEatRawMeat(true)
            inst:AddComponent("hunger")
            inst.components.hunger:SetMax(200)
            inst.components.hunger:SetKillRate(0)
            inst.components.hunger:SetRate(0)
            inst.components.hunger:Pause()
            inst.components.hunger:SetPercent(0)
            inst:StopUpdatingComponent(inst.components.hunger)
            inst:StopWallUpdatingComponent(inst.components.hunger)
            inst:ListenForEvent("oneat", oneat)
        end
    end)
end

-- 韦伯右键自身蛛网恐惧症
if GetModConfigData("Webber Right Self Overcoming Arachnophobia") then
    TUNING.WEBBER_SANITY = TUNING.WILSON_SANITY
    AddReadBookRightSelfAction("webber", "book_web", GetModConfigData("Webber Right Self Overcoming Arachnophobia"),
                               STRINGS.CHARACTERS.WEBBER.ANNOUNCE_CARRAT_ERROR_WALKING)
end

-- 蜘蛛协助工作
if GetModConfigData("Spider Help Work") then
    local BrainCommon = require "brains/braincommon"
    local AssistLeaderDefaults = BrainCommon.AssistLeaderDefaults
    local CHOPparameters, MINEparameters
    AddBrainPostInit("spiderbrain", function(self)
        if self.inst:HasOneOfTags({"spider_warrior", "spider_dropper"}) then
            if hardmode and not self.inst.components.workmultiplier then
                self.inst:AddComponent("workmultiplier")
                self.inst.components.workmultiplier:AddMultiplier(ACTIONS.CHOP, 0.5, "hard2hm")
            end
            local parameters = CHOPparameters
            if parameters == nil then
                parameters = {
                    action = "CHOP" -- Required.
                }
                local Starter = AssistLeaderDefaults.CHOP.Starter
                parameters.starter = function(inst, ...) return not inst.no_targeting and Starter(inst, ...) end
                local KeepGoing = AssistLeaderDefaults.CHOP.KeepGoing
                parameters.keepgoing = function(inst, ...) return not inst.no_targeting and KeepGoing(inst, ...) end
                CHOPparameters = parameters
            end
            local CHOPaction = BrainCommon.NodeAssistLeaderDoAction(self, parameters)
            table.insert(self.bt.root.children, 4, CHOPaction)
        elseif self.inst:HasOneOfTags({"spider_hider", "spider_moon"}) then
            if hardmode and not self.inst.components.workmultiplier then
                self.inst:AddComponent("workmultiplier")
                self.inst.components.workmultiplier:AddMultiplier(ACTIONS.MINE, 0.5, "hard2hm")
            end
            local parameters = MINEparameters
            if parameters == nil then
                parameters = {
                    action = "MINE" -- Required.
                }
                local Starter = AssistLeaderDefaults.MINE.Starter
                parameters.starter = function(inst, ...) return not inst.no_targeting and Starter(inst, ...) end
                local KeepGoing = AssistLeaderDefaults.MINE.KeepGoing
                parameters.keepgoing = function(inst, ...) return not inst.no_targeting and KeepGoing(inst, ...) end
                local MINE_CANT_TAGS = getupvalue2hm(AssistLeaderDefaults.MINE.FindNew, "MINE_CANT_TAGS")
                if MINE_CANT_TAGS ~= nil then
                    local FindNew = AssistLeaderDefaults.MINE.FindNew
                    parameters.finder = function(...)
                        table.insert(MINE_CANT_TAGS, "spiderden")
                        local result = FindNew(...)
                        for i = #MINE_CANT_TAGS, 1, -1 do if MINE_CANT_TAGS[i] == "spiderden" then table.remove(MINE_CANT_TAGS, i) end end
                        return result
                    end
                end
                MINEparameters = parameters
            end
            local MINEaction = BrainCommon.NodeAssistLeaderDoAction(self, parameters)
            table.insert(self.bt.root.children, 4, MINEaction)
        end
    end)
    local function SoundPath(inst, event) return inst:SoundPath(event) end
    AddStategraphState("spider", State {
        name = "work2hm",
        tags = {"busy"},
        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("atk")
        end,
        timeline = {
            TimeEvent(10 * FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "Attack")) end),
            TimeEvent(10 * FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "attack_grunt")) end),
            TimeEvent(25 * FRAMES, function(inst) inst:PerformBufferedAction() end)
        },
        events = {EventHandler("animover", function(inst) inst.sg:GoToState("idle") end)}
    })
    AddStategraphActionHandler("spider", ActionHandler(ACTIONS.CHOP, "work2hm"))
    AddStategraphActionHandler("spider", ActionHandler(ACTIONS.MINE, "work2hm"))
end

-- 帽子戏法
if GetModConfigData("Hat Trick") then
    TUNING.HatTrickDropRate = 0.05
    TUNING.NoFreezePercent = 0.8
    TUNING.NoFireAndScarePercent = 0.9
    TUNING.HatReduceRate = {
        finiteuses = 0.2,
        armor = 0.1,
        fueled = 0.02,
        perishable = 0.02,
    }
    AddComponentPostInit("follower", function(self)
        local oldSetLeader = self.SetLeader
        function self:SetLeader(new_leader)
            if self.leader then
                -- print(tostring(self.leader) .. " removefollower " .. tostring(self.inst))
                self.leader:PushEvent("removefollower", {follower = self.inst})
            end
            if new_leader then
                -- print(tostring(new_leader) .. " addfollower " .. tostring(self.inst))
                new_leader:PushEvent("addfollower", {follower = self.inst})
            end
            return oldSetLeader(self, new_leader)
        end
    end)
    AddPrefabPostInit("webber", function(inst)
        if not TheWorld.ismastersim then return end
        inst:AddComponent("hattrickparent2hm")
    end)
end
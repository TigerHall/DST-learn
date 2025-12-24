require "behaviours/follow"
local attackspeedup = GetModConfigData("extra_change") and GetModConfigData("boss_attackspeed") or 1
local dens = {"spiderden", "spiderden_2", "spiderden_3"}
local spidermode = GetModConfigData("spider")

local function killselftocallchild(inst, target)
    if inst.disableotherspider2hm or inst.killed2hm then return end
    if inst.components.childspawner:NumChildren() <= 0 and not inst:IsAsleep() and inst.components.shaveable and inst.components.shaveable.on_shaved then
        inst.disableotherspider2hm = (inst.data and inst.data.stage or 1) == 1
        -- 生成一个白蜘蛛防卫
        local spider = SpawnPrefab("spider_dropper")
        spider.Transform:SetPosition(inst.Transform:GetWorldPosition())
        if spider.components.knownlocations then spider.components.knownlocations:RememberLocation("home", inst:GetPosition()) end
        if target ~= nil and spider.components.combat ~= nil then spider.components.combat:SetTarget(target) end
        if inst.components.lootdropper and not inst.disableotherspider2hm then
            inst.components.lootdropper:SpawnLootPrefab("silk")
            inst.components.lootdropper:SpawnLootPrefab("silk")
        end
        -- 掉1级，如果1级会直接杀死巢穴,巢穴被杀死时会掉落1个蜘蛛丝
        inst.components.shaveable.on_shaved(inst, target)
        -- 如果掉1级后还有等级，新等级召唤所有蜘蛛进行防卫
        if inst and inst:IsValid() and not inst.disableotherspider2hm then inst.components.combat.onhitfn(inst, target) end
    else
        inst.components.combat.onhitfn(inst, target)
    end
end

local function onchildkilledfn(inst, child)
    if inst.components.childspawner and inst.components.combat and child and child:IsValid() and child.components.health and child.components.health:IsDead() and
        child.components.combat and child.components.combat.target then
        inst:DoTaskInTime(0, killselftocallchild, child.components.combat.target)
    end
end

local function OnKilled(inst, attacker)
    -- 自己掉级的不会生成白蜘蛛防卫
    if inst.disableotherspider2hm or inst.killed2hm then return end
    inst.killed2hm = true
    for i = 1, (inst.data and inst.data.stage or 1) do
        local spider = SpawnPrefab("spider_dropper")
        spider.Transform:SetPosition(inst.Transform:GetWorldPosition())
        if attacker ~= nil and spider.components.combat ~= nil then spider.components.combat:SetTarget(attacker) end
    end
end

for index, den in ipairs(dens) do
    AddPrefabPostInit(den, function(inst)
        if not TheWorld.ismastersim then return end
        inst.data = inst.data or {}
        inst.data.stage = inst.data.stage or 1
        if inst.components.childspawner and not inst.components.childspawner.onchildkilledfn then
            inst.components.childspawner:SetOnChildKilledFn(onchildkilledfn)
        end
        if inst.components.combat and not inst.components.combat.onkilledbyother then inst.components.combat.onkilledbyother = OnKilled end
    end)
end

-- 蜘蛛女王和寡妇进食
local SEE_FOOD_DIST = 12
local EATFOOD_CANT_TAGS = {"outofreach", "INLIMBO"}
local function EatFoodAction(inst)
    if inst.sg:HasStateTag("busy") then return end
    inst.food2hm = FindEntity(inst, SEE_FOOD_DIST, function(item) return inst.components.eater:CanEat(item) and item:IsOnValidGround() end, nil,
                              EATFOOD_CANT_TAGS)
    return inst.food2hm ~= nil and BufferedAction(inst, inst.food2hm, ACTIONS.ACTION2HM) or nil
end

local function spiderdelaytaunt(inst)
    if inst.sg and not inst:IsInLimbo() and inst.components.health and not inst.components.health:IsDead() then inst.sg:GoToState("taunt") end
end
-- 蜘蛛女王生成的蜘蛛会立即跳到敌人脸上

local function onspiderqueeneat(inst, data)
    if data and data.feeder and data.feeder:IsValid() then
        inst.feeder2hm = data.feeder
        if inst.feedfollow2hmtask then inst.feedfollow2hmtask:Cancel() end
        inst.feedfollow2hmtask = inst:DoTaskInTime(30, function() inst.feedfollow2hmtask = nil end)
        if inst.sg and not inst.sg:HasStateTag("busy") then inst.sg:GoToState("taunt") end
    end
    local mutation_target = data and data.food and data.food:HasTag("spidermutator") and data.food.components.spidermutator and
                                data.food.components.spidermutator.mutation_target
    if inst.components.hunger and (mutation_target or inst.components.hunger:GetPercent() >= 0.9) and inst.components.lootdropper and inst.components.leader and
        inst.components.leader.numfollowers < 10 then
        inst.components.hunger:DoDelta(-25, nil, true)
        local chance = math.random()
        local prefab = mutation_target or (chance > 0.6 and "spider" or (chance > 0.3 and "spider_warrior" or "spider_healer"))
        local spider = inst.components.lootdropper:SpawnLootPrefab(prefab)
        if spider ~= nil then
            local angle = (inst.Transform:GetRotation() + 180) * DEGREES
            local rad = spider:GetPhysicsRadius(0) + inst:GetPhysicsRadius(0) + .25
            local x, y, z = inst.Transform:GetWorldPosition()
            spider.Transform:SetPosition(x + rad * math.cos(angle), 0, z - rad * math.sin(angle))
            spider.sg:GoToState("taunt")
            inst.components.leader:AddFollower(spider)
            if inst.components.combat.target ~= nil then spider.components.combat:SetTarget(inst.components.combat.target) end
        end
    end
end
AddPrefabPostInit("spiderqueen", function(inst)
    if not TheWorld.ismastersim then return end
    if inst.components.lootdropper then
        local oldSpawnLootPrefab = inst.components.lootdropper.SpawnLootPrefab
        inst.components.lootdropper.SpawnLootPrefab = function(inst, ...)
            local loot = oldSpawnLootPrefab(inst, ...)
            if loot and loot:HasTag("spider") and loot.sg then loot:DoTaskInTime(0, spiderdelaytaunt) end
            return loot
        end
    end
    if not inst.components.hunger then
        inst:AddTag("handfed")
        inst:AddTag("fedbyall")
        inst:AddComponent("hunger")
        inst.components.hunger:SetMax(200)
        inst.components.hunger:SetKillRate(0)
        inst.components.hunger:SetRate(TUNING.WILSON_HUNGER_RATE / 10)
        inst:ListenForEvent("oneat", onspiderqueeneat)
        if inst.GetTimeAlive then
            inst.GetTimeAlive2hm = inst.GetTimeAlive
            local GetTimeAlive = inst.GetTimeAlive
            inst.GetTimeAlive = function(self, ...)
                return (inst.components.hunger and inst.components.hunger.current > 0 or inst:HasTag("swc2hm")) and
                           math.clamp(GetTimeAlive(self, ...), 0, TUNING.SPIDERQUEEN_MINWANDERTIME) or GetTimeAlive(self, ...)
            end
        end
    end
end)
AddBrainPostInit("spiderqueenbrain", function(self)
    if self.bt.root and self.bt.root.children then
        table.insert(self.bt.root.children, 5, Follow(self.inst, function() return self.inst.feeder2hm end, 2, 6, 10))
        table.insert(self.bt.root.children, 4, DoAction(self.inst, function() return EatFoodAction(self.inst) end))
    end
end)
AddStategraphActionHandler("spiderqueen", ActionHandler(ACTIONS.ACTION2HM, "eat2hm"))
local function eatfood2hm(inst)
    if inst.food2hm and inst.food2hm:IsValid() and inst.food2hm:IsOnValidGround() and inst.food2hm:IsNear(inst, 4) then
        if inst.components.eater and inst.components.eater:CanEat(inst.food2hm) then
            inst.components.eater:Eat(inst.food2hm)
        else
            inst.food2hm:Remove()
        end
        inst.food2hm = nil
    end
    inst.sg:GoToState("idle")
end
AddStategraphState("spiderqueen", State {
    name = "eat2hm",
    tags = {"busy"},
    onenter = function(inst)
        inst.Physics:Stop()
        inst.AnimState:PlayAnimation("poop_pre")
        inst.AnimState:PushAnimation("poop_pst", false)
        inst:ClearBufferedAction()
        inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/scream")
    end,
    timeline = {TimeEvent(24 * FRAMES, eatfood2hm)},
    events = {EventHandler("animqueueover", eatfood2hm)}
})
AddStategraphPostInit("spider", function(sg)
    local oldtauntonenter = sg.states.taunt.onenter
    sg.states.taunt.onexit = function(inst, ...)
        if inst.components.follower and inst.components.follower.leader and inst.components.follower.leader:IsValid() and inst.components.follower.leader.prefab ==
            "spiderqueen" and inst.components.combat and inst.components.follower.leader.components.combat and
            (inst.components.combat.target or inst.components.follower.leader.components.combat.target) then
            inst.spiderqueenjump2hm = not inst.spiderqueenjump2hm
            if inst.spiderqueenjump2hm then
                inst.sg:GoToState("warrior_attack", inst.components.combat.target or inst.components.follower.leader.components.combat.target)
                return
            end
        end
        oldtauntonenter(inst, ...)
    end
end)

-- =====================================================================
-- 黑寡妇和蜘蛛女王吃东西
if TUNING.DSTU and spidermode ~= -1 then
    -- 妥协黑寡妇,攻速和AI提高,但会导致技能放不出来,所以修改ai和sg
    if attackspeedup < 1.33 then TUNING.SPIDERQUEEN_ATTACKPERIOD = TUNING.SPIDERQUEEN_ATTACKPERIOD * 3 / 4 * attackspeedup end
    local function EquipWeapon(inst, weapon)
        if weapon and weapon:IsValid() and weapon.components.equippable and not weapon.components.equippable:IsEquipped() and inst.components.inventory then
            inst.components.inventory:Equip(weapon)
        end
    end
    local neardist = 144
    local awaydist = 400
    
    -- 回家动作
    local function JumpHomeAction(inst)
        local home = inst.components.homeseeker ~= nil and inst.components.homeseeker.home or nil
        return home ~= nil
            and home:IsValid()
            and home.components.childspawner ~= nil
            and (home.components.health == nil or not home.components.health:IsDead())
            and inst.sg:GoToState("jumphome")
            or nil
    end
    
    -- 黑寡妇的远程攻击AI被替换
    AddBrainPostInit("hoodedwidowbrain", function(self)
        if self.bt.root and self.bt.root.children then
            -- 兼容新旧版本，不再检查period
            if self.bt.root.period == 2 then
                self.bt.root.period = 1
            end
            
            -- 修复妥注释掉的回家逻辑：离家太远时强制回家且设置为最高优先级
            local gohome_node = WhileNode(
                function() return self.inst.bullier end,
                "Being Bullied or Too Far",
                DoAction(self.inst, JumpHomeAction)
            )
            table.insert(self.bt.root.children, 1, gohome_node)
            
            -- 检查是否需要远程攻击
            local function ShouldRangeAttack(inst)
                if not inst.sg or not inst.components.combat then return false end
                local target = inst.components.combat.target
                if not target or not target:IsValid() then return false end
                if inst.sg.currentstate and inst.sg.currentstate.name == "launchprojectile" then return true end
                if inst.sg:HasStateTag("busy") then return false end
                local distsq = inst:GetDistanceSqToInst(target)
                return distsq > neardist and distsq < awaydist
            end
            
            local newaction = WhileNode(function()
                return ShouldRangeAttack(self.inst)
            end, "Attack not Near", SequenceNode(
                {ActionNode(function() EquipWeapon(self.inst, self.inst.weaponitems.snotbomb) end, "Equip thrower"), ChaseAndAttack(self.inst)}))
            
            -- 远程攻击节点插入到第2位
            table.insert(self.bt.root.children, 2, newaction)
            
            -- 不删除妥协模组的节点，妥协新版已有完善的回家逻辑
            -- 添加进食行为，插入到合适位置（在Wander之前）
            local eat_inserted = false
            for i, node in ipairs(self.bt.root.children) do
                if node.name and (node.name:find("Wander") or node.name == "No Target") then
                    table.insert(self.bt.root.children, i, DoAction(self.inst, function() return EatFoodAction(self.inst) end))
                    eat_inserted = true
                    break
                end
            end
            if not eat_inserted then
                table.insert(self.bt.root.children, DoAction(self.inst, function() return EatFoodAction(self.inst) end))
            end
        end
    end)
    AddStategraphActionHandler("hoodedwidow", ActionHandler(ACTIONS.ACTION2HM, "eat2hm"))
    AddStategraphPostInit("hoodedwidow", function(sg)
        local launchprojectile = sg.states.launchprojectile.onenter
        sg.states.launchprojectile.onenter = function(inst, ...)
            if inst.components.combat and inst.components.combat.target and inst.components.combat.target:IsValid() and inst.components.timer then
                if not inst.components.timer:TimerExists("pounce") then
                    EquipWeapon(inst, inst.weaponitems.meleeweapon)
                    inst.sg:GoToState("preleapattack")
                    return
                elseif not inst.components.timer:TimerExists("mortar") and inst.components.combat.target:IsNear(inst, 15) then
                    EquipWeapon(inst, inst.weaponitems.meleeweapon)
                    inst.sg:GoToState("lobprojectile")
                    return
                end
            end
            launchprojectile(inst, ...)
        end
        local attack = sg.states.attack.onenter
        sg.states.attack.onenter = function(inst, ...)
            local weapon = inst.components.combat and inst.components.combat:GetWeapon()
            if weapon and not weapon:HasTag("snotbomb") and inst.components.timer then
                if not inst.components.timer:TimerExists("pounce") then
                    inst.sg:GoToState("preleapattack")
                    return
                elseif not inst.components.timer:TimerExists("mortar") then
                    inst.sg:GoToState("lobprojectile")
                    return
                end
            end
            attack(inst, ...)
        end
        local leapattack = sg.states.leapattack.onenter
        sg.states.leapattack.onenter = function(inst, ...)
            leapattack(inst, ...)
            if inst.components.combat.target and inst.components.combat.target:IsValid() then
                local dist = math.sqrt(inst:GetDistanceSqToInst(inst.components.combat.target))
                inst.components.locomotor:Stop()
                inst.Physics:SetMotorVelOverride(math.min(dist * 1.5, 20), 0, 0)
            end
        end
        if sg.states.lobprojectile.timeline then
            for key, timeevent in pairs(sg.states.lobprojectile.timeline) do
                local fn = timeevent.fn
                timeevent.fn = function(inst, ...)
                    EquipWeapon(inst, inst.weaponitems.meleeweapon)
                    fn(inst, ...)
                end
            end
        end
    end)
    AddStategraphState("hoodedwidow", State {
        name = "eat2hm",
        tags = {"busy"},
        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("shoot_pre")
            inst.AnimState:PushAnimation("shoot_pst", false)
            inst:ClearBufferedAction()
            inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/scream")
        end,
        timeline = {TimeEvent(24 * FRAMES, eatfood2hm)},
        events = {EventHandler("animqueueover", eatfood2hm)}
    })
    -- 半血时生成一批妥协蜘蛛袭击玩家
    local function processspider(inst, hoodedwidow)
        inst.hoodedwidow2hm = hoodedwidow or (inst.swp2hm and inst.swp2hm.hoodedwidow2hm)
        inst:AddTag("queensstuff")
        inst.persists = false
        inst.OnEntitySleep = inst.Remove
        local self = inst.components.combat
        local oldCanHitTarget = self.CanHitTarget
        self.CanHitTarget = function(self, target, ...) return target and oldCanHitTarget(self, target, ...) and not target:HasTag("hoodedwidow") end
        local oldIsValidTarget = self.IsValidTarget
        self.IsValidTarget = function(self, target, ...) return target and oldIsValidTarget(self, target, ...) and not target:HasTag("hoodedwidow") end
        if inst.components.follower and inst.hoodedwidow2hm and inst.hoodedwidow2hm:IsValid() then
            inst.components.follower:SetLeader(inst.hoodedwidow2hm)
        end
    end
    local function onhalfhealth(inst)
        if inst.components.combat and inst.components.combat.target then
            for i = 1, 3, 1 do
                local spider = SpawnMonster2hm(inst.components.combat.target, "spider_trapdoor", 20)
                if spider then
                    spider.swc2hmfn = processspider
                    processspider(spider, inst)
                end
            end
        end
    end
    local DIET = {FOODTYPE.MEAT}
    AddPrefabPostInit("hoodedwidow", function(inst)
        if not TheWorld.ismastersim then return end
        if inst.components.healthtrigger then inst.components.healthtrigger:AddTrigger(0.50031, onhalfhealth) end
        if inst.components.groundpounder and inst.components.groundpounder.noTags then table.insert(inst.components.groundpounder.noTags, "queensstuff") end
        -- 蛛网射线射程提高到36,但只会在20距离内释放,且飞行距离改为50
        if inst.weaponitems and inst.weaponitems.snotbomb and inst.weaponitems.snotbomb:IsValid() and inst.weaponitems.snotbomb.components.weapon then
            inst.weaponitems.snotbomb.components.weapon:SetRange(TUNING.SPAT_PHLEGM_ATTACKRANGE * 3)
        end
        if not inst.components.eater then
            inst:AddComponent("eater")
            inst.components.eater:SetDiet(DIET, DIET)
            inst.components.eater:SetCanEatHorrible()
            inst.components.eater:SetStrongStomach(true) -- can eat monster meat!
            inst.components.eater:SetCanEatRawMeat(true)
        end
    end)
    -- 蜘蛛网范围变大
    AddPrefabPostInit("widow_web_combat", function(inst)
        if inst.GroundCreepEntity then inst.GroundCreepEntity:SetRadius(4) end
        if not TheWorld.ismastersim then return end
        if inst.components.health then inst.components.health:SetMaxHealth(150) end
    end)
    -- 控制技能增强;如果被重复控制则后续控制不触发该效果
    AddPrefabPostInit("web_bomb", function(inst)
        if not TheWorld.ismastersim then return end
        if inst.components.projectile and not inst.components.projectile.range then inst.components.projectile:SetRange(50) end
    end)
    local function unstickself(inst)
        if not inst.hwuppintask2hm and not inst.delayhwuppintask2hmtask2hm and inst.components.pinnable and
            not (inst.components.health and inst.components.health:IsDead()) then inst.components.pinnable:Unstick() end
    end
    local function Unsticknewstate(inst, data)
        inst:RemoveEventCallback("newstate", Unsticknewstate)
        if data and data.statename ~= "death" and inst.components.pinnable and inst.splashprefabs2hm and
            not (inst.components.health and inst.components.health:IsDead()) then
            inst.components.pinnable:Stick("web_net_trap", inst.splashprefabs2hm)
            inst.components.pinnable.last_stuck_time = inst.laststucktime2hm or GetTime()
            inst:DoTaskInTime(1, unstickself)
        end
        inst.splashprefabs2hm = nil
        inst.laststucktime2hm = nil
        if inst.delayhwuppintask2hmtask2hm then
            inst.delayhwuppintask2hmtask2hm:Cancel()
            inst.delayhwuppintask2hmtask2hm = nil
        end
    end
    local function calcedelayhwuppintask2hmtask2hm(inst)
        inst.delayhwuppintask2hmtask2hm = nil
        inst.splashprefabs2hm = nil
        inst.laststucktime2hm = nil
    end
    local function cancelhwuppintask2hm(inst)
        inst.hwuppintask2hm = nil
        if inst.splashprefabs2hm then
            if not inst.delayhwuppintask2hmtask2hm and inst.continuestick2hm and not (inst.components.health and inst.components.health:IsDead()) then
                inst.delayhwuppintask2hmtask2hm = inst:DoTaskInTime(5, calcedelayhwuppintask2hmtask2hm)
                inst:ListenForEvent("newstate", Unsticknewstate)
            else
                inst.splashprefabs2hm = nil
                inst.laststucktime2hm = nil
            end
        end
        if inst.continuestick2hm then inst.continuestick2hm = nil end
        if TheWorld.FindFirstEntityWithTagtmp2hm then
            getmetatable(TheSim).__index["FindFirstEntityWithTag"] = TheWorld.FindFirstEntityWithTagtmp2hm
            TheWorld.FindFirstEntityWithTagtmp2hm = nil
        end
    end
    AddComponentPostInit("pinnable", function(self)
        local Stick = self.Stick
        self.Stick = function(self, goo_build, splashprefabs, ...)
            if goo_build and goo_build == "web_net_trap" and not self.inst.splashprefabs2hm and
                not (self.inst.components.health and self.inst.components.health:IsDead()) then
                if self.inst.hwuppintask2hm then self.inst.hwuppintask2hm:Cancel() end
                if TheWorld.FindFirstEntityWithTagtmp2hm then
                    getmetatable(TheSim).__index["FindFirstEntityWithTag"] = TheWorld.FindFirstEntityWithTagtmp2hm
                    TheWorld.FindFirstEntityWithTagtmp2hm = nil
                end
                self.inst.hwuppintask2hm = self.inst:DoTaskInTime(4, cancelhwuppintask2hm)
                self.inst.splashprefabs2hm = splashprefabs
                self.inst.laststucktime2hm = GetTime()
            end
            return Stick(self, goo_build, splashprefabs, ...)
        end
        local Unstick = self.Unstick
        self.Unstick = function(self, ...)
            Unstick(self, ...)
            if self.inst.hwuppintask2hm then
                self.inst.hwuppintask2hm:Cancel()
                self.inst.hwuppintask2hm = self.inst:DoTaskInTime(0, cancelhwuppintask2hm)
                local FindFirstEntityWithTag = TheWorld.FindFirstEntityWithTagtmp2hm or getmetatable(TheSim).__index["FindFirstEntityWithTag"]
                TheWorld.FindFirstEntityWithTagtmp2hm = FindFirstEntityWithTag
                getmetatable(TheSim).__index["FindFirstEntityWithTag"] = function(_self, tag, ...)
                    if tag == "widowweb" and self.inst:IsValid() then
                        self.inst.continuestick2hm = true
                        if TheWorld.FindFirstEntityWithTagtmp2hm then
                            getmetatable(TheSim).__index["FindFirstEntityWithTag"] = TheWorld.FindFirstEntityWithTagtmp2hm
                            TheWorld.FindFirstEntityWithTagtmp2hm = nil
                        end
                        tag = "hoodedwidow"
                    end
                    return FindFirstEntityWithTag(_self, tag, ...)
                end
            end
        end
    end)
    local function canceltmpSpawnPrefab2hm(inst)
        if TheWorld.tmpSpawnPrefab2hm then
            GLOBAL.SpawnPrefab = TheWorld.tmpSpawnPrefab2hm
            TheWorld.tmpSpawnPrefab2hm = nil
        end
    end
    local function cancelhealthkill(inst)
        if inst.tempKill2hm then
            if inst.components.health then inst.components.health.Kill = inst.tempKill2hm end
            inst.tempKill2hm = nil
        end
    end
    -- 减少蜘蛛茧额外掉落
    AddPrefabPostInit("webbedcreature", function(inst)
        if not TheWorld.ismastersim then return end
        if inst.components.lootdropper then
            local DropLoot = inst.components.lootdropper.DropLoot
            inst.components.lootdropper.DropLoot = function(self, ...)
                local chance = math.random()
                if not TheWorld.tmpSpawnPrefab2hm then
                    TheWorld:DoTaskInTime(0, canceltmpSpawnPrefab2hm)
                    local _SpawnPrefab = GLOBAL.SpawnPrefab
                    TheWorld.tmpSpawnPrefab2hm = _SpawnPrefab
                    GLOBAL.SpawnPrefab = function(name, ...)
                        local ent = _SpawnPrefab(name, ...)
                        if ent.components.health and chance < 0.25 then
                            if ent:IsValid() and ent.components.combat then            -- 活物仇恨玩家
                                local player = FindClosestPlayerToInst(ent, 400, true)
                                if player then
                                    ent.components.combat:SetTarget(player)
                                end
                            end
                            ent:DoTaskInTime(0, cancelhealthkill)
                            local Kill = ent.components.health.Kill
                            ent.tempKill2hm = Kill
                            ent.components.health.Kill = function(_self, ...) _self:SetPercent(chance * 4) end
                        end
                        return ent
                    end
                end
                -- 0.5概率减少额外掉落,0.5概率正常额外掉落,蜘蛛丝除保底外减少部分掉落概率
                if self.chanceloot and chance < 0.5 then
                    local firstsilk
                    for i = #self.chanceloot, 1, -1 do
                        if self.chanceloot[i].prefab ~= "silk" then
                            table.remove(self.chanceloot, i)
                        elseif not firstsilk and self.chanceloot[i].chance >= 1 then
                            firstsilk = true
                        else
                            self.chanceloot[i].chance = self.chanceloot[i].chance * chance
                        end
                    end
                end
                return DropLoot(self, ...)
            end
        end
    end)
    -- 触手尖刺可以扎破蜘蛛卵
    local function tentaclespikeattackwebbedcreature(target, inst)
        if target.components.health and not target.components.health:IsDead() then 
            target.components.health:Kill() 
        end
    end
    local function ontentaclespikeattack(inst, attacker, target)
        if target and target:IsValid() and target:HasTag("webbedcreature") and 
        inst.components.finiteuses and inst.components.finiteuses:GetPercent() > 0 then
            inst.components.finiteuses:SetUses(0) 
            --2/3的概率失败
            if math.random() < 1/3 then target:DoTaskInTime(0, tentaclespikeattackwebbedcreature,inst) end
        end
    end
    AddPrefabPostInit("tentaclespike", function(inst)
        if not TheWorld.ismastersim then return end
        if inst.components.weapon and not inst.components.weapon.onattack and inst.components.finiteuses then
            inst.components.weapon:SetOnAttack(ontentaclespikeattack)
        end
    end)
end

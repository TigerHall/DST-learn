local plant_change = GetModConfigData("plant_change")
if plant_change == false then return end
local changeIndex = (plant_change == -1 or plant_change == true) and 3 or plant_change
local epicchangeindex = (changeIndex - 1) * 3 / 14 + 1
local else_changeIndex = math.max(changeIndex / 2, 1)

TUNING.PINECONE_GROWTIME.base = TUNING.PINECONE_GROWTIME.base * plant_change
TUNING.PINECONE_GROWTIME.random = TUNING.PINECONE_GROWTIME.random * plant_change
TUNING.GRASSGEKKO_REGROW_TIME = TUNING.GRASSGEKKO_REGROW_TIME * plant_change
TUNING.GRASSGATOR_SHEDTIME_SET = TUNING.GRASSGATOR_SHEDTIME_SET * plant_change
TUNING.GRASSGATOR_SHEDTIME_VAR = TUNING.GRASSGATOR_SHEDTIME_VAR * plant_change

-- 蘑菇农场1.5倍生长
TUNING.MUSHROOMFARM_FULL_GROW_TIME = TUNING.MUSHROOMFARM_FULL_GROW_TIME * 3/16

-- 大理石3倍生长
TUNING.MARBLESHRUB_GROW_TIME[1].base = TUNING.MARBLESHRUB_GROW_TIME[1].base * 3/8
TUNING.MARBLESHRUB_GROW_TIME[1].random = TUNING.MARBLESHRUB_GROW_TIME[1].random * 3/8
TUNING.MARBLESHRUB_GROW_TIME[2].base = TUNING.MARBLESHRUB_GROW_TIME[2].base * 3/8
TUNING.MARBLESHRUB_GROW_TIME[2].random = TUNING.MARBLESHRUB_GROW_TIME[2].random * 3/8
-- 三阶段后仍然为8倍
-- TUNING.MARBLESHRUB_GROW_TIME[3].base = TUNING.MARBLESHRUB_GROW_TIME[3].base * 3/8
-- TUNING.MARBLESHRUB_GROW_TIME[3].random = TUNING.MARBLESHRUB_GROW_TIME[3].random * 3/8

local function isNeedPlant(inst)
    return not inst:HasTag("animal") and not inst:HasTag("spiderden") and not inst:HasTag("farm_plant") and inst.prefab ~= "oceantree" and
               not (inst.TransferPlantData and (inst.type == "gem" or inst.type == "nightvision"))
end

-- 生长变慢
local function processgrowablestages(self)
    if self.stages then
        for index, stage in ipairs(self.stages) do
            if stage.processd2hm then break end
            stage.processd2hm = true
            if stage.time and type(stage.time) == "function" then
                local oldtime = stage.time
                stage.time = function(...)
                    local time = oldtime(...)
                    return time and time * changeIndex
                end
            end
        end
    end
end
AddComponentPostInit("growable", function(self)
    local oldStartGrowing = self.StartGrowing
    self.StartGrowing = function(self, time, ...)
        if isNeedPlant(self.inst) then
            if time and time > 0 and not (self.stages and self.stages[self.stage] and self.stages[self.stage].time) then time = time * changeIndex end
            processgrowablestages(self)
        end
        oldStartGrowing(self, time, ...)
    end
end)

local function processpickable(inst, self)
    if self.getregentimefn and type(self.getregentimefn) == "function" then
        local old = self.getregentimefn
        self.getregentimefn = function(inst, ...) return old(inst, ...) * changeIndex end
    end
end
AddComponentPostInit("pickable", function(self)
    local oldSetUp = self.SetUp
    self.SetUp = function(self, product, regen, number, ...)
        if regen and regen > 0 then regen = regen * changeIndex end
        oldSetUp(self, product, regen, number, ...)
    end
    self.inst:DoTaskInTime(0, processpickable, self)
end)

AddComponentPostInit("harvestable", function(self)
    local oldSetGrowTime = self.SetGrowTime
    self.SetGrowTime = function(self, time, ...)
        if time and time > 0 then 
            time = time * changeIndex 
        end
        oldSetGrowTime(self, time, ...)
    end
    local oldStartGrowing = self.StartGrowing
    self.StartGrowing = function(self, time, ...)
        if not POPULATING and time and time > 0 then time = time * changeIndex end
        oldStartGrowing(self, time, ...)
    end
end)

AddComponentPostInit("crop", function(self)
    self.rate = self.rate / changeIndex
    local oldStartGrowing = self.StartGrowing
    self.StartGrowing = function(self, prod, time, ...)
        if time and time > 0 then time = time * changeIndex end
        oldStartGrowing(self, prod, time, ...)
    end
end)

if CONFIGS_LEGION then
    AddComponentPostInit("perennialcrop2", function(self)
        local oldGetGrowTime = self.GetGrowTime
        self.GetGrowTime = function(self, ...)
            local time = oldGetGrowTime(self, ...)
            return time and time * changeIndex
        end
    end)
end

if TUNING.NDNR_ACTIVE then
    AddComponentPostInit("ndnr_pluckable", function(self)
        local SetRespawnTime = self.SetRespawnTime
        self.SetRespawnTime = function(self, time, ...)
            if time and not self.inst.components.health and
                (self.inst.components.growable or self.inst.components.pickable or self.inst.components.crop or self.inst.components.harvestable) then
                time = time * changeIndex
            end
            SetRespawnTime(self, time, ...)
        end
    end)
end

-- 妥协巨树蓝莓恢复变慢,帮助金鱼草修BUG
if TUNING.DSTU then
    AddPrefabPostInit("diseasecure", function(inst)
        if not TheWorld.ismastersim then return end
        if inst.components.timer then inst.components.timer:SetTimeLeft("disperse", TUNING.SLEEPBOMB_DURATION / 2) end
    end)
    local function slowgrow(inst)
        if not TheWorld.ismastersim then return end
        if inst.components.timer and inst.components.timer.StartTimer then
            local StartTimer = inst.components.timer.StartTimer
            inst.components.timer.StartTimer = function(self, name, time, ...)
                if time and name == "regrow" then time = POPULATING and time or time * changeIndex end
                return StartTimer(self, name, time, ...)
            end
        end
    end
    AddPrefabPostInit("giant_tree", slowgrow)
    AddPrefabPostInit("blueberryplant", slowgrow)
    AddPrefabPostInit("whisperpod_normal_ground",
                      function(inst) SetOnSave(inst, function(inst, data) if inst.growing and not data.growing then data.growing = true end end) end)
end

-- 大理石灌木可以催生
AddPrefabPostInit("marbleshrub", function(inst)
    inst:AddTag("silviculture")
    if not TheWorld.ismastersim then return end
    inst.components.growable.magicgrowable = true
end)

-- 亮茄生成速率减慢，但根据玩家数量调整生成数量
if else_changeIndex > 1 then
    local function OnLunarRiftReachedMaxSize(source, rift)
        local self = TheWorld.components.lunarthrall_plantspawner
        if self.waves_to_release and self.waves_to_release > 0 then
            local player_count = #AllPlayers
            local base_waves = math.max(math.ceil(self.waves_to_release / else_changeIndex), 1)
            self.waves_to_release = base_waves * math.max(player_count, 1)
        end
        if self._nextspawn then
            local time = GetTaskRemaining(self._nextspawn)
            local SpawnThralls = self._nextspawn.fn
            if time and time > 0 and SpawnThralls then
                self._nextspawn:Cancel()
                self._nextspawn = nil
                self._nextspawn = self.inst:DoTaskInTime(time * else_changeIndex, SpawnThralls)
            end
        elseif self._spawntask and self._spawntask.fn then
            local setTimeForPoralRelease = self._spawntask.fn
            setTimeForPoralRelease()
        end
        if self._spawntask then
            local time = GetTaskRemaining(self._spawntask)
            local setTimeForPoralRelease = self._spawntask.fn
            if time and time > 0 and setTimeForPoralRelease then
                self._spawntask:Cancel()
                self._spawntask = nil
                self._spawntask = self.inst:DoTaskInTime(time * else_changeIndex, setTimeForPoralRelease)
            end
        end
    end
    local function DealyOnLunarRiftReachedMaxSize(inst, ...)
        if POPULATING then return end
        inst:DoTaskInTime(FRAMES, OnLunarRiftReachedMaxSize, ...)
    end
    AddComponentPostInit("lunarthrall_plantspawner", function(self) self.inst:ListenForEvent("ms_lunarrift_maxsize", DealyOnLunarRiftReachedMaxSize) end)
end

-- 森林织影者更慢生成植物
local function slowbloomtask(inst)
    if inst._bloomtask and inst._bloomtask.period and not inst._bloomtask.period2hm then
        inst._bloomtask.period2hm = true
        inst._bloomtask.period = inst._bloomtask.period * changeIndex * (GetModConfigData("Shadow World") and 2 or 1)
    end
end
AddPrefabPostInit("stalker_forest", function(inst)
    if not TheWorld.ismastersim then return end
    inst:DoTaskInTime(FRAMES, slowbloomtask)
    local StartBlooming = inst.StartBlooming
    inst.StartBlooming = function(inst, ...)
        StartBlooming(inst, ...)
        inst:DoTaskInTime(FRAMES, slowbloomtask)
    end
    local OnEntityWake = inst.OnEntityWake
    inst.OnEntityWake = function(inst, ...)
        OnEntityWake(inst, ...)
        inst:DoTaskInTime(FRAMES, slowbloomtask)
    end
end)

-- 干浆果
local cooking = require("cooking")
local berriesVEGGIES = {"berries", "berries_juicy"}
local function onperished(inst)
    if inst.components.perishable and inst.components.inventoryitem and inst.components.inventoryitem.owner and inst.components.inventoryitem.owner:IsValid() then
        if not (inst.components.inventoryitem.owner.components.container and inst.components.inventoryitem.owner.components.container.itemtestfn) then
            inst.components.perishable.onperishreplacement = inst.prefab .. "_dried2hm"
        end
    elseif inst.components.perishable and inst:IsAsleep() then
        inst.components.perishable.onperishreplacement = nil
        inst:DoTaskInTime(0, inst.Remove)
    end
end
local hungervalue = TUNING.DSTU and TUNING.DSTU.SEEDS and TUNING.DSTU.FOOD_SEEDS_HUNGER or TUNING.CALORIES_TINY / 2
local function veggiepostinit(inst)
    if not TheWorld.ismastersim then return end
    if inst.components.perishable then inst:ListenForEvent("perished", onperished) end
end
for _, veggiename in ipairs(berriesVEGGIES) do
    AddIngredientValues({veggiename .. "_dried2hm"}, {fruit = .25})
    AddPrefabPostInit(veggiename, veggiepostinit)
end


-- 蘑菇
local function process_mushroom(inst)
    if not TheWorld.ismastersim then return end
    
    local oldOnPicked = inst.components.pickable.onpickedfn
    inst.components.pickable.onpickedfn = function(inst)
        oldOnPicked(inst)
        inst.rain = 128 -- 8天
    end
    
    local oldCheckRegrow = inst.checkregrow
    inst.checkregrow = function(inst)
        if inst.components.pickable ~= nil and not inst.components.pickable.canbepicked and TheWorld.state.israining and
             TheWorld.state.isspring then -- 非春天不生长
            inst.rain = inst.rain - 1
            if inst.rain <= 0 then
                inst.components.pickable:Regen()
            end
        end 
    end
end

for _, prefab in ipairs({"red_mushroom", "green_mushroom", "blue_mushroom"}) do
    AddPrefabPostInit(prefab, process_mushroom)
end


-- 巨石枝生长速度削弱
TUNING.TREE_ROCK.SAPLING_GROW_TIME.base = TUNING.TREE_ROCK.SAPLING_GROW_TIME.base * changeIndex

-- 巨石树退化系统

-- 落石会破坏覆盖范围的易碎品，破坏建筑
-- 参考地震巨石落下触发的逻辑
local HEAVY_WORK_ACTIONS = {
    CHOP = true,
    DIG = true,
    HAMMER = true,
    MINE = true,
}

local HEAVY_SMASHABLE_TAGS = { "smashable", "quakedebris", "_combat", "_inventoryitem", "NPC_workable" }
for k, v in pairs(HEAVY_WORK_ACTIONS) do
    table.insert(HEAVY_SMASHABLE_TAGS, k.."_workable")
end
local HEAVY_NON_SMASHABLE_TAGS = { "INLIMBO", "playerghost", "irreplaceable", "caveindebris", "outofreach" }

local function HasHardHat(ent)
    local equipped_hat = ent.components.inventory and ent.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
    return equipped_hat and equipped_hat:HasTag("hardarmor")
end

-- 原版的GetAffectedEntities逻辑，用于检测硬质头盔
local function GetAffectedEntitiesForBounceCheck(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local build_name = inst.build or "rock1"
    local range = (build_name == "rock1") and 
                  (TUNING.TREE_ROCK.ROCK1_AOE_RADIUS or 2) or
                  (TUNING.TREE_ROCK.ROCK2_AOE_RADIUS or 3.25)
    
    local AOE_TARGET_MUST_HAVE_TAGS = { "_combat" }
    local AOE_TARGET_CANT_TAGS = { "INLIMBO", "flight", "invisible", "notarget", "noattack" }
    local AOE_RANGE_PADDING = 3
    
    local ents = TheSim:FindEntities(x, y, z, range + AOE_RANGE_PADDING, AOE_TARGET_MUST_HAVE_TAGS, AOE_TARGET_CANT_TAGS)
    local affected_ents = {}
    
    for i, v in ipairs(ents) do
        if v ~= inst and v:IsValid() and not v:IsInLimbo() and not IsEntityDead(v) then
            local range1 = range + v:GetPhysicsRadius(0)
            if v:GetDistanceSqToPoint(x, y, z) < range1 * range1 then
                table.insert(affected_ents, v)
            end
        end
    end
    return affected_ents
end

-- 原版的ShouldBounce逻辑，是否需要延迟落地
local function ShouldBounce(inst)
    for i, ent in ipairs(GetAffectedEntitiesForBounceCheck(inst)) do
        if ent:HasTag("tree_rock_bouncer") or HasHardHat(ent) then
            return true
        end
    end
    return false
end

local function SmashSurroundingItems(inst)

    if not (inst and inst:IsValid()) then return end
    
    local build_name = inst.build or "rock1"

    if build_name == "rock1" then
        range = TUNING.TREE_ROCK.ROCK1_AOE_RADIUS or 2      -- 圆石头
    elseif build_name == "rock2" then
        range = TUNING.TREE_ROCK.ROCK2_AOE_RADIUS or 3.25   -- 扁石头
    end
    
    -- 查找范围内的可砸碎物品
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, 0, z, range, nil, HEAVY_NON_SMASHABLE_TAGS, HEAVY_SMASHABLE_TAGS)
    
    for i, v in ipairs(ents) do
        if v ~= inst and v:IsValid() and not v:IsInLimbo() then
            -- 砸碎带quakedebris标签的掉落物
            if v:HasTag("quakedebris") then
                local vx, vy, vz = v.Transform:GetWorldPosition()
                SpawnPrefab("ground_chunks_breaking").Transform:SetPosition(vx, 0, vz)
                v:Remove()
                
            -- 破坏可工作的建筑
            elseif v.components.workable ~= nil then
                local work_action = v.components.workable:GetWorkAction()
                
                if (v.sg == nil or not v.sg:HasStateTag("busy")) then
                    local should_destroy = false
                    
                    if work_action == nil and v:HasTag("NPC_workable") then
                        should_destroy = true
                    elseif work_action ~= nil and HEAVY_WORK_ACTIONS[work_action.id] then
                        -- 挖掘类建筑需要额外检查是否有spawner组件（避免破坏重要的生成器）
                        if work_action ~= ACTIONS.DIG or 
                           (v.components.spawner == nil and v.components.childspawner == nil) then
                            should_destroy = true
                        end
                    end
                    
                    if should_destroy then
                        v.components.workable:Destroy(inst)
                    end
                end
            end
        end
    end
end

-- 为所有巨石枝变种添加砸碎功能
local tree_rock_prefabs = {"tree_rock", "tree_rock1", "tree_rock2", "tree_rock1_short", "tree_rock1_normal", "tree_rock2_short", "tree_rock2_normal"}

for _, prefab_name in ipairs(tree_rock_prefabs) do
    AddPrefabPostInit(prefab_name, function(inst)
        if not TheWorld.ismastersim then return end
        
        inst:DoTaskInTime(0, function()
            if inst.components.workable and inst.components.workable.onfinish then
                local oldOnChopDown = inst.components.workable.onfinish

                inst.components.workable.onfinish = function(inst, chopper)
                    -- 调用原版砍倒逻辑
                    oldOnChopDown(inst, chopper)
                    
                    local FALL_DELAY = 4 * FRAMES      -- 普通砸落延迟
                    local BOUNCE_FALL_DELAY = 15 * FRAMES  -- 弹跳砸落延迟（有硬质头盔时）
                    
                    -- 检查是否应该延迟
                    local should_bounce = ShouldBounce(inst)

                    if should_bounce then
                        inst:DoTaskInTime(BOUNCE_FALL_DELAY, function()
                            SmashSurroundingItems(inst)
                        end)
                    else
                        inst:DoTaskInTime(FALL_DELAY, function()
                            SmashSurroundingItems(inst)
                        end)
                    end
                end
            end
        end)
    end)
end
-- TODO:竞技场模式

local EVENT_LIST = {
    farm_plant_terror_snakeskinfruit = "terror_bees",
    farm_plant_terror_blueberry = "terror_bees",
    farm_plant_terror_ginger = "terror_bees",
}

local CREATURE_LIST = {
    terror_bees = {
        {creature = "bee",          weight = 5},
        {creature = "killerbee",    weight = 10},
        {creature = "honor_bee",     weight = 20},
        {creature = "terror_bee",    weight = 50},
        {creature = "beequeen",     weight = 1}
    }
}

local SPAWN_DIST = 15
local worldsettingstimer = TheWorld.components.worldsettingstimer
local TERROREVENT_TIMER_NAME = "terror_event_timer"

local TerrorEvent = Class(function(self, inst)
	self.inst = inst

    -- 当前是否处于凶险事件状态
    self.isterror = false

    self.pick_record = {}   -- pick_record[player.userid] = {[plant.prefab] = count}

    -- 每个玩家的生成生物清单
    self.spawn_list = {}    -- spawn_list[player.userid] = {"creature"}

    -- 每个玩家的生成任务
    self.spawntask = {}     -- spawntask[player.userid] = task

    -- 当前凶险事件类型
    self.current_event = nil

    -- 凶险事件处于冷却状态
    self.isincooldown = false

    -- 阻止凶险事件的源头记录
    self.prevent_source = {}

    -- data = {picker = picker, plant = self.inst}
    self.inst:ListenForEvent("terror_event_begin", function(_, data)
        self:OnTerrorPicked(data.picker, data.plant)
    end, TheWorld)

    self.inst:ListenForEvent("terror_event_end", function()
        self.isincooldown = true
        local function OnCooldownPeriodEnd()
            self.isincooldown = false
        end
        if not worldsettingstimer:ActiveTimerExists(TERROREVENT_TIMER_NAME) then
            worldsettingstimer:AddTimer(TERROREVENT_TIMER_NAME, TUNING.HMR_TERROREVENT_COOLDOWN_PERIOD, true, OnCooldownPeriodEnd)
        end
        worldsettingstimer:StartTimer(TERROREVENT_TIMER_NAME, TUNING.HMR_TERROREVENT_COOLDOWN_PERIOD)
        worldsettingstimer:ResumeTimer(TERROREVENT_TIMER_NAME)
    end, TheWorld)

    -- self.inst:ListenForEvent("ms_playerjoined", function() end)
end)

---------------------------------------------------------------------------
---[[首次采摘时提醒玩家]]
---------------------------------------------------------------------------
function TerrorEvent:IsFirstPick(player, plant)
    if self.pick_record[player.userid] == nil then
        return true
    else
        if self.pick_record[player.userid][plant.prefab] == nil then
            return true
        else
            return false
        end
    end
end

function TerrorEvent:GetPickNum(player, plant)
    if self.pick_record[player.userid] == nil then
        return 0
    else
        if self.pick_record[player.userid][plant.prefab] == nil then
            return 0
        else
            return self.pick_record[player.userid][plant.prefab]
        end
    end
end

function TerrorEvent:RecordPick(picker, plant)
    if self.pick_record[picker.userid] == nil then
        self.pick_record[picker.userid] = {[plant.prefab] = 1}
    else
        if self.pick_record[picker.userid][plant.prefab] == nil then
            self.pick_record[picker.userid][plant.prefab] = 1
        else
            self.pick_record[picker.userid][plant.prefab] = self.pick_record[picker.userid][plant.prefab] + 1
        end
    end
end

---------------------------------------------------------------------------
---[[阻止来源]]
---------------------------------------------------------------------------
function TerrorEvent:AddPreventSource(source)
    table.insert(self.prevent_source, source.GUID)
    if self.isterror then
        self:StopTerrorEvent()
    end
end

function TerrorEvent:RemovePreventSource(source)
    for i, guid in ipairs(self.prevent_source) do
        if guid == source.GUID then
            table.remove(self.prevent_source, i)
            break
        end
    end
end

function TerrorEvent:HasPreventSource()
    return self.prevent_source and #self.prevent_source > 0
end

---------------------------------------------------------------------------
---[[采摘]]
---------------------------------------------------------------------------
-- 采摘回调函数
function TerrorEvent:OnTerrorPicked(picker, plant)
    local hasterroreventtimer = worldsettingstimer:ActiveTimerExists(TERROREVENT_TIMER_NAME)
    if not self.isterror and (not hasterroreventtimer or not self.isincooldown) then
        self.isterror = true
        self.isincooldown = false

        self.current_event = self:ChooseTerrorEvent(plant)
        self:StartTerrorEvent(self.current_event)
    end
end

-- 选择凶险事件
function TerrorEvent:ChooseTerrorEvent(plant)
    local event = EVENT_LIST[plant.prefab]
    if event then
        return event
    else
        return "terror_bees"
    end
end

---------------------------------------------------------------------------
---[[生成生物]]
---------------------------------------------------------------------------
-- 判断生物生成点是否附近无洞穴
local function NoHoles(pt)
    return not TheWorld.Map:IsPointNearHole(pt)
end

-- 获取生成点
local function GetSpawnPoint(pt, radius_override)
    -- 设置生成半径，默认为SPAWN_DIST
    if radius_override == nil then
        radius_override = SPAWN_DIST
    end
	if TheWorld.has_ocean then
		-- 如果世界中有海洋，定义海洋生成点的判断条件
		local function OceanSpawnPoint(offset)
			local x = pt.x + offset.x
			local y = pt.y + offset.y
			local z = pt.z + offset.z
			return TheWorld.Map:IsAboveGroundAtPoint(x, y, z, true) and NoHoles(pt) -- 判断是否在地面且无洞穴
		end

		-- 找到有效的生成位置
		local offset = FindValidPositionByFan(math.random() * TWOPI, radius_override, 12, OceanSpawnPoint)
		if offset ~= nil then
			offset.x = offset.x + pt.x -- 计算生成位置
			offset.z = offset.z + pt.z
			return offset
		end
	else
		-- 如果没有海洋，确保生成点在地面
		if not TheWorld.Map:IsAboveGroundAtPoint(pt:Get()) then
			pt = FindNearbyLand(pt, 1) or pt
		end
		local offset = FindWalkableOffset(pt, math.random() * TWOPI, radius_override, 12, true, true, NoHoles)
		if offset ~= nil then
			offset.x = offset.x + pt.x -- 计算生成位置
			offset.z = offset.z + pt.z
			return offset
		end
	end
end

-- 确定生成数量
local function GetSpawnNum(player)
    local age = player.components.age:GetAgeInDays()
    if age <= 10 then
        return 0
    else
        return math.min(age, 70)
    end
end

-- 选择生物
local function ChooseCreature(event)
    local creatures = CREATURE_LIST[event]

    local total_weight = 0
    for _, creature in ipairs(creatures) do
        total_weight = total_weight + creature.weight
    end

    local rand = math.random() * total_weight
    local sum = 0
    for _, creature in ipairs(creatures) do
        sum = sum + creature.weight
        if rand <= sum then
            return creature.creature
        end
    end
end

-- 判断是否所有玩家的生成任务都结束
local function IsAllTaskEnd(self)
    local all_end = true
    for _, allplayer in ipairs(AllPlayers) do
        if self.spawn_list[allplayer.userid] ~= nil and #self.spawn_list[allplayer.userid] > 0 then
            all_end = false
            break
        end
    end
    if all_end then
        self.isterror = false   -- 所有玩家的生成任务都结束，结束凶险事件
        self.current_event = nil
        self.spawn_list = {}
        self.spawntask = {}
        TheWorld:PushEvent("terror_event_end")
    end
end

local function SpawnCreaturesFn(player, data)
    local self = data.self
    if self.spawn_list[player.userid] == nil or #self.spawn_list[player.userid] == 0 then
        return IsAllTaskEnd(self)
    end
    local spawn_fn = data.fn
    local pt = player:GetPosition()
    local spawn_pt = GetSpawnPoint(pt)
    local spawn = SpawnPrefab(self.spawn_list[player.userid][1])
    if spawn ~= nil then
        spawn.Physics:Teleport(spawn_pt:Get())
        spawn:FacePoint(pt)
        if spawn.components.combat ~= nil then
            spawn.components.combat:SetTarget(player)
        end
        if spawn.components.spawnfader ~= nil then
            spawn.components.spawnfader:FadeIn() -- 渐显效果
        end
    end
    table.remove(self.spawn_list[player.userid], 1)

    if self.spawn_list[player.userid] == nil or #self.spawn_list[player.userid] == 0 then
        self.spawntask[player.userid]:Cancel()
        self.spawntask[player.userid] = nil

        IsAllTaskEnd(self)

        player.net_terrorevent:set("none")
    end

    spawn_fn(self, player)
end

local function SpawnCreatures(self, player)
    if self.spawntask[player.userid] then
        self.spawntask[player.userid]:Cancel()
    end

    if self.spawn_list[player.userid] == nil or #self.spawn_list[player.userid] == 0 then
        return IsAllTaskEnd(self)
    end
    self.spawntask[player.userid] = player:DoTaskInTime(GetRandomMinMax(2, 5), SpawnCreaturesFn, {self = self, fn = SpawnCreatures})
end

-- 开启凶险事件
function TerrorEvent:StartTerrorEvent(event)
    for _, player in ipairs(AllPlayers) do

        -- 玩家视野相关
        player.net_terrorevent:set(event)

        -- 每个玩家的生成数量
        local creaturesnum = GetSpawnNum(player)
        -- 每个玩家的生成生物清单
        self.spawn_list[player.userid] = {}
        -- 选择将生成的生物
        if creaturesnum > 0 then
            for i = 1, creaturesnum do
                table.insert(self.spawn_list[player.userid], ChooseCreature(event))
            end
        end
        -- 生成生物
        SpawnCreatures(self, player)
    end
end

function TerrorEvent:StopTerrorEvent()
    self.isterror = false
    for _, player in ipairs(AllPlayers) do
        player.net_terrorevent:set("none")
    end
    if self.spawn_task ~= nil then
        for _, task in pairs(self.spawn_task) do
            task:Cancel()
        end
    end
    self.current_event = nil
    self.spawn_list = {}
    self.spawntask = {}
end

function TerrorEvent:OnSave()
    local data =
    {
        isterror = self.isterror,
        spawn_list = self.spawn_list,
        current_event = self.current_event,
        isincooldown = self.isincooldown
    }
    return next(data) ~= nil and data or nil
end

function TerrorEvent:OnLoad(data)
    self.isterror = data.isterror
    self.spawn_list = data.spawn_list
    self.current_event = data.current_event
    self.isincooldown = data.isincooldown

    if self.isterror then
        self.inst:DoTaskInTime(TUNING.HMR_TERROREVENT_GAMESTART_BUFFER_TIME, function()
            for _, player in ipairs(AllPlayers) do
                SpawnCreatures(self, player)
            end
        end)
    end
end

return TerrorEvent
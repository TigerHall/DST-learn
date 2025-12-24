local GetPrefab = require("aab_utils/getprefab")

-- 每天加一点经验
local function OnStartDay(inst)
    inst.components.aab_my_pig:DoDelta(1)
end

local function oncurrent(self, current)
    self.inst.replica.aab_my_pig:SetCurrent(current)
end

local function onpig(self, pig)
    self.inst.replica.aab_my_pig:SetPig(pig)
end

local MyPig = Class(function(self, inst)
    self.inst = inst

    self.current = 0

    self.pig = nil
    self.name = nil --每次猪人重新召唤都会换一个新名字，这不好

    self.spawntask = nil
    self._onpigdeath = function(pig, data) self:Unsummon() end

    self.pig_health = TUNING.AAB_MY_PIG_HEALTH --召回时猪人的血量
    self.last_unsummon_time = GetTime()        --上次召回时间，根据这个计算血量

    inst:WatchWorldState("startday", OnStartDay)
end, nil, {
    current = oncurrent,
    pig = onpig
})

function MyPig:OnLevelChange()
    local pig = self.pig
    if not pig or not pig:IsValid() or IsEntityDead(pig) then
        return
    end
    pig.components.health:SetMaxHealth(TUNING.AAB_MY_PIG_HEALTH + 10 * self.current)
    -- pig.components.combat:SetDefaultDamage(TUNING.AAB_MY_PIG_DAMAGE + 0.5 * self.current)
    pig.components.combat.externaldamagemultipliers:SetModifier(pig, 1 + 1 / 30 * self.current, "aab_monkey_weak") --用攻击倍率的话可以受到武器加成
    pig.components.combat:SetAttackPeriod(math.max(1, 2 - self.current / 30))
end

function MyPig:DoDelta(count)
    self.current = math.clamp(self.current + count, 0, 9999)
    self:OnLevelChange()
end

----------------------------------------------------------------------------------------------------
local function GetCurrentHealth(self)
    return self.pig_health + (GetTime() - self.last_unsummon_time) * math.max(TUNING.AAB_MY_PIG_HEALTH_HEAL * 2, 1) --最少每秒回1滴血，收回状态下回血速度翻倍
end

local function LinkPig(self, pig)
    self.pig = pig
    self:OnLevelChange()
    self.inst.components.leader:AddFollower(pig)
    self.inst:ListenForEvent("death", self._onpigdeath, pig)
    pig.components.health:SetPercent(GetCurrentHealth(self) / pig.components.health.maxhealth) --溢出了也不会报错
end

local function TrySpawnPig(inst, self)
    local pos = GetPrefab.GetSpawnPoint(inst:GetPosition(), 30, 12)
    if not pos then
        if inst:GetCurrentPlatform() then
            --如果玩家在船上直接传送到玩家身边
            pos = inst:GetPosition()
            SpawnAt("spawn_fx_small", pos)
        else
            return
        end
    end

    local pig = SpawnAt("aab_my_pig", pos)
    if self.name then
        pig.components.named:SetName(self.name)
    else
        self.name = pig.components.named.name
    end
    LinkPig(self, pig)

    if self.spawntask then
        self.spawntask:Cancel()
        self.spawntask = nil
    end
end

-- 召唤
function MyPig:Summon()
    if self.pig and self.pig:IsValid() then return end

    if self._pigdata then --从保存的数据中还原猪人
        local pig = SpawnSaveRecord(self._pigdata)
        LinkPig(self, pig)
        if not self.inst:IsNear(pig, 30) then
            --上下洞穴应该刷在玩家身边，而不是地上的坐标
            pig.Transform:SetPosition(self.inst.Transform:GetWorldPosition())
            SpawnAt("spawn_fx_small", pig)
        end

        self._pigdata = nil
    else
        if not self.spawntask then
            self.spawntask = self.inst:DoPeriodicTask(1, TrySpawnPig, 0, self)
        end
    end
end

-- 召回
function MyPig:Unsummon()
    local pig = self.pig
    if not pig then return end

    if pig:IsValid() and not IsEntityDead(pig) then
        SpawnAt("spawn_fx_small", pig)
        pig.components.inventory:DropEverything()
        pig:Remove()
    end

    self.pig = nil
    self.last_unsummon_time = GetTime()
    self.pig_health = pig.components.health and pig.components.health.currenthealth or 0
end

----------------------------------------------------------------------------------------------------

function MyPig:OnSave()
    local data = {}

    data.current = self.current
    data.pigdata = self._pigdata
    data.name = self.name

    if self.pig and self.pig:IsValid() then
        data.pig_health = self.pig.components.health.currenthealth or GetCurrentHealth(self)
        data.pigdata = self.pig:GetSaveRecord()
        data.name = self.pig.components.named.name
    end

    return data
end

function MyPig:OnLoad(data)
    if not data then return end

    self.current = data.current or self.current
    self.pig_health = data.pig_health or self.pig_health
    self.name = data.name or self.name

    if data.pigdata then
        self._pigdata = data.pigdata --因为游戏有可能连续调用两次save和load
        self.inst:DoTaskInTime(0, function() self:Summon() end)
    end
end

return MyPig

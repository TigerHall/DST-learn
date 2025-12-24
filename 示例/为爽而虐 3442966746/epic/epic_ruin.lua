-- 记录非玩家生物受到的巨兽伤害， 死亡时按巨兽伤害占比减少掉落物

local epic_ruin_max_rate = GetModConfigData("epic_ruin") or 0.6

-- 初始化数据存储
local function InitEpicRuinData(inst)
    if not inst.components.persistent2hm then
        inst:AddComponent("persistent2hm")
    end
    if not inst.components.persistent2hm.data.epicruin2hm then
        inst.components.persistent2hm.data.epicruin2hm = {
            totalEpicDamage = 0,
            lastDecayDay = TheWorld.state.cycles or 0,
        }
    end
    return inst.components.persistent2hm.data.epicruin2hm
end

-- 获取数据（自动初始化）
local function GetEpicRuinData(inst)
    if inst.components.persistent2hm and inst.components.persistent2hm.data.epicruin2hm then
        return inst.components.persistent2hm.data.epicruin2hm
    end
    return InitEpicRuinData(inst)
end

-- 每天衰减记录的巨兽伤害（每天衰减20%总血量）
local function DailyDecayEpicDamage(inst)
    if not inst.components.health then return end
    
    local data = GetEpicRuinData(inst)
    if data.totalEpicDamage <= 0 then return end
    
    local currentDay = TheWorld.state.cycles or 0
    local lastDecayDay = data.lastDecayDay or 0
    local daysPassed = currentDay - lastDecayDay
    
    if daysPassed > 0 then
        local maxHealth = inst.components.health.maxhealth
        local decayAmount = maxHealth * 0.2 * daysPassed
        
        data.totalEpicDamage = math.max(0, data.totalEpicDamage - decayAmount)
        data.lastDecayDay = currentDay
    end
end

-- 记录来自巨兽的伤害
local function RecordEpicDamage(inst, damage, attacker)
    if not inst.components.health then return end
    if inst:HasTag("player") then return end
    
    -- 检查攻击者是否是巨兽或巨兽的召唤物
    local isEpic = false
    if attacker then
        if attacker:HasTag("epic") or attacker:HasTag("epic_child2hm") then
            isEpic = true
        end
    end
    
    if not isEpic then return end
    
    local data = GetEpicRuinData(inst)
    
    -- 执行日常衰减
    DailyDecayEpicDamage(inst)
    
    -- 记录伤害(上限为总血量)
    local maxHealth = inst.components.health.maxhealth
    data.totalEpicDamage = math.min(data.totalEpicDamage + damage, maxHealth)
end

-- 计算掉落减少比例
local function CalculateReduceRatio(inst)
    if not inst.components.health then return 0 end
    if not inst.components.persistent2hm or not inst.components.persistent2hm.data.epicruin2hm then
        return 0
    end
    
    local data = inst.components.persistent2hm.data.epicruin2hm
    if data.totalEpicDamage <= 0 then return 0 end
    
    -- 执行最后一次日常衰减
    DailyDecayEpicDamage(inst)
    
    -- 计算占比（不超过配置的最大值）
    local maxHealth = inst.components.health.maxhealth
    local epicDamageRatio = data.totalEpicDamage / maxHealth
    return math.min(epicDamageRatio, epic_ruin_max_rate)
end

-- 掉落物生成顺序：numrandomloot -> chanceloot -> chanceloottable -> ifnotchanceloot -> loot -> droprecipeloot -> burnt(charcoal)
-- 我们在最终的 loots 表中按比例随机移除掉落物
local function ModifyLootDropper(inst)
    if not inst.components.lootdropper then return end
    
    local oldGenerateLoot = inst.components.lootdropper.GenerateLoot
    inst.components.lootdropper.GenerateLoot = function(self)
        local loots = oldGenerateLoot(self)
        
        local reduceRatio = CalculateReduceRatio(inst)
        if reduceRatio <= 0 or not loots or #loots == 0 then
            return loots
        end
        
        -- 计算要移除的掉落物数量
        local removeCount = math.floor(#loots * reduceRatio)
        
        -- 随机移除掉落物（从后往前移除以避免索引问题）
        for i = 1, removeCount do
            if #loots > 0 then
                table.remove(loots, math.random(#loots))
            end
        end
        
        return loots
    end
end

-- 修改生物的Health组件来记录伤害
local function ModifyHealthComponent(inst)
    if not inst.components.health then return end
    
    local oldSetVal = inst.components.health.SetVal
    inst.components.health.SetVal = function(self, val, cause, afflicter)
        local delta = self.currenthealth - val
        
        -- 仅记录受到的伤害（delta > 0）
        if delta > 0 and afflicter then
            RecordEpicDamage(inst, delta, afflicter)
        end
        
        return oldSetVal(self, val, cause, afflicter)
    end
end

AddPrefabPostInitAny(function(inst)
    if not TheWorld.ismastersim then return end
    if inst:HasTag("player") then return end
    if not inst.components.health then return end
    
    inst:DoTaskInTime(0, function()
        if not inst:IsValid() then return end
        
        ModifyHealthComponent(inst)

        ModifyLootDropper(inst)
        
        inst:WatchWorldState("cycles", function()
            DailyDecayEpicDamage(inst)
        end)
    end)
end)

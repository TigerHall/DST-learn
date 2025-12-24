-- ============================================================================
-- 随机生物大小 API (重构版本)
-- ============================================================================

-- 配置常量
local CONFIG = {
    -- 体型限制
    MAX_DOMESTICATED_SCALE = 1.5,  -- 驯化牛最大体型倍率
    DOUBLE_LOOT_THRESHOLD = 1.3,   -- 双倍掉落阈值
    
    -- 随机概率
    HEALTH_UNIT_LARGE_CHANCE = 0.043,  -- 有血量单位大体型概率 (4.3%)
    NO_HEALTH_LARGE_CHANCE = 0.1,      -- 无血量单位大体型概率 (10%)
    SPAWN_CHANCE = 0.8,                -- 生物生成随机大小概率 (80%)
    
    -- 体型范围
    HEALTH_LARGE_MIN = 1.35,
    HEALTH_LARGE_MAX = 2.0,
    HEALTH_NORMAL_MIN = 0.75,
    HEALTH_NORMAL_MAX = 1.3,
    NO_HEALTH_LARGE_SCALE = 1.5,
    NO_HEALTH_NORMAL_MIN = 0.75,
    NO_HEALTH_NORMAL_MAX = 1.2,
}

-- ============================================================================
-- 核心功能函数
-- ============================================================================

-- 获取随机倍率倍率
local function GetRandomScale(inst)
    if inst.myscale then return inst.myscale end
    
    if inst:HasTag("_health") then
        -- 有血量的生物：4.3%概率1.35~2倍，95.7%概率0.75~1.3倍
        local chance = math.random(1150)
        if chance > 1100 then
            return CONFIG.HEALTH_LARGE_MIN + (chance - 1100) / 50 * (CONFIG.HEALTH_LARGE_MAX - CONFIG.HEALTH_LARGE_MIN)
        end
        return chance / 2000 + CONFIG.HEALTH_NORMAL_MIN
    else
        -- 无血量的生物：10%概率1.5倍，90%概率0.75~1.2倍
        local chance = math.random()
        if chance > 0.9 then
            return CONFIG.NO_HEALTH_LARGE_SCALE
        end
        return chance * (CONFIG.NO_HEALTH_NORMAL_MAX - CONFIG.NO_HEALTH_NORMAL_MIN) + CONFIG.NO_HEALTH_NORMAL_MIN
    end
end

-- 应用视觉倍率
local function ApplyVisualScale(inst, scale)
    local sx, sy, sz = inst.Transform:GetScale()
    if not (sx and sy and sz) then return false end
    
    local visualScale = scale > 1 and ((scale - 1) / 2 + 1) or scale
    inst.Transform:SetScale(sx * visualScale, sy * visualScale, sz * visualScale)
    return visualScale
end

-- 应用属性倍率
local function ApplyAttributeScale(inst, scale)
    -- 更新光环范围
    if inst.components.aura and scale > 1 then
        inst.components.aura.radius = inst.components.aura.radius * scale
    end
    
    -- 更新血量
    if inst.components.health and not inst.myscalehealth2hm then
        local percent = inst.components.health:GetPercent()
        inst.components.health:SetMaxHealth(math.ceil(inst.components.health.maxhealth * scale))
        inst.components.health:SetPercent(percent)
        inst.myscalehealth2hm = true
    end
end

-- 应用战斗属性倍率
local function ApplyCombatScale(inst, scale)
    if not inst.components.combat then return end

    -- 牛的伤害会在游戏内动态改变，需要为驯化好的牛统一按驯势乘以倍率
    if inst.prefab == "beefalo" and inst.components.domesticatable and inst.components.domesticatable:IsDomesticated() then
        return -- 由驯化处理
    end
    -- 伤害倍率大于1时随体型1~2倍在1~1.5变化
    inst.myscale_damage_multiplier = scale > 1 and ((scale - 1) / 2 + 1) or scale

    if inst.components.combat then
        inst.components.combat.defaultdamage = math.ceil(inst.components.combat.defaultdamage * inst.myscale_damage_multiplier)
    end

end

-- 应用移动速度倍率
local function ApplyLocomotorScale(inst, scale, visualScale)
    if not inst.components.locomotor or visualScale <= 1 then return end -- 体型小的就不管了
    
    local locomotor = inst.components.locomotor
    local currentSpeed = locomotor:GetSpeedMultiplier()
    
    -- 计算速度倍率（体型1~2倍对应速度1~1.5倍）
    local speedMultiplier = 1 + (scale - 1) * 0.5
    local oldSpeedMultiplier = 1 + (scale - 1)
    local finalSpeedRatio = speedMultiplier / oldSpeedMultiplier
    
    locomotor:SetExternalSpeedMultiplier(inst, "myscale_speed", finalSpeedRatio)
end

-- 应用掉落物和采集倍率
local function ApplyLootScale(inst, scale, enableLoot)
    if scale <= CONFIG.DOUBLE_LOOT_THRESHOLD then return end
 
    if enableLoot and not inst:HasTag("structure") and not inst:HasTag("swc2hm") then
        -- 双倍掉落
        if inst.components.lootdropper then
            local oldDropLoot = inst.components.lootdropper.DropLoot
            inst.components.lootdropper.DropLoot = function(self, ...)
                oldDropLoot(self, ...)
                return oldDropLoot(self, ...)
            end
            
            -- 冰块特殊处理
            if inst.prefab == "rock_ice" then
                local oldSpawnLoot = inst.components.lootdropper.SpawnLootPrefab
                inst.components.lootdropper.SpawnLootPrefab = function(self, ...)
                    oldSpawnLoot(self, ...)
                    return oldSpawnLoot(self, ...)
                end
            end
        end
        
        -- 风滚草特殊处理
        if inst.prefab == "tumbleweed" and inst.loot and next(inst.loot) then
            local newLoot = {}
            for i, v in ipairs(inst.loot) do
                table.insert(newLoot, v)
            end
            for i, v in ipairs(newLoot) do
                table.insert(inst.loot, v)
            end
        end
    end
    
    -- 双倍采集（排除有交易组件的单位）
    if inst.components.pickable and not inst.components.trader then
        inst.components.pickable.numtoharvest = inst.components.pickable.numtoharvest * 2
    end
end

-- 主倍率函数
local function ApplyScale(inst, scale, enableLoot)
    if not inst or inst.scaled_applied or not inst.ray_busuijidaxiao or inst.ray_busuijidaxiao ~= 1 then
        return
    end
    
    inst.scaled_applied = true
    local actualScale = inst.myscale or scale
    
    -- 应用视觉倍率
    local visualScale = ApplyVisualScale(inst, actualScale)
    if not visualScale then return end
    
    -- 应用各种属性倍率
    ApplyAttributeScale(inst, actualScale)              -- 血量和光环
    ApplyCombatScale(inst, actualScale, visualScale)    -- 伤害
    ApplyLocomotorScale(inst, actualScale, visualScale) -- 移动速度
    ApplyLootScale(inst, actualScale, enableLoot)       -- 掉落物
    
    inst.myscale = actualScale
end

-- ============================================================================
-- 保存/加载系统
-- ============================================================================

local function SetupSaveLoad(inst)
    local oldOnSave = inst.OnSave
    inst.OnSave = function(inst, data)
        if oldOnSave then oldOnSave(inst, data) end
        data.ray_busuijidaxiao = inst.ray_busuijidaxiao
        data.ray_nars2hm = inst.ray_nars2hm
        if inst.myscale then data.myscale = inst.myscale end
    end

    local oldOnLoad = inst.OnLoad
    inst.OnLoad = function(inst, data)
        if oldOnLoad then oldOnLoad(inst, data) end
        if not data then return end
        
        if data.ray_busuijidaxiao ~= nil then 
            inst.ray_busuijidaxiao = data.ray_busuijidaxiao 
        end
        
        if data.ray_nars2hm then
            inst.ray_nars2hm = data.ray_nars2hm
            inst:AddTag("ray_nars2hm")
        end
        
        if data.myscale then inst.myscale = data.myscale end
    end
    
    local oldOnPreLoad = inst.OnPreLoad
    inst.OnPreLoad = function(inst, data)
        if oldOnPreLoad then oldOnPreLoad(inst, data) end
        if not data then return end
        
        -- 恢复血量
        if data.myscale and inst.components.health and not (data.health and data.health.maxhealth) then
            inst.components.health.maxhealth = math.ceil(inst.components.health.maxhealth * data.myscale)
            if data.health and data.health.health then
                inst.components.health:SetCurrentHealth(data.health.health)
            end
            inst.components.health:DoDelta(0)
            inst.myscalehealth2hm = true
        end
    end
end

-- ============================================================================
-- 牛类特殊处理
-- ============================================================================

local function SetupBeefaloBehavior(inst)
    if not TheWorld.ismastersim then return end
    
    -- 修复一个睡眠时缺少睡眠时间可能导致的崩溃
    inst:ListenForEvent("ridersleep", function(inst, data)
        if data and data.sleeptime == nil and data.sleepiness then
            data.sleeptime = 6 
        end
    end)
    
    -- 拦截SetTendency：在设置前保存伤害，设置后重新覆盖，这样原版不会再乱动伤害数据了
    if inst.SetTendency then
        local oldSetTendency = inst.SetTendency
        inst.SetTendency = function(inst, changedomestication)
            -- 保存当前的体型伤害数据
            local saved_damage = nil
            if inst.myscale and inst.components.combat then
                saved_damage = inst.components.combat.defaultdamage
            end
            
            -- 调用原版函数（这可能会重置defaultdamage）
            oldSetTendency(inst, changedomestication)

            -- 禁止伤害被覆盖
            if inst.components.combat and saved_damage then
                inst.components.combat.defaultdamage = saved_damage
            end
            
            -- 如果已完成驯化，限制体型并应用驯势改变的伤害
            if inst.components.domesticatable:IsDomesticated() and inst.processed_domestication == nil then
                inst:DoTaskInTime(0, function(inst)
                    if not inst or not inst:IsValid() or not inst.myscale then return end
                    inst.processed_domestication = 1  -- 标记已处理，避免重复执行
                    -- 限制体型不大于1.5
                    inst.myscale = math.min(inst.myscale, CONFIG.MAX_DOMESTICATED_SCALE)
                    
                    -- 重新计算并应用伤害倍率
                    inst.myscale_damage_multiplier = inst.myscale > 1 and ((inst.myscale - 1) / 2 + 1) or inst.myscale
                    
                    -- 按照驯势设置基础伤害，然后应用体型倍率
                    local base_damage = TUNING.BEEFALO_DAMAGE[inst.tendency] or TUNING.BEEFALO_DAMAGE.DEFAULT
                    inst.components.combat.defaultdamage = math.ceil(base_damage * inst.myscale_damage_multiplier)
                end)
            end
            
        end
    end
end

-- ============================================================================
-- 实体过滤和生成逻辑
-- ============================================================================

-- 判断实体是否应该应用随机大小
local function ShouldApplyRandomSize(inst)
    return inst and inst.Transform and
           not inst:HasTag("player") and
           not inst:HasTag("structure") and
           not inst:HasTag("wall") and
           not inst:HasTag("shadow") and
           not inst:HasTag("groundtile") and
           not inst:HasTag("molebait") and
           not inst:HasTag("FX") and
           not inst:HasTag("shadowminion") and
           not inst:HasTag("shadowcreature") and
           not inst:HasTag("epic") and
           not inst:HasTag("shadowchesspiece") and
           not inst:HasTag("crabking") and
           not inst:HasTag("companion") and
           not inst:HasTag("boat") and
           not inst:HasTag("ghost") and
           not inst:HasTag("abigail") and
           not inst.components.scaler and
           (inst:HasTag("_health") or inst:HasTag("boulder") or inst:HasTag("tree") or inst:HasTag("plant"))
end

-- 检查实体周围是否应该禁用随机大小
local function CheckNearbyRestrictions(inst)
    if inst.ray_busuijidaxiao ~= nil then return end
    
    -- 检查玩家附近
    for i, player in ipairs(AllPlayers) do
        if player:IsValid() and inst:IsNear(player, 4) then
            inst.ray_busuijidaxiao = 0
            inst.ray_nars2hm = true
            inst:AddTag("ray_nars2hm")
            return
        end
    end
    
    -- 检查已标记的实体附近
    if inst.ray_busuijidaxiao ~= 0 then
        local x, y, z = inst.Transform:GetWorldPosition()
        local nearbyRestricted = TheSim:FindEntities(x, y, z, 4, {"ray_nars2hm"})
        if #nearbyRestricted < 1 and math.random() < CONFIG.SPAWN_CHANCE then
            inst.ray_busuijidaxiao = 1
        else
            inst.ray_busuijidaxiao = 0
        end
    end
end

-- ============================================================================
-- 特殊生物处理
-- ============================================================================

-- 猪人变身处理
local function SetupPigmanBehavior(inst)
    if not inst.components.werebeast then return end
    
    local function ApplyPigmanScale(inst)
        if not inst.myscale then return end
        
        if inst.components.health then
            inst.components.health:SetMaxHealth(math.ceil(inst.components.health.maxhealth * inst.myscale))
        end
        
        if inst.components.combat then
            inst.components.combat.defaultdamage = math.ceil(inst.components.combat.defaultdamage * inst.myscale)
        end
    end
    
    local oldOnSetWere = inst.components.werebeast.onsetwerefn or function() end
    inst.components.werebeast.onsetwerefn = function(inst)
        oldOnSetWere(inst)
        ApplyPigmanScale(inst)
    end
    
    local oldOnSetNormal = inst.components.werebeast.onsetnormalfn or function() end
    inst.components.werebeast.onsetnormalfn = function(inst)
        oldOnSetNormal(inst)
        ApplyPigmanScale(inst)
    end
end

-- 蜘蛛巢升级处理
local function SetupSpiderDenBehavior(inst)
    if not inst.components.upgradeable then return end
    
    local oldSetStage = inst.components.upgradeable.SetStage
    inst.components.upgradeable.SetStage = function(self, num)
        oldSetStage(self, num)
        if self.inst.myscale and self.inst.components.health then
            self.inst.components.health:SetMaxHealth(math.ceil(self.inst.components.health.maxhealth * self.inst.myscale))
        end
    end
end

-- ============================================================================
-- 骑乘变化
-- ============================================================================

local function OnMounted(inst, data)
    if data and data.target then
        local scale = data.target.Transform:GetScale()
        inst:ApplyScale("mounted", scale)
    end
end

local function OnDismounted(inst, data)
    inst:ApplyScale("mounted", 1)
end

local function SetupPlayerMounting(inst)
    if not TheWorld.ismastersim then return end
    inst:ListenForEvent("mounted", OnMounted)
    inst:ListenForEvent("dismounted", OnDismounted)
end

-- ============================================================================
-- 驯化保护
-- ============================================================================

local function OnDomesticationDelta(inst, data)
    if inst.components.domesticatable:IsDomesticated() and data and data.new < 1 then
        inst.components.domesticatable:DeltaDomestication(1)
    end
end

-- ============================================================================
-- 蔬菜打蜡
-- ============================================================================

local function SetupVeggieWaxing()
    require("prefabs/veggies")
    if not GLOBAL.VEGGIES then return end
    
    for veggieName, _ in pairs(GLOBAL.VEGGIES) do
        AddPrefabPostInit(veggieName .. "_oversized", function(inst)
            -- 打蜡功能
            if inst.components.waxable then
                inst.components.waxable.waxfn = function(inst, doer)
                    local waxedVeggie = SpawnPrefab(inst.prefab .. "_waxed")
                    if inst.myscale then waxedVeggie.myscale = inst.myscale end
                    
                    if doer.components.inventory and doer.components.inventory:IsHeavyLifting() and 
                       doer.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY) == inst then
                        doer.components.inventory:Unequip(EQUIPSLOTS.BODY)
                        doer.components.inventory:Equip(waxedVeggie)
                    else
                        waxedVeggie.Transform:SetPosition(inst.Transform:GetWorldPosition())
                        waxedVeggie.AnimState:PlayAnimation("wax_oversized", false)
                        waxedVeggie.AnimState:PushAnimation("idle_oversized")
                    end
                    inst:Remove()
                    return true
                end
            end
            
            -- 腐烂功能
            if inst.components.perishable then
                inst.components.perishable.perishfn = function(inst)
                    if inst.components.inventoryitem:GetGrandOwner() then
                        local spoiledItems = {}
                        for i = 1, #inst.components.lootdropper.loot do
                            table.insert(spoiledItems, "spoiled_food")
                        end
                        inst.components.lootdropper:SetLoot(spoiledItems)
                        inst.components.lootdropper:DropLoot()
                    else
                        local rotten = SpawnPrefab(inst.prefab .. "_rotten")
                        if inst.myscale then rotten.myscale = inst.myscale end
                        rotten.Transform:SetPosition(inst.Transform:GetWorldPosition())
                    end
                    inst:Remove()
                end
            end
        end)
    end
end

-- ============================================================================
-- 生物兼容性设置
-- ============================================================================

local function SetupCreatureCompatibility()
    -- 给洞穴添加猎人组件以生成脚印
    AddPrefabPostInit("cave", function(inst)
        if inst.ismastersim and not inst.components.hunter then
            inst:AddComponent("hunter")
        end
    end)
    
    -- 添加蠕虫和座狼标签使其兼容不互掐
    local function ProcessWorm(inst)
        if TheWorld.ismastersim and TheWorld:HasTag("cave") then
            inst:AddTag("warg")
        end
    end
    
    AddPrefabPostInit("worm", ProcessWorm)
    
    -- DST Uncompromising 模组兼容
    if TUNING.DSTU then
        AddPrefabPostInit("gatorsnake", ProcessWorm)
        AddPrefabPostInit("shockworm", ProcessWorm)
        AddPrefabPostInit("viperling", ProcessWorm)
        AddPrefabPostInit("viperworm", ProcessWorm)
    end
    
    AddPrefabPostInit("warg", function(inst)
        if TheWorld.ismastersim and TheWorld:HasTag("cave") then
            inst:AddTag("worm")
        end
    end)
end

-- ============================================================================
-- 主入口和初始化
-- ============================================================================

-- 注册所有实体的随机大小功能
AddPrefabPostInitAny(function(inst)
    if not ShouldApplyRandomSize(inst) or not TheWorld.ismastersim then
        return
    end
    
    inst:DoTaskInTime(0, function()
        CheckNearbyRestrictions(inst)
        
        if inst.ray_busuijidaxiao == 1 then
            ApplyScale(inst, GetRandomScale(inst), true)
        end
    end)
    
    SetupSaveLoad(inst)
end)

-- 注册特殊生物行为
AddPrefabPostInit("beefalo", SetupBeefaloBehavior)
AddPrefabPostInit("pigman", SetupPigmanBehavior)
AddPrefabPostInit("spiderden", SetupSpiderDenBehavior)

-- 注册牛的驯化保护
AddPrefabPostInit("beefalo", function(inst)
    if TheWorld.ismastersim then
        inst:ListenForEvent("domesticationdelta", OnDomesticationDelta)
    end
end)

-- 注册玩家骑乘功能
AddPlayerPostInit(SetupPlayerMounting)

-- 初始化其他系统
SetupVeggieWaxing()
SetupCreatureCompatibility()

-- c_find("beefalo").components.domesticatable:BecomeDomesticated()
-- c_find("beefalo").components.health:SetPercent(1); c_select().sg:GoToState("revive")
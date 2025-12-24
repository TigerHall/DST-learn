-- ============================================================================
local speedup = GetModConfigData("extra_change") and GetModConfigData("boss_speed") or 1
local attackspeedup = GetModConfigData("extra_change") and GetModConfigData("boss_attackspeed") or 1
local alterguardianmode = GetModConfigData("alterguardian")

if alterguardianmode == true then alterguardianmode = -3 end

-- ============================================================================
-- 移速
if speedup < 2 then
    TUNING.ALTERGUARDIAN_PHASE1_WALK_SPEED = TUNING.ALTERGUARDIAN_PHASE1_WALK_SPEED * 2 / speedup
    TUNING.ALTERGUARDIAN_PHASE2_WALK_SPEED = TUNING.ALTERGUARDIAN_PHASE2_WALK_SPEED * 2 / speedup
    TUNING.ALTERGUARDIAN_PHASE3_WALK_SPEED = TUNING.ALTERGUARDIAN_PHASE3_WALK_SPEED * 2 / speedup
end

-- 攻速
if attackspeedup < 2 then
    TUNING.ALTERGUARDIAN_PHASE1_ATTACK_PERIOD = TUNING.ALTERGUARDIAN_PHASE1_ATTACK_PERIOD / 2 * attackspeedup
    TUNING.ALTERGUARDIAN_PHASE2_ATTACK_PERIOD = TUNING.ALTERGUARDIAN_PHASE2_ATTACK_PERIOD / 2 * attackspeedup
    -- TUNING.ALTERGUARDIAN_PHASE3_ATTACK_PERIOD = TUNING.ALTERGUARDIAN_PHASE3_ATTACK_PERIOD / 2 * attackspeedup
end

-- 技能冷却
if alterguardianmode ~= -2 then
    -- 第一阶段属性
    TUNING.ALTERGUARDIAN_PHASE1_ROLLCOOLDOWN = TUNING.ALTERGUARDIAN_PHASE1_ROLLCOOLDOWN / 2
    TUNING.ALTERGUARDIAN_PHASE1_SUMMONCOOLDOWN = TUNING.ALTERGUARDIAN_PHASE1_SUMMONCOOLDOWN / 2

    -- 第二阶段属性
    -- TUNING.ALTERGUARDIAN_PHASE2_SPINCD = TUNING.ALTERGUARDIAN_PHASE2_SPINCD / 2
    -- TUNING.ALTERGUARDIAN_PHASE2_SPIKECOOLDOWN = TUNING.ALTERGUARDIAN_PHASE2_SPIKECOOLDOWN / 2
    -- TUNING.ALTERGUARDIAN_PHASE2_SUMMONCOOLDOWN = TUNING.ALTERGUARDIAN_PHASE2_SUMMONCOOLDOWN / 2

    -- 第三阶段属性
    -- TUNING.ALTERGUARDIAN_PHASE3_TRAP_CD = TUNING.ALTERGUARDIAN_PHASE3_TRAP_CD / 2
    TUNING.ALTERGUARDIAN_PHASE3_SUMMONCOOLDOWN = TUNING.ALTERGUARDIAN_PHASE3_SUMMONCOOLDOWN / 2
end

TUNING.ALTERGUARDIAN_PHASE1_MINROLLCOUNT = TUNING.ALTERGUARDIAN_PHASE1_MINROLLCOUNT * 2
TUNING.ALTERGUARDIAN_PHASE2_SPIN_SPEED = TUNING.ALTERGUARDIAN_PHASE2_SPIN_SPEED * 2
TUNING.ALTERGUARDIAN_PHASE2_SPIKE_LIFETIME = TUNING.ALTERGUARDIAN_PHASE2_SPIKE_LIFETIME * 2
TUNING.ALTERGUARDIAN_PHASE3_TRAP_LT = TUNING.ALTERGUARDIAN_PHASE3_TRAP_LT * 2
TUNING.ALTERGUARDIAN_PHASE3_TRAP_WORKS = TUNING.ALTERGUARDIAN_PHASE3_TRAP_WORKS * 2
TUNING.ALTERGUARDIAN_PHASE3_ATTACK_RANGE = TUNING.ALTERGUARDIAN_PHASE3_ATTACK_RANGE * 2
TUNING.ALTERGUARDIAN_PHASE3_SUMMONRSQ = TUNING.ALTERGUARDIAN_PHASE3_SUMMONRSQ + 225
TUNING.ALTERGUARDIAN_PHASE3_TARGET_DIST = TUNING.ALTERGUARDIAN_PHASE3_TARGET_DIST * 2

if alterguardianmode >= -1 then return end

-- ============================================================================
-- 竞技场相关组件初始化
AddPrefabPostInit("forest_network", function(inst)
    inst:AddComponent("alterguardian_floor_helper2hm")
end)

AddPrefabPostInit("world", function(inst)
    if not TheWorld.ismastersim then return end

    if not inst.components.alterguardian_arena_manager2hm then
        inst:AddComponent("alterguardian_arena_manager2hm")
    end
end)

-- ============================================================================
-- 是否在场内
function Map:IsPointInAlterguardianArena(x, y, z)
    local world = TheWorld
    if world == nil or world.net == nil or world.net.components.alterguardian_floor_helper2hm == nil then
        return false
    end
    return world.net.components.alterguardian_floor_helper2hm:IsPointInArena(x, y, z)
end

-- 结界是否激活
function Map:IsAlterguardianArenaBarrierUp()
    local world = TheWorld
    if world == nil or world.net == nil or world.net.components.alterguardian_floor_helper2hm == nil then
        return false
    end
    return world.net.components.alterguardian_floor_helper2hm:IsBarrierUp()
end

-- 获取中心坐标
function Map:GetAlterguardianArenaCenterXZ()
    local world = TheWorld
    if world == nil or world.net == nil or world.net.components.alterguardian_floor_helper2hm == nil then
        return nil, nil
    end
    return world.net.components.alterguardian_floor_helper2hm:GetArenaOrigin()
end

-- ============================================================================
-- -- 天体竞技场内禁用传送
-- local _original_IsTeleportingPermittedFromPointToPoint = IsTeleportingPermittedFromPointToPoint
-- IsTeleportingPermittedFromPointToPoint = function(fx, fy, fz, tx, ty, tz)
--     local world = TheWorld
--     if world and world.Map then
--         local map = world.Map
        
--         if map.IsAlterguardianArenaBarrierUp and map:IsAlterguardianArenaBarrierUp() then
--             local from_in_arena = map:IsPointInAlterguardianArena(fx, fy, fz)
--             local to_in_arena = map:IsPointInAlterguardianArena(tx, ty, tz)
--             if from_in_arena or to_in_arena then
--                 return false
--             end
--         end
--     end
    
--     if _original_IsTeleportingPermittedFromPointToPoint then
--         return _original_IsTeleportingPermittedFromPointToPoint(fx, fy, fz, tx, ty, tz)
--     end
    
--     return true
-- end

-- local _original_IsTeleportLinkingPermittedFromPoint = IsTeleportLinkingPermittedFromPoint
-- IsTeleportLinkingPermittedFromPoint = function(fx, fy, fz)
--     local world = TheWorld
--     if world and world.Map then
--         local map = world.Map

--         if map.IsAlterguardianArenaBarrierUp and map:IsAlterguardianArenaBarrierUp() 
--            and map:IsPointInAlterguardianArena(fx, fy, fz) then
--             return false
--         end
--     end
  
--     if _original_IsTeleportLinkingPermittedFromPoint then
--         return _original_IsTeleportLinkingPermittedFromPoint(fx, fy, fz)
--     end
    
--     return true
-- end

-- ============================================================================
-- 召唤时用额外的约束静电强化血量和奖励

-- 一阶段：10个月熠 → 30个碎片
CONSTRUCTION_PLANS["moon_device_construction1"] = {
    Ingredient("wagpunk_bits", 4),
    Ingredient("moonstorm_spark", 10), 
    Ingredient("moonglass_charged", 30) 
}

-- 二阶段：3静电槽 + 1宝球
CONSTRUCTION_PLANS["moon_device_construction2"] = {
    Ingredient("moonstorm_static_item", 1),
    Ingredient("moonstorm_static_item", 1),
    Ingredient("moonstorm_static_item", 1),
    Ingredient("moonrockseed", 1)
}

if not TUNING.ALTERGUARDIAN_ORIGINAL_HEALTH_BACKUP then
    TUNING.ALTERGUARDIAN_ORIGINAL_HEALTH_BACKUP = {
        PHASE1 = TUNING.ALTERGUARDIAN_PHASE1_HEALTH,
        PHASE2_MAX = TUNING.ALTERGUARDIAN_PHASE2_MAXHEALTH,
        PHASE2_START = TUNING.ALTERGUARDIAN_PHASE2_STARTHEALTH,
        PHASE3_MAX = TUNING.ALTERGUARDIAN_PHASE3_MAXHEALTH,
        PHASE3_START = TUNING.ALTERGUARDIAN_PHASE3_STARTHEALTH,
    }
end

TUNING.moon_device_static_count2hm = 0

local function UpdateAlterguardianHealth(static_count)
    local health_mult = static_count * 0.8
    
    TUNING.ALTERGUARDIAN_PHASE1_HEALTH = TUNING.ALTERGUARDIAN_ORIGINAL_HEALTH_BACKUP.PHASE1 * health_mult
    TUNING.ALTERGUARDIAN_PHASE2_MAXHEALTH = TUNING.ALTERGUARDIAN_ORIGINAL_HEALTH_BACKUP.PHASE2_MAX * health_mult
    TUNING.ALTERGUARDIAN_PHASE2_STARTHEALTH = TUNING.ALTERGUARDIAN_ORIGINAL_HEALTH_BACKUP.PHASE2_START * health_mult
    TUNING.ALTERGUARDIAN_PHASE3_MAXHEALTH = TUNING.ALTERGUARDIAN_ORIGINAL_HEALTH_BACKUP.PHASE3_MAX * health_mult
    TUNING.ALTERGUARDIAN_PHASE3_STARTHEALTH = TUNING.ALTERGUARDIAN_ORIGINAL_HEALTH_BACKUP.PHASE3_START * health_mult

end

-- 根据静电数量计算血量倍数
local function GetHealthMultFromStaticCount(static_count)
    return (static_count or 1) * 0.8
end

-- 天体血量设置函数（实体加载后使用，确保血上限能继承）
local function SetupAlterguardianHealth(inst, phase)
    if not inst.components.health then return end
    
    local static_count = inst.moon_device_static_count2hm or TUNING.moon_device_static_count2hm or 1
    static_count = math.max(1, math.min(3, static_count))
    local health_mult = GetHealthMultFromStaticCount(static_count)
    
    local target_maxhealth
    local backup = TUNING.ALTERGUARDIAN_ORIGINAL_HEALTH_BACKUP
    
    if phase == 1 then
        target_maxhealth = backup.PHASE1 * health_mult
    elseif phase == 2 then
        target_maxhealth = backup.PHASE2_START * health_mult
    elseif phase == 3 then
        target_maxhealth = backup.PHASE3_START * health_mult
    end
    
    if target_maxhealth then
        local current_health = inst.components.health.currenthealth
        local current_maxhealth = inst.components.health.maxhealth
        
        if math.abs(current_maxhealth - target_maxhealth) > 1 then

            local health_percent = current_health / current_maxhealth
            
            inst.components.health:SetMaxHealth(target_maxhealth)
            
            inst.components.health:SetCurrentHealth(target_maxhealth * health_percent)
        end
    end
end

AddPrefabPostInit("moon_device_construction2", function(inst)
    if not TheWorld.ismastersim then return end
    
    inst:DoTaskInTime(0, function(inst)
        if not inst.components.constructionsite then return end
        
        inst.static_slots_filled2hm = {false, false, false}
        
        -- 1-3个静电 + 1个宝球即可完成
        local old_IsComplete = inst.components.constructionsite.IsComplete
        inst.components.constructionsite.IsComplete = function(self)
            local static_count = 0
            for i = 1, 3 do
                if inst.static_slots_filled2hm[i] then
                    static_count = static_count + 1
                end
            end
            
            local moonrock_count = self:GetMaterialCount("moonrockseed")
            
            if static_count >= 1 and static_count <= 3 and moonrock_count >= 1 then
                return true
            end
            
            return old_IsComplete(self)
        end
        
        local old_AddMaterial = inst.components.constructionsite.AddMaterial
        inst.components.constructionsite.AddMaterial = function(self, prefab, num)
            if prefab == "moonstorm_static_item" then
                for i = 1, 3 do
                    if not inst.static_slots_filled2hm[i] then
                        -- 标记这个槽位已填充
                        inst.static_slots_filled2hm[i] = true
                        
                        self.inst.replica.constructionsite:SetSlotCount(i, 1)
                        
                        -- 更新materials表记录总数
                        if not self.materials[prefab] then
                            self.materials[prefab] = {amount = 1, slot = i}
                        else
                            self.materials[prefab].amount = self.materials[prefab].amount + 1
                        end

                        return 0
                    end
                end
                return num
            else
                return old_AddMaterial(self, prefab, num)
            end
        end
        
        -- 计算血量
        local old_OnConstruct = inst.components.constructionsite.OnConstruct
        inst.components.constructionsite.OnConstruct = function(self, doer, items)

            local result = old_OnConstruct(self, doer, items)
            
            -- 最终静电数量
            local static_count = 0
            for i = 1, 3 do
                if inst.static_slots_filled2hm[i] then
                    static_count = static_count + 1
                end
            end
            
            static_count = math.max(1, math.min(3, static_count))
            
            TUNING.moon_device_static_count2hm = static_count
            UpdateAlterguardianHealth(static_count)
            
            return result
        end

    end)
end)

-- ============================================================================
require "physics"
require "behaviours/follow"
local function nilfn() end
-- 天体宝珠矿强力开采
AddPrefabPostInit("rock_moon_shell", function(inst)
    if not TheWorld.ismastersim then
        return
    end
    
    if inst.components.workable then
        inst.components.workable:SetRequiresToughWork(true)
    end
end)

-- ============================================================================
-- 小地图图标
local function AddMinimapIcon(inst)
    if not inst.MiniMapEntity and not inst.icon2hm then
        local icon = SpawnPrefab("shadowchessicon2hm")
        if icon then
            icon:TrackEntity(inst)
            inst.icon2hm = icon
        end
    end
end

-- 月亮科技制作站
local function AddPrototyper(inst)
    if not inst.components.prototyper then
        inst:AddComponent("prototyper")
        inst.components.prototyper.trees = TUNING.PROTOTYPER_TREES.MOONORB_UPGRADED
    end
end
PROTOTYPER_DEFS.alterguardian_phase1 = PROTOTYPER_DEFS.moon_altar
PROTOTYPER_DEFS.alterguardian_phase2 = PROTOTYPER_DEFS.moon_altar
PROTOTYPER_DEFS.alterguardian_phase3 = PROTOTYPER_DEFS.moon_altar
PROTOTYPER_DEFS.alterguardian_phase3deadorb = PROTOTYPER_DEFS.moon_altar
PROTOTYPER_DEFS.alterguardian_phase3dead = PROTOTYPER_DEFS.moon_altar

-- ============================================================================
-- 季节锁定， 0=不锁定, 1=夏天, 2=春天, 3=冬天, 4=秋天
TUNING.alterguardianseason2hm = 0

-- 季节配置
local PHASE_SEASONS = {"summer", "spring", "winter", "autumn"}
-- 夏/春/冬的降水状态
local PHASE_PRECIPITATIONS = {false, true, true}  
-- 设置世界季节
local function SetWorldSeason(season)
    TheWorld:PushEvent("ms_setseason", season)
    SendModRPCToShard(GetShardModRPC("MOD_HARDMODE", "ms_setseason_update"), nil, season)
end

-- 季节锁定
local function TryLockSeason(inst)
    -- 检查是否满足锁定条件
    if not inst.alterguardianseason2hm or 
       (inst.alterguardianseason2hm < 4 and not TheWorld.state.isalterawake) or
       TUNING.alterguardianseason2hm > inst.alterguardianseason2hm or 
       (inst.components.health and inst.components.health:IsDead()) or
       (inst.components.workable and inst.components.workable.workleft <= 0) then
        return
    end
    
    -- 更新全局季节锁定状态
    if TUNING.alterguardianseason2hm < inst.alterguardianseason2hm then
        TheWorld:PushEvent("delayrefreshseason2hm")
    end
    TUNING.alterguardianseason2hm = inst.alterguardianseason2hm
    
    -- 设置季节
    local season = PHASE_SEASONS[TUNING.alterguardianseason2hm]
    if season and TheWorld.state.season ~= season then
        SetWorldSeason(season)
    end
    
    -- 设置降水
    local precipitation = PHASE_PRECIPITATIONS[TUNING.alterguardianseason2hm]
    if precipitation ~= nil then
        local current_has_precipitation = (TheWorld.state.precipitation ~= "none")
        if precipitation ~= current_has_precipitation then
            TheWorld:PushEvent("ms_forceprecipitation", precipitation)
        end
    end
end

local function AddSeasonLock(inst, phase_index, try_immediately)
    local can_enable = (inst.alterguardianseason2hm == nil)
    inst.alterguardianseason2hm = phase_index
    TUNING.alterguardianseason2hm = math.max(phase_index, TUNING.alterguardianseason2hm)
    
    if can_enable then
        inst:WatchWorldState("cycles", TryLockSeason)
    end
    
    TryLockSeason(inst)
end



-- ============================================================================
-- 月能汲取
-- ============================================================================

local MOON_ENERGY_ITEMS = {
    "moonstorm_spark",           -- 月熠
    "moonglass_charged",         -- 注能碎片
    "purebrilliance2hm",         -- 注能纯粹辉煌
    "alterguardianhat",          -- 启迪之冠
    "glasscutter"                -- 注能玻璃刀
}

local MOON_ENERGY_SEARCH_RANGE = 20

local function CanAbsorbMoonEnergy(item)
    if not item or not item:IsValid() then return false end
    
    local is_target = false
    for _, prefab in ipairs(MOON_ENERGY_ITEMS) do
        if item.prefab == prefab then
            is_target = true
            break
        end
    end
    
    if not is_target then return false end
    
    if not item.components.perishable then return false end
    
    local remaining = item.components.perishable.perishremainingtime
    
    if not remaining or remaining <= 0 then return false end
    
    return true
end

local function DoMoonEnergyAbsorption(inst)
    if not inst or not inst:IsValid() then return end
    
    if inst.components.health and inst.components.health:IsDead() then return end
    
    local x, y, z = inst.Transform:GetWorldPosition()
    
    local absorbed_count = 0
    local processed_items = {}
    
    local players = FindPlayersInRange(x, y, z, MOON_ENERGY_SEARCH_RANGE, true)
    
    for _, player in ipairs(players) do
        if player.components.inventory then
            local items = player.components.inventory:FindItems(function(item)
                if not item or not item:IsValid() or processed_items[item] then return false end
                
                for _, prefab in ipairs(MOON_ENERGY_ITEMS) do
                    if item.prefab == prefab then return true end
                end
                return false
            end)
            
            for _, item in ipairs(items) do
                if not processed_items[item] and CanAbsorbMoonEnergy(item) then
                    processed_items[item] = true
                    
                    local max_time = item.components.perishable.perishtime
                    local reduce_time = max_time * 0.2
                    item.components.perishable:AddTime(-reduce_time)
                    
                    absorbed_count = absorbed_count + 1
                end
            end
        end
    end
    
    local MOON_ENERGY_MUST_TAGS = {"_inventoryitem"}
    local MOON_ENERGY_CANT_TAGS = {"INLIMBO", "fire"}
    local entities = TheSim:FindEntities(x, y, z, MOON_ENERGY_SEARCH_RANGE, MOON_ENERGY_MUST_TAGS, MOON_ENERGY_CANT_TAGS)
    
    for _, item in ipairs(entities) do
        if not processed_items[item] and CanAbsorbMoonEnergy(item) then
            processed_items[item] = true
            
            local max_time = item.components.perishable.perishtime
            local reduce_time = max_time * 0.2
            item.components.perishable:AddTime(-reduce_time)
            
            absorbed_count = absorbed_count + 1
        end
    end
    
    if absorbed_count > 0 then
        local heal_amount = absorbed_count * 40
        
        if inst.components.health then
            inst.components.health:DoDelta(heal_amount, false, "moon_energy_absorption")
        end
    end
end

local function AddMoonEnergyAbsorption(inst)
    if not inst.moon_energy_absorption_task then
        inst.moon_energy_absorption_task = inst:DoPeriodicTask(5, DoMoonEnergyAbsorption)
    end
end

local function RemoveMoonEnergyAbsorption(inst)
    if inst.moon_energy_absorption_task then
        inst.moon_energy_absorption_task:Cancel()
        inst.moon_energy_absorption_task = nil
    end
end

-- ============================================================================
-- 天体在使用特定技能时生成临时分身，分身同步释放相同技能，技能结束后分身消失
-- ============================================================================

-- 分身淡出并移除
local function FadeOutAndRemoveShadow(shadow)
    if not shadow or not shadow:IsValid() then return end
    
    shadow:AddTag("NOCLICK")
    shadow:AddTag("notarget")
    shadow:StopBrain()
    
    if shadow.components.locomotor then
        shadow.components.locomotor:StopMoving()
    end
    if shadow.components.combat then
        shadow.components.combat:SetTarget(nil)
    end
    if shadow.components.health then
        shadow.components.health:SetInvincible(true)
    end
    if shadow.components.follower then
        shadow.components.follower:SetLeader(nil)
    end
    if shadow.entity and shadow.entity:GetParent() then
        local wx, wy, wz = shadow.Transform:GetWorldPosition()
        shadow.entity:SetParent(nil)
        shadow.Transform:SetPosition(wx, wy, wz)
    end
    if shadow._follow_task then
        shadow._follow_task:Cancel()
        shadow._follow_task = nil
    end
    if shadow.Physics then
        RemovePhysicsColliders(shadow)
    end
    if shadow.DynamicShadow then
        shadow.DynamicShadow:Enable(false)
    end
    if shadow.MiniMapEntity then
        shadow.MiniMapEntity:SetEnabled(false)
    end
    
    if not shadow.components.despawnfader2hm then
        shadow:AddComponent("despawnfader2hm")
    end
    shadow.components.despawnfader2hm.fn = function(inst) 
        inst:DoTaskInTime(0, inst.Remove) 
    end
    shadow.components.despawnfader2hm:FadeOut()
    
    if shadow.AnimState then
        shadow.AnimState:SetDeltaTimeMultiplier(1)
        shadow.AnimState:Pause()
    end

    shadow:DoTaskInTime(1.5, shadow.Remove)
end

-- 移除分身，技能结束时调用
local function RemoveSkillShadow(inst)
    if inst._skill_shadow and inst._skill_shadow:IsValid() then
        FadeOutAndRemoveShadow(inst._skill_shadow)
        inst._skill_shadow = nil
    end
end

-- 移除龙卷风分身，天二专用
local function RemoveTornadoShadow(inst)
    if inst._tornado_shadow and inst._tornado_shadow:IsValid() then
        FadeOutAndRemoveShadow(inst._tornado_shadow)
        inst._tornado_shadow = nil
    end
end

-- 创建临时技能分身
local function SpawnSkillShadow(inst, offset_angle, offset_distance, initial_state, state_data)
    if not inst or not inst:IsValid() then return nil end
 
    RemoveSkillShadow(inst)
    
    local x, y, z = inst.Transform:GetWorldPosition()
    local rotation = inst.Transform:GetRotation()
    
    -- 计算分身的生成位置
    offset_angle = offset_angle or (math.random() * 360)
    offset_distance = offset_distance or 3
    local rad = offset_angle * DEGREES
    local spawn_x = x + math.cos(rad) * offset_distance
    local spawn_z = z - math.sin(rad) * offset_distance
    
    -- 生成分身
    local shadow = SpawnPrefab(inst.prefab)
    if not shadow then return nil end
    
    shadow.Transform:SetPosition(spawn_x, y, spawn_z)
    -- 朝向与本体相同
    shadow.Transform:SetRotation(rotation)  
    
    shadow:AddTag("swc2hm")            
    shadow:AddTag("skill_shadow2hm")  
    shadow:AddTag("notarget")           
    shadow:AddTag("NOCLICK")            
    shadow.swp2hm = inst             
    shadow.persists = false            
    shadow.disablesw2hm = true      
    
    -- 暗影外观
    if shadow.AnimState then
        shadow.AnimState:SetMultColour(0, 0, 0, 0.5)
    end
    
    -- 禁用不需要的组件
    if shadow.components.lootdropper then
        shadow.components.lootdropper:SetLoot()
        shadow.components.lootdropper:SetChanceLootTable()
    end
    if shadow.components.health then
        shadow.components.health:SetInvincible(true)
    end
    if shadow.components.combat then
        -- 分身的攻击目标与本体相同
        if inst.components.combat and inst.components.combat.target then
            shadow.components.combat:SetTarget(inst.components.combat.target)
        end
    end
    
    -- 禁用小地图图标
    if shadow.MiniMapEntity then
        shadow.MiniMapEntity:SetEnabled(false)
    end
    
    -- 停止AI行为
    shadow:StopBrain()
    
    -- 淡入效果
    if not shadow.components.spawnfader2hm then
        shadow:AddComponent("spawnfader2hm")
    end
    shadow.components.spawnfader2hm:FadeIn()
    
    -- 如果指定了初始状态，让分身进入该状态
    if initial_state and shadow.sg then
        shadow:DoTaskInTime(0, function()
            if shadow:IsValid() and shadow.sg then
                shadow.sg:GoToState(initial_state, state_data)
            end
        end)
    end
    
    -- 记录分身
    inst._skill_shadow = shadow
    
    return shadow
end

-- 为天体一阶段设置技能分身（在翻滚时生成）
local function SetupPhase1SkillShadow(inst, target)
    -- 计算分身位置：在本体侧面
    local side_angle = inst.Transform:GetRotation() + (math.random() > 0.5 and 90 or -90)
    local shadow = SpawnSkillShadow(inst, side_angle, 4, "roll_start")
    
    if shadow then
        -- 标记为一阶段分身，以便在滚动时使用较慢的速度
        shadow._is_phase1_roll_shadow = true
        
        if shadow.sg then
            -- 让分身的翻滚朝向目标
            shadow:DoTaskInTime(FRAMES, function()
                if shadow:IsValid() and target and target:IsValid() then
                    local tx, ty, tz = target.Transform:GetWorldPosition()
                    shadow.Transform:SetRotation(shadow:GetAngleToPoint(tx, ty, tz))
                end
            end)
            
            -- 监听分身的翻滚结束
            shadow:ListenForEvent("newstate", function(shadow, data)
                if data and data.statename and 
                   (data.statename == "idle" or 
                    data.statename == "walk" or 
                    data.statename == "walk_start" or
                    data.statename == "hit") then
                    -- 翻滚技能结束，移除分身
                    if shadow:IsValid() and not shadow._removing then
                        shadow._removing = true
                        shadow:DoTaskInTime(1, function()
                            if shadow:IsValid() then
                                FadeOutAndRemoveShadow(shadow)
                            end
                        end)
                    end
                end
            end)
        end
    end
    
    return shadow
end

-- 为天体二阶段创建跟随龙卷风的分身
local function SpawnTornadoFollowShadow(inst, tornado, spin_speed_mult)
    if not inst or not inst:IsValid() or not tornado or not tornado:IsValid() then 
        return nil 
    end
    
    -- 如果已有龙卷风分身，先移除
    RemoveTornadoShadow(inst)
    
    local tx, ty, tz = tornado.Transform:GetWorldPosition()
    
    -- 生成分身
    local shadow = SpawnPrefab(inst.prefab)
    if not shadow then return nil end
    
    -- 设置分身标记
    shadow:AddTag("swc2hm")
    shadow:AddTag("skill_shadow2hm")
    -- 标记为龙卷风分身
    shadow:AddTag("tornado_shadow2hm")  
    shadow:AddTag("notarget")
    shadow:AddTag("NOCLICK")
    shadow.swp2hm = inst
    shadow.persists = false
    shadow.disablesw2hm = true
    shadow._bound_tornado = tornado                     -- 绑定的龙卷风
    shadow._spin_speed_mult = spin_speed_mult or 0.75   -- 旋转速度倍率
    
    -- 暗影外观
    if shadow.AnimState then
        shadow.AnimState:SetMultColour(0, 0, 0, 0.5)
    end
    
    -- 禁用不需要的组件
    if shadow.components.lootdropper then
        shadow.components.lootdropper:SetLoot()
        shadow.components.lootdropper:SetChanceLootTable()
    end
    if shadow.components.health then
        shadow.components.health:SetInvincible(true)
    end
    if shadow.components.combat then
        shadow.components.combat:SetTarget(nil)
    end
    
    if shadow.MiniMapEntity then
        shadow.MiniMapEntity:SetEnabled(false)
    end
    
    if shadow.Physics then
        RemovePhysicsColliders(shadow)
    end
    
    shadow:StopBrain()
    
    -- 淡入效果
    if not shadow.components.spawnfader2hm then
        shadow:AddComponent("spawnfader2hm")
    end
    shadow.components.spawnfader2hm:FadeIn()
    
    -- 绑定为龙卷风的子实体
    shadow.entity:SetParent(tornado.entity)
    shadow.Transform:SetPosition(0, 0, 0)  
    
    -- 缩小分身体型为原来的0.8倍
    if shadow.Transform then
        shadow.Transform:SetScale(0.8, 0.8, 0.8)
    end
    
    -- 停止状态机以防止动画被其他状态覆盖
    if shadow.sg then
        shadow.sg:Stop()
    end
    
    -- 播放旋转动画（与本体召唤时相同的动作）
    if shadow.AnimState then
        shadow.AnimState:PlayAnimation("attk_spin_loop", true)
        -- 设置旋转动画速度
        shadow.AnimState:SetDeltaTimeMultiplier(spin_speed_mult or 0.75)
    end
    
    -- 定期检查龙卷风是否存在（不再检查动画，因为已停止状态机）
    shadow._follow_task = shadow:DoPeriodicTask(0.5, function(shadow)
        if not shadow:IsValid() then return end
        
        local bound_tornado = shadow._bound_tornado
        if not bound_tornado or not bound_tornado:IsValid() then
            -- 龙卷风消失，解除绑定并移除分身
            shadow.entity:SetParent(nil)
            FadeOutAndRemoveShadow(shadow)
            return
        end
    end)
    
    -- 监听龙卷风移除事件
    shadow:ListenForEvent("onremove", function()
        if shadow:IsValid() and not shadow._removing then
            shadow._removing = true
            shadow.entity:SetParent(nil)
            FadeOutAndRemoveShadow(shadow)
        end
    end, tornado)
    
    -- 记录分身
    inst._tornado_shadow = shadow
    
    return shadow
end

-- ============================================================================
-- 第一阶段：地震流星 + 夏季环境
-- ============================================================================

-- 竞技场半径，虚影会覆盖整个竞技场
local PHASE1_ARENA_RADIUS = 28

-- 检查天一是否在竞技场中心（模块级函数，供状态图使用）
local function Phase1IsAtArenaCenter(inst)
    local manager = inst._arena_manager or TheWorld.components.alterguardian_arena_manager2hm
    if not manager then return true end  -- 没有竞技场则认为在中心
    
    local center_x, center_y, center_z = manager:GetArenaCenter()
    if not center_x then return true end
    
    local ix, iy, iz = inst.Transform:GetWorldPosition()
    local dist_sq = (ix - center_x)^2 + (iz - center_z)^2
    local at_center = dist_sq <= 16  -- 4格以内认为在中心
    return at_center
end

-- 获取竞技场中心位置（模块级函数，供状态图使用）
local function Phase1GetArenaCenter(inst)
    local manager = inst._arena_manager or TheWorld.components.alterguardian_arena_manager2hm
    if manager then
        local cx, cy, cz = manager:GetArenaCenter()
        if cx then
            return Point(cx, cy or 0, cz)
        end
    end
    return inst:GetPosition()
end

-- 沙尘暴天气
local function StartPhase1Sandstorm(inst)
    if not inst:IsValid() or (inst.components.health and inst.components.health:IsDead()) then
        return
    end

    if TheWorld.components.waterstreakrain2hm then
        TheWorld.components.waterstreakrain2hm.enablesand = true
        TheWorld.components.waterstreakrain2hm:Enable(true)
    end
end

-- 停止沙尘暴
local function StopPhase1Sandstorm(inst)
    
    if TheWorld.components.waterstreakrain2hm then
        TheWorld.components.waterstreakrain2hm.enablesand = false
        TheWorld.components.waterstreakrain2hm:Enable(false)
    end
end

-- 持续维持沙尘暴
local function MaintainSandstorm(inst)
    if not inst:IsValid() or (inst.components.health and inst.components.health:IsDead()) then
        StopPhase1Sandstorm(inst)
        return
    end
        
    if TheWorld.components.waterstreakrain2hm then
        TheWorld.components.waterstreakrain2hm.enablesand = true
        TheWorld.components.waterstreakrain2hm:Enable(true)
    end

end

-- 天体初始化
AddPrefabPostInit("alterguardian_phase1", function(inst)
    inst:AddTag("toughworker")
    
    if not TheWorld.ismastersim then
        return
    end
    
    if inst.components.burnable then
        inst:RemoveComponent("burnable")
    end
    
    -- 功能组件
    AddMinimapIcon(inst)
    AddPrototyper(inst)
    AddSeasonLock(inst, 1)  -- 锁定为夏季
    
    -- 流星雨
    if not inst.components.meteorshower then
        inst:AddComponent("meteorshower")
    end
    
    inst.moon_device_static_count2hm = TUNING.moon_device_static_count2hm or 1
    
    -- 血量保存和恢复
    if not inst.components.persistent2hm then
        inst:AddComponent("persistent2hm")
    end
    
    inst.onsave2hm = function(inst, data)
        data.static_count = inst.moon_device_static_count2hm
        if inst.components.health then
            data.health_percent = inst.components.health:GetPercent()
        end
    end
    
    inst.onload2hm = function(inst, data)
        if data then
            if data.static_count then
                inst.moon_device_static_count2hm = data.static_count
                TUNING.moon_device_static_count2hm = data.static_count
                UpdateAlterguardianHealth(data.static_count)
            end
        end
    end
    
    inst:DoTaskInTime(0, function()
        if inst:IsValid() and not inst:HasTag("swc2hm") and not inst:HasTag("skill_shadow2hm") then
            SetupAlterguardianHealth(inst, 1)
        end
    end)
    
    -- 月能汲取能力
    AddMoonEnergyAbsorption(inst)
    inst:ListenForEvent("death", function(inst)
        RemoveMoonEnergyAbsorption(inst)
    end)
    
    -- 禁用原版脱加载回血
    inst._start_sleep_time = nil
    inst:RemoveEventCallback("entitysleep", inst.OnEntitySleep)
    inst:RemoveEventCallback("entitywake", inst.OnEntityWake)
    inst.OnEntitySleep = function(inst) end
    inst.OnEntityWake = function(inst) end
    
    -- 激活竞技场
    inst:DoTaskInTime(0.1, function()
        if not inst:IsValid() or inst:HasTag("INLIMBO") then return end
        
        -- 不为暗影分身处理竞技场逻辑
        if inst:HasTag("swc2hm") or inst:HasTag("skill_shadow2hm") then return end
        
        local manager = TheWorld.components.alterguardian_arena_manager2hm
        if not manager then return end
        
        -- 已经被追踪了
        if inst._arena_manager or manager:GetBoss() == inst then
            inst._arena_manager = manager
            return
        end
        
        -- 尝试恢复连接（仅用于存档恢复的情况）
        if manager:TryRestoreConnection(inst) then
            inst._arena_manager = manager
            return
        end
        
        -- 检查是否有已存在的竞技场
        local helper = TheWorld.net and TheWorld.net.components.alterguardian_floor_helper2hm
        local marker = helper and helper:GetMarker()
        
        if marker and marker:IsValid() then
            -- 已有竞技场 marker，只追踪 Boss
            manager:TrackBoss(inst)
            inst._arena_manager = manager
            if not manager:IsInBattle() then
                manager:SetPhase(1)
            end
            if not manager:IsBarrierUp() then
                manager:RaiseBarrier()
            end
            return
        end
        
        -- 新生成的 Boss，创建竞技场
        local x, y, z = inst.Transform:GetWorldPosition()
        
        -- 生成持久化的 marker 实体
        manager:SpawnArenaMarker(x, y, z)
        
        manager:TrackBoss(inst)
        manager:RaiseBarrier()
        manager:SetPhase(1)  
        inst._arena_manager = manager
    end)
    
    -- 沙尘暴
    inst:DoTaskInTime(0.5, StartPhase1Sandstorm)
    -- 定期维持
    inst._sandstorm_task = inst:DoPeriodicTask(10, MaintainSandstorm)
    -- 死亡/移除时停止沙尘暴
    inst:ListenForEvent("death", StopPhase1Sandstorm)
    inst:ListenForEvent("onremove", StopPhase1Sandstorm)
    
    -- 死亡/移除时清理技能分身
    inst:ListenForEvent("death", function(inst)
        RemoveSkillShadow(inst)
    end)
    inst:ListenForEvent("onremove", function(inst)
        RemoveSkillShadow(inst)
    end)

    inst:ListenForEvent("death", function(inst)
        local manager = inst._arena_manager or TheWorld.components.alterguardian_arena_manager2hm
        if manager and manager:GetBoss() == inst then
            -- 一阶段死亡
            manager:SetPhase(2)
        end
    end)
    
    -- 强化虚影召唤技能：先移动到竞技场中心，三波虚影覆盖整个竞技场
    local original_EnterShield = inst.EnterShield
    
    local function DoEnhancedGestaltSummon(inst)
        -- 清除待召唤标记
        inst._pending_gestalt_summon = nil
        inst._roll_to_center_target = nil
        inst._is_summoning_gestalts = true
        
        -- 使用竞技场中心作为召唤中心
        local center = Phase1GetArenaCenter(inst)
        local cx, cy, cz = center:Get()
        
        local spawn_warning = SpawnPrefab("alterguardian_summon_fx")
        spawn_warning.Transform:SetScale(2.0, 2.0, 2.0)
        spawn_warning.Transform:SetPosition(cx, cy, cz)
        
        -- 基础虚影数量，随血量降低增加
        local health_percent = inst.components.health:GetPercent()
        local base_gestalts = 8 + math.ceil((1 - health_percent) * 12)
        
        -- 三波虚影，每波数量递增
        local ring_configs = {
            {delay = 0, count = base_gestalts, min_r = 5, max_r = 10},                              -- 第一波：内圈
            {delay = 0.8, count = base_gestalts + 4, min_r = 10, max_r = 18},                       -- 第二波：中圈，+4
            {delay = 1.6, count = base_gestalts + 8, min_r = 18, max_r = PHASE1_ARENA_RADIUS - 2},  -- 第三波：外圈，+8
        }
        
        for ring_idx, ring in ipairs(ring_configs) do
            inst:DoTaskInTime(ring.delay, function(inst2)
                if not inst2:IsValid() or (inst2.components.health and inst2.components.health:IsDead()) then
                    return
                end
                
                local angle_step = TWOPI / ring.count
                local initial_angle = TWOPI * math.random()
                
                for i = 1, ring.count do
                    inst2:DoTaskInTime(i * 0.08, function(inst3)
                        if not inst3:IsValid() or (inst3.components.health and inst3.components.health:IsDead()) then
                            return
                        end
                        
                        local gestalt = SpawnPrefab("gestalt_alterguardian_projectile")
                        if gestalt then
                            local r = GetRandomMinMax(ring.min_r, ring.max_r)
                            local angle = initial_angle + (i - 1) * angle_step + GetRandomWithVariance(0, PI / 12)
                            local x, z = r * math.cos(angle), r * math.sin(angle)
                            
                            gestalt.Transform:SetPosition(cx + x, cy, cz + z)
                            
                            -- 寻找最近玩家作为目标
                            local target = nil
                            local rangesq = 900  -- 30格范围
                            local gx, gy, gz = gestalt.Transform:GetWorldPosition()
                            
                            for _, v in ipairs(AllPlayers) do
                                if not IsEntityDeadOrGhost(v) and v.entity:IsVisible() then
                                    local distsq = v:GetDistanceSqToPoint(gx, 0, gz)
                                    if distsq < rangesq then
                                        rangesq = distsq
                                        target = v
                                    end
                                end
                            end
                            
                            if target then
                                gestalt:ForceFacePoint(target:GetPosition())
                                gestalt:SetTargetPosition(target:GetPosition())
                            end
                        end
                    end)
                end
            end)
        end
        
        -- 召唤结束后移除特效
        inst:DoTaskInTime(4, function(inst2)
            if spawn_warning and spawn_warning:IsValid() then
                spawn_warning:PushEvent("endloop")
            end
            if inst2:IsValid() then
                inst2._is_summoning_gestalts = nil
            end
        end)
        
        inst.components.timer:StartTimer("summon_cooldown", TUNING.ALTERGUARDIAN_PHASE1_SUMMONCOOLDOWN)
    end
    
    -- 移动到竞技场中心并召唤虚影
    local function Phase1MoveToCenter(inst)
        if not inst:IsValid() or (inst.components.health and inst.components.health:IsDead()) then
            return
        end
        
        local center = Phase1GetArenaCenter(inst)
        if not center then
            DoEnhancedGestaltSummon(inst)
            return
        end
        
        inst._moving_to_center = true
        inst.Physics:Stop()
        
        local speed = (TUNING.ALTERGUARDIAN_PHASE1_WALK_SPEED or 4) * 1.5
        inst:ForceFacePoint(center:Get())
        inst.Physics:SetMotorVelOverride(speed, 0, 0)
        
        if inst.AnimState then
            inst.AnimState:PlayAnimation("walk_loop", true)
        end
        
        inst._move_to_center_task = inst:DoPeriodicTask(0.1, function(inst)
            if not inst:IsValid() or not inst._moving_to_center then
                if inst._move_to_center_task then
                    inst._move_to_center_task:Cancel()
                    inst._move_to_center_task = nil
                end
                return
            end
            
            if Phase1IsAtArenaCenter(inst) then
                inst.Physics:ClearMotorVelOverride()
                inst.Physics:Stop()
                inst._moving_to_center = nil
                if inst._move_to_center_task then
                    inst._move_to_center_task:Cancel()
                    inst._move_to_center_task = nil
                end
                -- 到达中心，召唤虚影
                if not inst.components.timer:TimerExists("summon_cooldown") then
                    DoEnhancedGestaltSummon(inst)
                end
            else
                inst:ForceFacePoint(center:Get())
            end
        end)
        
        inst:DoTaskInTime(5, function(inst)
            if inst:IsValid() and inst._moving_to_center then
                inst.Physics:ClearMotorVelOverride()
                inst.Physics:Stop()
                inst._moving_to_center = nil
                if inst._move_to_center_task then
                    inst._move_to_center_task:Cancel()
                    inst._move_to_center_task = nil
                end
                -- 超时后直接召唤
                if not inst.components.timer:TimerExists("summon_cooldown") then
                    DoEnhancedGestaltSummon(inst)
                end
            end
        end)
    end
    
    inst.EnterShield = function(inst)
        inst._is_shielding = true
        inst.components.health:SetAbsorptionAmount(TUNING.ALTERGUARDIAN_PHASE1_SHIELDABSORB)
        
        if not inst.components.timer:TimerExists("summon_cooldown") then
            -- 检查是否在竞技场中心
            local at_center = Phase1IsAtArenaCenter(inst)
            
            if not at_center then
                -- 不在中心，先移动到中心
                inst._pending_gestalt_summon = true
                Phase1MoveToCenter(inst)
            else
                -- 已在中心，直接召唤
                DoEnhancedGestaltSummon(inst)
            end
        end
    end
    
    inst:DoPeriodicTask(1, function(inst)
        -- 护盾状态下、没有正在移动、没有正在召唤时检查
        if inst._is_shielding and not inst._moving_to_center and not inst._is_summoning_gestalts then
            if not inst.components.timer:TimerExists("summon_cooldown") then
                if Phase1IsAtArenaCenter(inst) then
                    DoEnhancedGestaltSummon(inst)
                else
                    Phase1MoveToCenter(inst)
                end
            end
        end
    end)

    inst:ListenForEvent("timerdone", function(inst, data)
        if data.name == "summon_cooldown" then
            if inst._is_shielding and not inst._moving_to_center and not inst._is_summoning_gestalts then
                -- 检查是否在中心
                if not Phase1IsAtArenaCenter(inst) then
                    inst._pending_gestalt_summon = true
                    Phase1MoveToCenter(inst)
                else
                    DoEnhancedGestaltSummon(inst)
                end
            end
        end
    end)
    
    -- 清理
    local function CleanupMoveState(inst)
        if inst._moving_to_center then
            inst.Physics:ClearMotorVelOverride()
            inst.Physics:Stop()
            inst._moving_to_center = nil
        end
        if inst._move_to_center_task then
            inst._move_to_center_task:Cancel()
            inst._move_to_center_task = nil
        end
        inst._pending_gestalt_summon = nil
        inst._is_summoning_gestalts = nil
    end
    
    inst:ListenForEvent("death", CleanupMoveState)
    inst:ListenForEvent("onremove", CleanupMoveState)
end)

-- 兼容天体仇灵
AddPrefabPostInit("alterguardian_phase1_lunarrift", function(inst)
    inst:AddTag("toughworker")
    
    if not TheWorld.ismastersim then
        return
    end
    
    if inst.components.burnable then
        inst:RemoveComponent("burnable")
    end
    
    if not inst.components.meteorshower then
        inst:AddComponent("meteorshower")
    end
end)

-- ----------------------------------------------------------------------------
-- 风滚草攻击
-- ----------------------------------------------------------------------------

-- 生成火焰风滚草攻击附近玩家
local function MakeFireTumbleweeds(inst)
    if TheWorld.state.season ~= "summer" then return end
    
    local x, y, z = inst.Transform:GetWorldPosition()
    local players = FindPlayersInRange(x, y, z, 30, true)
    local min_range_sq = math.huge
    
    for i, player in ipairs(players) do
        local dist_sq = player:GetDistanceSqToPoint(x, y, z)
        if dist_sq < min_range_sq and 
           inst.components.combat:CanTarget(player) and 
           player.userid then
            local px, py, pz = player.Transform:GetWorldPosition()
            local tumbleweed = SpawnPrefab("mod_hardmode_tumbleweed")
            -- 在玩家身后36单位处生成风滚草
            tumbleweed.Transform:SetPosition(
                px - math.cos(tumbleweed.angle) * 36, 
                py, 
                pz + math.sin(tumbleweed.angle) * 36
            )
        end
    end
end

-- ----------------------------------------------------------------------------
-- 地震陷坑攻击
-- ----------------------------------------------------------------------------

local SINKHOLD_BLOCKER_TAGS = {"antlion_sinkhole_blocker"}
local IsValidSinkholePosition_x, IsValidSinkholePosition_z

-- 延迟转换陷坑
local function SinkholeDelayChange(inst)
    -- 陷坑非持久且使用自定义的消失方式来消失，从而节约性能
    local eyeofterror_sinkhole = SpawnPrefab("eyeofterror_sinkhole")
    eyeofterror_sinkhole.Transform:SetPosition(inst.Transform:GetWorldPosition())
    eyeofterror_sinkhole:PushEvent("docollapse")
    eyeofterror_sinkhole.components.timer:SetTimeLeft("repair", 360)
    inst:Remove()
end

-- 检查位置是否可以生成陷坑
local function IsValidSinkholePosition(offset)
    local x1 = IsValidSinkholePosition_x + offset.x
    local z1 = IsValidSinkholePosition_z + offset.z
    
    -- 检查是否有阻挡物
    if #TheSim:FindEntities(x1, 0, z1, TUNING.ANTLION_SINKHOLE.RADIUS / 2 * 1.9, SINKHOLD_BLOCKER_TAGS) > 0 then
        return false
    end
    
    -- 检查地形是否可通行
    for dx = -1, 1 do
        for dz = -1, 1 do
            if not TheWorld.Map:IsPassableAtPoint(
                x1 + dx * TUNING.ANTLION_SINKHOLE.RADIUS / 2, 
                0, 
                z1 + dz * TUNING.ANTLION_SINKHOLE.RADIUS / 2, 
                false, 
                true
            ) then
                return false
            end
        end
    end
    
    return true
end

-- 在指定位置生成陷坑
local function SpawnSinkhole(spawn_point)
    local x = GetRandomWithVariance(spawn_point.x, TUNING.ANTLION_SINKHOLE.RADIUS / 2)
    local z = GetRandomWithVariance(spawn_point.z, TUNING.ANTLION_SINKHOLE.RADIUS / 2)
    IsValidSinkholePosition_x = x
    IsValidSinkholePosition_z = z
    
    -- 尝试在多个半径范围内查找有效位置
    local offset = FindValidPositionByFan(math.random() * 2 * PI, TUNING.ANTLION_SINKHOLE.RADIUS / 2 * 1.8 + math.random(), 9, IsValidSinkholePosition) or
                   FindValidPositionByFan(math.random() * 2 * PI, TUNING.ANTLION_SINKHOLE.RADIUS / 2 * 2.9 + math.random(), 17, IsValidSinkholePosition) or
                   FindValidPositionByFan(math.random() * 2 * PI, TUNING.ANTLION_SINKHOLE.RADIUS / 2 * 3.9 + math.random(), 17, IsValidSinkholePosition) or
                   nil
    
    if offset ~= nil then
        local antlion_sinkhole = SpawnPrefab("antlion_sinkhole")
        antlion_sinkhole.persists = false
        antlion_sinkhole.Transform:SetPosition(x + offset.x, 0, z + offset.z)
        antlion_sinkhole:PushEvent("startcollapse")
        antlion_sinkhole:DoTaskInTime(3 + math.random(), SinkholeDelayChange)
    end
end

-- 对目标位置生成陷坑
local function DoSinkholesAttack(inst)
    if inst.components.combat.target then
        local target_pos = inst.components.combat.target:GetPosition()
        SpawnSinkhole(target_pos)
    end
end

-- 生成环形陷坑攻击
local function DoCircularSinkholesAttack(inst, segments, radius, start_angle)
    
    local x, y, z = inst.Transform:GetWorldPosition()
    
    -- 破坏码头
    if TheWorld.components.dockmanager ~= nil then
        TheWorld.components.dockmanager:DamageDockAtPoint(x, y, z, 1000)
    end
    
    -- 计算环形陷坑位置
    local segment_angle = (segments > 0 and 360 / segments or 360)
    local start = start_angle or math.random(0, 360)
    
    -- 收集所有陷坑位置
    local sinkhole_positions = {}
    for mid_angle = -start, 360 - start, segment_angle do
        local offset = Vector3(
            radius * math.cos(mid_angle), 
            0, 
            -radius * math.sin(mid_angle)
        )
        table.insert(sinkhole_positions, Vector3(x + offset.x, 0, z + offset.z))
    end
    
    -- 将陷坑分成三批生成
    local total_count = #sinkhole_positions
    local batch_size = math.ceil(total_count / 3)
    
    local batch1_end = math.min(batch_size, total_count)
    for i = 1, batch1_end do
        SpawnSinkhole(sinkhole_positions[i])
    end
    
    if batch1_end < total_count then
        inst:DoTaskInTime(2, function()
            if not inst:IsValid() then return end
            local batch2_end = math.min(batch_size * 2, total_count)
            for i = batch1_end + 1, batch2_end do
                SpawnSinkhole(sinkhole_positions[i])
            end
        end)
    end
    
    if batch_size * 2 < total_count then
        inst:DoTaskInTime(4, function()
            if not inst:IsValid() then return end
            for i = batch_size * 2 + 1, total_count do
                SpawnSinkhole(sinkhole_positions[i])
            end
        end)
    end
    
    inst:DoTaskInTime(1, function()
        if inst:IsValid() then
            DoSinkholesAttack(inst)
        end
    end)
end

-- ----------------------------------------------------------------------------
-- 流星攻击
-- ----------------------------------------------------------------------------

-- 生成流星攻击玩家
local function DoShadowMeteorAttack(inst)
    
    local x, y, z = inst.Transform:GetWorldPosition()
    local players = FindPlayersInRange(x, y, z, 30, true)
    local min_range_sq = math.huge
    
    for i, player in ipairs(players) do
        local dist_sq = player:GetDistanceSqToPoint(x, y, z)
        if dist_sq < min_range_sq and inst.components.combat:CanTarget(player) then
            local meteor = SpawnPrefab("shadowmeteor")
            meteor.Transform:SetPosition(player.Transform:GetWorldPosition())
            meteor:SetSize("large", 1)
            meteor:SetPeripheral(false)
        end
    end
end

-- ----------------------------------------------------------------------------
-- 第一阶段状态图增强
-- ----------------------------------------------------------------------------

AddStategraphPostInit("alterguardian_phase1", function(sg)
    -- 空闲状态：触发季节锁定
    local OnEnterIdle = sg.states.idle.onenter
    sg.states.idle.onenter = function(inst, ...)
        OnEnterIdle(inst, ...)
        TryLockSeason(inst)
    end
    
    -- 滚动开始：生成风滚草和技能分身
    if sg.states.roll_start then
        local OnEnterRollStart = sg.states.roll_start.onenter
        sg.states.roll_start.onenter = function(inst, ...)
            MakeFireTumbleweeds(inst)
            
            -- 生成技能分身（只有本体才会生成，分身不会再生成分身）
            if not inst:HasTag("skill_shadow2hm") and not inst:HasTag("swc2hm") then
                local target = inst.components.combat and inst.components.combat.target
                SetupPhase1SkillShadow(inst, target)
            end
            
            OnEnterRollStart(inst, ...)
        end
    end
    
    -- 滚动中：增强滚动效果
    local OnEnterRoll = sg.states.roll.onenter
    sg.states.roll.onenter = function(inst, ...)
        -- 海上时滚向最近的存活玩家
        if inst.components.combat and inst.components.combat.target then
            local tx, ty, tz = inst.components.combat.target.Transform:GetWorldPosition()
            inst.Transform:SetRotation(inst:GetAngleToPoint(tx, ty, tz))
        elseif inst:IsOnOcean() then
            local target = FindClosestPlayerToInst(inst, 10000, true)
            if target and target:IsValid() then
                local tx, ty, tz = target.Transform:GetWorldPosition()
                inst.Transform:SetRotation(inst:GetAngleToPoint(tx, ty, tz))
            end
        end
        
        OnEnterRoll(inst, ...)
        
        local current_speed, y, z = inst.Physics:GetMotorVel()
        if inst._is_phase1_roll_shadow then
            -- 分身使用原速度的0.7倍，错开攻击频率
            inst.Physics:SetMotorVelOverride(current_speed * 0.7, y, z)
        else
            -- 本体增强速度
            inst.Physics:SetMotorVelOverride(current_speed * 1.3, y, z)
        end
        
        -- 概率增加滚动次数
        if not inst:HasTag("skill_shadow2hm") and
           inst.sg.mem._num_rolls > 4 and 
           math.random() < 0.35 and 
           inst.sg.mem._num_rolls then
            inst.sg.mem._num_rolls = inst.sg.mem._num_rolls + 1
        end
    end
    
    -- 添加 roll 状态的 onupdate 来检查是否到达中心
    local OnUpdateRoll = sg.states.roll.onupdate
    sg.states.roll.onupdate = function(inst)
        if OnUpdateRoll then
            OnUpdateRoll(inst)
        end
        
        -- 如果正在翻滚回中心，检查是否已经靠近中心
        if inst._roll_to_center_target and inst._pending_gestalt_summon then
            if Phase1IsAtArenaCenter(inst) then
                -- 已经到达中心，清除翻滚目标
                -- 定期检查任务会处理虚影召唤
                inst._roll_to_center_target = nil
            end
        end
    end
    
    -- 滚动超时：修改碰撞玩家后的行为
    local OnRollTimeout = sg.states.roll.ontimeout
    sg.states.roll.ontimeout = function(inst, ...)
        if inst.sg.statemem.hitplayer and 
           inst.sg.mem._num_rolls > 0 then
            -- 首次攻击到玩家也不会停下
            inst.sg.statemem.hitplayer = nil
            inst.sg.mem._num_rolls = math.min(inst.sg.mem._num_rolls - 2, 4)
        end
        OnRollTimeout(inst, ...)
    end
    
    -- 滚动结束：生成风滚草，并在稍后清理技能分身
    local OnEnterRollStop = sg.states.roll_stop.onenter
    sg.states.roll_stop.onenter = function(inst, ...)
        MakeFireTumbleweeds(inst)
        OnEnterRollStop(inst, ...)
        
        -- 翻滚结束后清理技能分身（延迟一点以确保分身也完成了翻滚）
        if inst._skill_shadow and not inst:HasTag("skill_shadow2hm") then
            inst:DoTaskInTime(2, function()
                RemoveSkillShadow(inst)
            end)
        end
    end
    
    -- 砸地：产生环形AOE地震
    local OnEnterTantrum = sg.states.tantrum.onenter
    sg.states.tantrum.onenter = function(inst, ...)
        -- 记录AOE次数
        if inst.sg.mem.aoes_remaining == nil or inst.sg.mem.aoes_remaining == 0 then
            inst.aoessinkhole2hm = false
        end
        
        OnEnterTantrum(inst, ...)
        
        if inst.aoessinkhole2hm == false and inst.sg.mem.aoes_remaining then
            inst.aoessinkhole2hm = inst.sg.mem.aoes_remaining + 1
        end
    end
    
    -- 砸地时产生环形陷坑
    AddStateTimeEvent2hm(sg.states.tantrum, 7 * FRAMES, function(inst)
        if inst.aoessinkhole2hm and 
           inst.sg.mem.aoes_remaining and 
           (inst.aoessinkhole2hm - inst.sg.mem.aoes_remaining) % 2 == 1 then
            local segment_count = 4 + (inst.aoessinkhole2hm - inst.sg.mem.aoes_remaining)
            local ring_radius = segment_count * TUNING.ANTLION_SINKHOLE.RADIUS
            DoCircularSinkholesAttack(inst, segment_count, ring_radius)
        end
    end)
    
    -- 添加走路到中心后进入护盾的状态，翻滚的话距离难以精确控制
    local walk_to_center_for_shield_state = State{
        name = "walk_to_center_for_shield",
        -- charge标签让Phase1的locomote事件处理器忽略这个状态
        -- moving标签标记我们正在移动
        tags = {"busy", "canrotate", "charge", "moving"},
        
        onenter = function(inst, data)
            -- 获取竞技场中心
            local manager = inst._arena_manager or TheWorld.components.alterguardian_arena_manager2hm
            if manager then
                local cx, cy, cz = manager:GetArenaCenter()
                if cx and cz then
                    inst.sg.statemem.center = Point(cx, cy or 0, cz)
                end
            end
            
            if not inst.sg.statemem.center then
                inst.sg:GoToState("shield_pre")
                return
            end
            
            inst._walking_to_center_for_shield = true
            inst:ForceFacePoint(inst.sg.statemem.center:Get())
            
            -- 较快的临时速度
            local original_speed = inst.components.locomotor.walkspeed
            inst.sg.statemem.original_speed = original_speed
            inst.components.locomotor.walkspeed = (TUNING.ALTERGUARDIAN_PHASE1_WALK_SPEED or 4) * 1.6
            
            inst.components.locomotor:WalkForward()
            
            inst.AnimState:PlayAnimation("walk_loop", true)
            
            inst.sg:SetTimeout(15)
        end,
        
        onupdate = function(inst)
            local center = inst.sg.statemem.center
            if center then

                inst:ForceFacePoint(center:Get())

                inst.components.locomotor:WalkForward()
                
                local dist_sq = inst:GetDistanceSqToPoint(center:Get())
                
                if dist_sq <= 9 then  -- 3格以内认为到达中心
                    inst.sg:GoToState("walk_to_center_for_shield_stop")
                end
            end
        end,
        
        ontimeout = function(inst)
            -- 超时后强制进入护盾
            inst.sg:GoToState("walk_to_center_for_shield_stop")
        end,
        
        events = {
            -- 覆盖locomote事件，继续朝目标移动
            EventHandler("locomote", function(inst)
                if inst.sg.statemem.center then
                    inst:ForceFacePoint(inst.sg.statemem.center:Get())
                    inst.components.locomotor:WalkForward()
                end
            end),
        },
        
        onexit = function(inst)
            -- 恢复速度
            if inst.sg.statemem.original_speed then
                inst.components.locomotor.walkspeed = inst.sg.statemem.original_speed
            end
            inst.components.locomotor:Stop()
        end,
    }
    
    -- 走到中心后的停止状态，播放停止动画然后进入护盾
    local walk_to_center_for_shield_stop_state = State{
        name = "walk_to_center_for_shield_stop",
        tags = {"busy", "nointerrupt"},
        
        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("walk_pst")
        end,
        
        events = {
            EventHandler("animover", function(inst)
                inst._walking_to_center_for_shield = nil
                inst.sg:GoToState("shield_pre")
            end),
            -- 取消locomote事件
            EventHandler("locomote", function(inst) end),
        },
        
        onexit = function(inst)
            inst._walking_to_center_for_shield = nil
        end,
    }
    
    sg.states["walk_to_center_for_shield"] = walk_to_center_for_shield_state
    sg.states["walk_to_center_for_shield_stop"] = walk_to_center_for_shield_stop_state

    -- 插盾牌前检查是否需要翻滚到中心
    local original_entershield_handler = sg.events["entershield"]
    
    if original_entershield_handler then
        sg.events["entershield"] = EventHandler("entershield", function(inst)
            if inst.components.health:IsDead() then
                return
            end
            
            -- 会在走路结束后自动进入护盾
            if inst._walking_to_center_for_shield then
                return
            end
            
            local is_busy = inst.sg:HasStateTag("busy")
            local is_idle = inst.sg:HasStateTag("idle")
            if is_busy and not is_idle then
                return
            end
            
            local manager = inst._arena_manager or TheWorld.components.alterguardian_arena_manager2hm
            if manager then
                local cx, cy, cz = manager:GetArenaCenter()
                if cx and cz then
                    local ix, iy, iz = inst.Transform:GetWorldPosition()
                    local dist_sq = (ix - cx)^2 + (iz - cz)^2
                    if dist_sq > 16 then  -- 4格以外，需要先走回中心
                        inst.sg:GoToState("walk_to_center_for_shield")
                        return
                    end
                end
            end
            
            inst.sg:GoToState("shield_pre")
        end)
    end
    
    -- 护盾前：启动流星雨
    local OnEnterShieldPre = sg.states.shield_pre.onenter
    sg.states.shield_pre.onenter = function(inst, ...)
        OnEnterShieldPre(inst, ...)
        
        inst.components.meteorshower:StopShower()
        inst.components.meteorshower:StartShower()
    end
    
    -- 护盾结束：定点流星砸击
    local OnEnterShieldEnd = sg.states.shield_end.onenter
    sg.states.shield_end.onenter = function(inst, ...)
        OnEnterShieldEnd(inst, ...)
        DoShadowMeteorAttack(inst)
    end


end)

-- ============================================================================
-- 第二阶段：风雨雷电 + 春季环境
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 第二阶段碰撞系统
-- ----------------------------------------------------------------------------

-- 清除碰撞记录
local function ClearRecentlyCharged(inst, other)
    inst.recentlycharged[other] = nil
end

-- 销毁碰撞对象
local function OnDestroyOther(inst, other)
    if other:IsValid() and 
       other.components.workable ~= nil and 
       other.components.workable:CanBeWorked() and 
       other.components.workable.action ~= ACTIONS.NET and
       not inst.recentlycharged[other] then
        SpawnPrefab("collapse_small").Transform:SetPosition(other.Transform:GetWorldPosition())
        other.components.workable:Destroy(inst)
        
        -- 如果对象仍然存在且可工作，添加到冷却列表
        if other:IsValid() and 
           other.components.workable ~= nil and 
           other.components.workable:CanBeWorked() then
            inst.recentlycharged[other] = true
            inst:DoTaskInTime(3, ClearRecentlyCharged, other)
        end
    end
end

-- 第二阶段碰撞处理
local function OnPhase2Collide(inst, other)
    if other and other:IsValid() then
        -- 水稻兼容，顺手抄龙卷风
        if other.prefab == "riceplant" and 
           TUNING.DSTU and 
           other.components.pickable and 
           not inst.recentlycharged[other] then
            other.components.lootdropper:SpawnLootPrefab("rice")
            other.components.pickable:Pick()
            if other:IsValid() then
                inst.recentlycharged[other] = true
                inst:DoTaskInTime(3, ClearRecentlyCharged, other)
            end
            return
        end
        
        if other.components.workable ~= nil and 
           other.components.workable:CanBeWorked() and 
           other.components.workable.action ~= ACTIONS.NET and 
           not inst.recentlycharged[other] then
            inst:DoTaskInTime(2 * FRAMES, OnDestroyOther, other)
        end
    end
end

-- ----------------------------------------------------------------------------
-- 第二阶段召唤和初始化
-- ----------------------------------------------------------------------------
-- 第二阶段水球雨/龙卷风天气

local function StartPhase2Weather(inst)
    if not inst:IsValid() or (inst.components.health and inst.components.health:IsDead()) then
        return
    end
  
    if TheWorld.state.precipitation == "none" then
        TheWorld:PushEvent("ms_forceprecipitation", true)
    end
    
    if TUNING.DSTU then
        if TheWorld.components.um_stormspawner and not TheSim:FindFirstEntityWithTag("um_tornado") then
            TheWorld:PushEvent("forcetornado")
        end
    else
        if TheWorld.components.waterstreakrain2hm then
            TheWorld.components.waterstreakrain2hm.enablerain = true
            TheWorld.components.waterstreakrain2hm:Enable(true)
        end
    end
end

-- 停止第二阶段天气
local function StopPhase2Weather(inst)
    if TheWorld.components.waterstreakrain2hm then
        TheWorld.components.waterstreakrain2hm.enablerain = false
        TheWorld.components.waterstreakrain2hm:Enable(false)
    end
end

-- 持续维持第二阶段天气
local function MaintainPhase2Weather(inst)
    if not inst:IsValid() or (inst.components.health and inst.components.health:IsDead()) then
        StopPhase2Weather(inst)
        return
    end
    
    -- 持续降雨
    if TheWorld.state.precipitation == "none" then
        TheWorld:PushEvent("ms_forceprecipitation", true)
    end
end

-- ----------------------------------------------------------------------------
-- 第二阶段尖刺攻击系统
-- ----------------------------------------------------------------------------

local SPIKE_DISTANCE_SQ = TUNING.ALTERGUARDIAN_PHASE2_SPIKE_RANGE * TUNING.ALTERGUARDIAN_PHASE2_SPIKE_RANGE
local spawn_spike_with_target       -- 原版尖刺生成函数的引用
local phase2_spike_target           -- 临时存储尖刺的目标玩家

-- ----------------------------------------------------------------------------
-- DPS追踪系统（用于动态调整旋转速度）
-- ----------------------------------------------------------------------------
local DPS_TRACKING_WINDOW = 5  -- 追踪最近5秒的伤害
local DPS_HIGH_THRESHOLD = 300  -- DPS阈值，超过此值时增加移速

-- 初始化DPS追踪
local function InitDPSTracker(inst)
    inst._dps_tracker2hm = {
        damages = {},       -- {time, amount} 记录每次伤害
        last_update = 0,
    }
end

-- 记录一次伤害
local function RecordDamage(inst, amount)
    if not inst._dps_tracker2hm then return end
    
    local now = GetTime()
    table.insert(inst._dps_tracker2hm.damages, {time = now, amount = amount})
    
    -- 清理过期记录
    local cutoff = now - DPS_TRACKING_WINDOW
    local new_damages = {}
    for _, record in ipairs(inst._dps_tracker2hm.damages) do
        if record.time >= cutoff then
            table.insert(new_damages, record)
        end
    end
    inst._dps_tracker2hm.damages = new_damages
end

-- 计算当前DPS
local function CalculateCurrentDPS(inst)
    if not inst._dps_tracker2hm then return 0 end
    
    local now = GetTime()
    local cutoff = now - DPS_TRACKING_WINDOW
    local total_damage = 0
    
    for _, record in ipairs(inst._dps_tracker2hm.damages) do
        if record.time >= cutoff then
            total_damage = total_damage + record.amount
        end
    end
    
    return total_damage / DPS_TRACKING_WINDOW
end

-- 检查是否处于高DPS状态
local function IsHighDPS(inst)
    return CalculateCurrentDPS(inst) >= DPS_HIGH_THRESHOLD
end

-- 第二阶段初始化
AddPrefabPostInit("alterguardian_phase2", function(inst)
    inst:AddTag("toughworker")
    inst:AddTag("electricdamageimmune")
    inst:AddTag("tornado_nosucky")
    inst:AddTag("noauradamage")  -- 免疫龙卷风碰撞伤害（DSTU龙卷风使用此标签排除伤害）
    
    if not TheWorld.ismastersim then return end
  
    InitDPSTracker(inst)
    
    -- 追踪DPS
    inst:ListenForEvent("healthdelta", function(inst, data)
        if data and data.amount and data.amount < 0 then
            RecordDamage(inst, -data.amount)
        end
    end)
    
    AddMinimapIcon(inst)
    AddPrototyper(inst)
    AddSeasonLock(inst, 2)  -- 锁定为春季
    
    -- 继承阶段1的竞技场管理
    inst:DoTaskInTime(0, function()
        if not inst:IsValid() then return end
        
        -- 不为暗影分身处理竞技场逻辑
        if inst:HasTag("swc2hm") or inst:HasTag("skill_shadow2hm") then return end
        
        local manager = TheWorld.components.alterguardian_arena_manager2hm
        if not manager then return end
        
        -- 已被追踪（存档恢复的情况）
        if inst._arena_manager or manager:GetBoss() == inst then
            inst._arena_manager = manager
            return
        end
        
        -- 尝试恢复连接（处理存档恢复的情况）
        if manager:TryRestoreConnection(inst) then
            inst._arena_manager = manager
            return
        end
        
        -- 检查是否有已存在的竞技场
        local helper = TheWorld.net and TheWorld.net.components.alterguardian_floor_helper2hm
        local marker = helper and helper:GetMarker()
        
        -- 阶段切换或存档恢复
        manager:TrackBoss(inst)
        inst._arena_manager = manager
        if manager:GetPhase() ~= 2 then
            manager:SetPhase(2)
        end
        -- 确保结界激活
        if not manager:IsBarrierUp() and marker then
            manager:RaiseBarrier()
        end
    end)
    
    -- 水球雨/龙卷风天气
    inst:DoTaskInTime(0.5, StartPhase2Weather)
    inst._weather_task = inst:DoPeriodicTask(10, MaintainPhase2Weather)
    -- 死亡/移除时停止天气
    inst:ListenForEvent("death", StopPhase2Weather)
    inst:ListenForEvent("onremove", StopPhase2Weather)
    
    -- 死亡/移除时清理龙卷风分身
    inst:ListenForEvent("death", function(inst)
        RemoveTornadoShadow(inst)
    end)
    inst:ListenForEvent("onremove", function(inst)
        RemoveTornadoShadow(inst)
    end)
    
    inst:ListenForEvent("death", function(inst)
        local manager = inst._arena_manager or TheWorld.components.alterguardian_arena_manager2hm
        if manager and manager:GetBoss() == inst then
            -- 二阶段死亡
            manager:SetPhase(3)
        end
    end)
    
    -- 设置碰撞回调
    if inst.GUID and inst.Physics and not PhysicsCollisionCallbacks[inst.GUID] then
        inst.recentlycharged = {}
        inst.Physics:SetCollisionCallback(OnPhase2Collide)
    end
    
    inst.moon_device_static_count2hm = TUNING.moon_device_static_count2hm or 1
    
    -- 血量保存和恢复
    if not inst.components.persistent2hm then
        inst:AddComponent("persistent2hm")
    end
    
    inst.onsave2hm = function(inst, data)
        data.static_count = inst.moon_device_static_count2hm
        if inst.components.health then
            data.health_percent = inst.components.health:GetPercent()
        end
    end
    
    inst.onload2hm = function(inst, data)
        if data then
            if data.static_count then
                inst.moon_device_static_count2hm = data.static_count
                TUNING.moon_device_static_count2hm = data.static_count
                UpdateAlterguardianHealth(data.static_count)
            end
        end
    end
    
    inst:DoTaskInTime(0, function()
        if inst:IsValid() and not inst:HasTag("swc2hm") and not inst:HasTag("skill_shadow2hm") then
            SetupAlterguardianHealth(inst, 2)
        end
    end)
    
    -- 月能汲取能力
    AddMoonEnergyAbsorption(inst)
    inst:ListenForEvent("death", function(inst)
        RemoveMoonEnergyAbsorption(inst)
    end)

    inst._start_sleep_time = nil
    if inst.OnEntitySleep then
        inst:RemoveEventCallback("entitysleep", inst.OnEntitySleep)
    end
    if inst.OnEntityWake then
        inst:RemoveEventCallback("entitywake", inst.OnEntityWake)
    end
    inst.OnEntitySleep = function(inst) end
    inst.OnEntityWake = function(inst) end
    
    -- 增强尖刺攻击：使尖刺瞄准所有附近玩家而非随机目标
    if inst.DoSpikeAttack then
        if not spawn_spike_with_target then
            spawn_spike_with_target = getupvalue2hm(inst.DoSpikeAttack, "spawn_spike_with_target")
        end
        
        if spawn_spike_with_target then
            local original_DoSpikeAttack = inst.DoSpikeAttack
            inst.DoSpikeAttack = function(inst, ...)
                -- 收集范围内的所有存活玩家
                local targets = {}
                local inst_pos = inst:GetPosition()
                for _, player in ipairs(AllPlayers) do
                    if not player:HasTag("playerghost") and 
                       player.entity:IsVisible() and 
                       (player.components.health ~= nil and not player.components.health:IsDead()) and
                       player:GetDistanceSqToPoint(inst_pos:Get()) < SPIKE_DISTANCE_SQ then
                        table.insert(targets, player)
                    end
                end
                
                if IsTableEmpty(targets) then
                    return original_DoSpikeAttack(inst, ...)
                end
                
                local original_DoTaskInTime = inst.DoTaskInTime
                inst.DoTaskInTime = function(inst, time, fn, ...)
                    if fn == spawn_spike_with_target and not IsTableEmpty(targets) then
                        local target = table.remove(targets, #targets)
                        if target and target:IsValid() then
                            return original_DoTaskInTime(inst, time, function(...)
                                phase2_spike_target = target
                                fn(...)
                                phase2_spike_target = nil
                            end, ...)
                        end
                    end
                    return original_DoTaskInTime(inst, time, fn, ...)
                end
                
                original_DoSpikeAttack(inst, ...)
                inst.DoTaskInTime = original_DoTaskInTime
            end
        end
    end
end)

-- ----------------------------------------------------------------------------
-- 第二阶段旋风攻击
-- ----------------------------------------------------------------------------

local ARENA_TORNADO_RADIUS = 40

-- 检查附近是否已有龙卷风
local function HasNearbyTornado(inst, radius)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, radius or 60, {"tornado"}, {"FX", "NOCLICK", "DECOR"})
    for _, ent in ipairs(ents) do
        if ent:IsValid() and ent.prefab == "tornado" then
            return ent
        end
    end
    return nil
end

-- 获取旋风生成位置（在BOSS和目标之间15%的位置）
local function GetTornadoSpawnLocation(inst, target)
    local ix, iy, iz = inst.Transform:GetWorldPosition()
    local tx, ty, tz = target.Transform:GetWorldPosition()
    return ix + 0.15 * (tx - ix), 0, iz + 0.15 * (tz - iz)
end

--  先从当前位置逐渐移动到竞技场圆周上，然后开始环绕
local function SetupTornadoCircling(tornado, cx, cz, start_angle, clockwise)
    if not tornado or not tornado:IsValid() then return end
    
    -- 清理之前的任务
    if tornado._circling_task then
        tornado._circling_task:Cancel()
        tornado._circling_task = nil
    end
    if tornado._moveto_task then
        tornado._moveto_task:Cancel()
        tornado._moveto_task = nil
    end
    
    tornado._arena_cx = cx
    tornado._arena_cz = cz
    tornado._arena_angle = start_angle
    tornado._arena_clockwise = clockwise
    tornado._arena_radius = ARENA_TORNADO_RADIUS
    tornado._arena_phase = "moving_to_circle" -- 阶段：moving_to_circle -> circling
    
    -- 计算目标点（圆周上的位置）
    local target_x = cx + ARENA_TORNADO_RADIUS * math.cos(start_angle)
    local target_z = cz + ARENA_TORNADO_RADIUS * math.sin(start_angle)
    
    -- 移动速度（每0.1秒移动的距离）
    local move_speed = 0.8
    
    tornado._circling_task = tornado:DoPeriodicTask(0.1, function(tornado)
        if not tornado:IsValid() or tornado:HasTag("NOCLICK") then
            return
        end
        
        local tx, ty, tz = tornado.Transform:GetWorldPosition()
        local cx = tornado._arena_cx
        local cz = tornado._arena_cz
        local radius = tornado._arena_radius
        
        if tornado._arena_phase == "moving_to_circle" then
            -- 阶段1：从当前位置移动到圆周上
            local target_x = cx + radius * math.cos(tornado._arena_angle)
            local target_z = cz + radius * math.sin(tornado._arena_angle)
            
            local dx = target_x - tx
            local dz = target_z - tz
            local dist = math.sqrt(dx * dx + dz * dz)
            
            if dist < move_speed * 2 then
                -- 已到达圆周，切换到环绕阶段
                tornado._arena_phase = "circling"
                tornado.Transform:SetPosition(target_x, 0, target_z)
            else
                -- 继续向圆周移动
                local nx = dx / dist * move_speed
                local nz = dz / dist * move_speed
                tornado.Transform:SetPosition(tx + nx, 0, tz + nz)
            end
        else
            -- 阶段2：沿圆周环绕
            local angle_speed = 0.015 -- 弧度/tick，调整环绕速度
            
            if tornado._arena_clockwise then
                tornado._arena_angle = tornado._arena_angle - angle_speed
            else
                tornado._arena_angle = tornado._arena_angle + angle_speed
            end
            
            local new_x = cx + radius * math.cos(tornado._arena_angle)
            local new_z = cz + radius * math.sin(tornado._arena_angle)
            
            -- 直接设置龙卷风位置
            tornado.Transform:SetPosition(new_x, 0, new_z)
        end
    end)
    
    tornado:ListenForEvent("onremove", function()
        if tornado._circling_task then
            tornado._circling_task:Cancel()
            tornado._circling_task = nil
        end
    end)
end

-- 生成追踪玩家的小旋风
local function DoSmallTornadoAttack(inst)
    local existing_tornado = HasNearbyTornado(inst, 80)
    if existing_tornado then
        return existing_tornado
    end
    
    if inst.components.combat and 
       inst.components.combat.target and 
       inst.components.combat.target:IsValid() then
        local target = inst.components.combat.target
        local x, y, z = inst.Transform:GetWorldPosition()
        local dist_sq = target:GetDistanceSqToPoint(x, y, z)
        
        -- 范围45单位内才生成旋风
        if dist_sq < 45 * 45 and inst.components.combat:CanTarget(target) then
            local tornado = SpawnPrefab("tornado")
            tornado.WINDSTAFF_CASTER = inst.swp2hm or inst
            
            -- 设置在BOSS和目标之间的位置
            tornado.Transform:SetPosition(GetTornadoSpawnLocation(inst, target))
            tornado.components.knownlocations:RememberLocation("target", target:GetPosition())
            
            -- 移速变为0.4倍
            if tornado.components.locomotor then
                tornado.components.locomotor.walkspeed = TUNING.TORNADO_WALK_SPEED * 0.33 * 0.4
                tornado.components.locomotor.runspeed = TUNING.TORNADO_WALK_SPEED * 0.4
            end
            
            -- 设置追踪玩家的行为
            tornado._tracking_target = target
            tornado._tracking_task = tornado:DoPeriodicTask(0.5, function(tornado)
                if not tornado:IsValid() then
                    return
                end
                
                -- 优先追踪原目标，如果目标无效则寻找最近的玩家
                local tracking_target = tornado._tracking_target
                if not tracking_target or not tracking_target:IsValid() or 
                   (tracking_target.components.health and tracking_target.components.health:IsDead()) then
                    tracking_target = FindClosestPlayerToInst(tornado, 40, true)
                    tornado._tracking_target = tracking_target
                end
                
                if tracking_target and tracking_target:IsValid() then
                    tornado.components.knownlocations:RememberLocation("target", tracking_target:GetPosition())
                end
            end)
            
            tornado:ListenForEvent("onremove", function()
                if tornado._tracking_task then
                    tornado._tracking_task:Cancel()
                    tornado._tracking_task = nil
                end
            end)
            
            return tornado
        end
    end
    return nil
end

-- 妥协龙卷风
local function UMTornadoAdvanceFull(inst)
    if inst.Advance_Task ~= nil then
        inst.Advance_Task:Cancel()
    end
    inst.Advance_Task = nil
    inst.startmoving = true
    inst.AnimState:PlayAnimation("tornado_loop", true)
end

local function UMTornadoInit(inst)
    inst.SoundEmitter:PlaySound("UCSounds/um_tornado/um_tornado_loop", "spinLoop")
    if not inst.is_full then
        inst.AnimState:PlayAnimation("tornado_pre")
        inst.Advance_Task = inst:ListenForEvent("animover", UMTornadoAdvanceFull)
        inst.is_full = true
    else
        UMTornadoAdvanceFull(inst)
    end
end


-- ----------------------------------------------------------------------------
-- 第二阶段玻璃刺围困攻击
-- ----------------------------------------------------------------------------

local SPIKE_ROTATION_OFFSETS = {65, 90, 180}  -- 不同攻击模式的角度偏移
local SPIKE_EMERGE_DELAYS = {0.75, 0.33, 0.33}  -- 不同攻击模式的延迟时间

-- 生成玻璃刺围困攻击（三种模式：半包围/双竖线/双横线）
local function DoSpikesAttack(inst)
    local target = inst.components.combat.target
    if not target or not target:IsValid() or not target:IsNear(inst, 6) then
        return
    end
    
    -- 设置或重置技能冷却
    if inst.components.timer then
        if inst.components.timer:TimerExists("spike_cd") then
            inst.components.timer:SetTimeLeft("spike_cd", TUNING.ALTERGUARDIAN_PHASE2_SPIKECOOLDOWN)
        else
            inst.components.timer:StartTimer("spike_cd", TUNING.ALTERGUARDIAN_PHASE2_SPIKECOOLDOWN)
        end
    end
    
    -- 选择攻击模式：1=半包围(70%) 2=双竖线 3=双横线
    inst.spikeattacktype2hm = math.random() < 0.7 and 1 or math.random(2, 3)
    
    local rot_offset = SPIKE_ROTATION_OFFSETS[inst.spikeattacktype2hm] or 65
    local emerge_delay = SPIKE_EMERGE_DELAYS[inst.spikeattacktype2hm] or 0.33
    local angle = inst:GetAngleToPoint(target.Transform:GetWorldPosition())
    local pos_target = inst.spikeattacktype2hm ~= 1 and target or inst
    
    if not pos_target then
        return
    end
    
    local x, y, z = pos_target.Transform:GetWorldPosition()
    
    -- 破坏码头
    if TheWorld.components.dockmanager ~= nil then
        TheWorld.components.dockmanager:DamageDockAtPoint(x, y, z, 1000)
    end
    
    -- 生成中央尖刺（排除模式2）
    if inst.spikeattacktype2hm ~= 2 then
        local spike_center = SpawnPrefab("alterguardian_phase2spiketrail")
        spike_center.Transform:SetPosition(x, 0, z)
        spike_center.Transform:SetRotation(angle)
        spike_center:SetOwner(inst)
        if spike_center._emerge_task and spike_center._emerge_task.fn then
            local emerge = spike_center._emerge_task.fn
            spike_center._emerge_task:Cancel()
            spike_center._emerge_task = spike_center:DoTaskInTime(
                inst.spikeattacktype2hm == 1 and 1 or emerge_delay, 
                emerge
            )
        end
    end
    
    -- 生成左侧尖刺
    local spike_left = SpawnPrefab("alterguardian_phase2spiketrail")
    spike_left.Transform:SetPosition(x, 0, z)
    spike_left.Transform:SetRotation(angle - rot_offset)
    spike_left:SetOwner(inst)
    if spike_left._emerge_task and spike_left._emerge_task.fn then
        local emerge = spike_left._emerge_task.fn
        spike_left._emerge_task:Cancel()
        spike_left._emerge_task = spike_left:DoTaskInTime(emerge_delay, emerge)
    end
    
    -- 生成右侧尖刺（排除模式3）
    if inst.spikeattacktype2hm ~= 3 then
        local spike_right = SpawnPrefab("alterguardian_phase2spiketrail")
        spike_right.Transform:SetPosition(x, 0, z)
        spike_right.Transform:SetRotation(angle + rot_offset)
        spike_right:SetOwner(inst)
        if spike_right._emerge_task and spike_right._emerge_task.fn then
            local emerge = spike_right._emerge_task.fn
            spike_right._emerge_task:Cancel()
            spike_right._emerge_task = spike_right:DoTaskInTime(emerge_delay, emerge)
        end
    end
end

-- ----------------------------------------------------------------------------
-- 第二阶段月亮风暴闪电攻击
-- ----------------------------------------------------------------------------

local LIGHTNING_EXCLUDE_TAGS = {"playerghost", "INLIMBO", "lightningblocker"}

-- 生成月亮风暴闪电
local function SpawnMoonstormLighting(inst, x, y, z)
    local spark = SpawnPrefab("moonstorm_lightning")
    spark.Transform:SetPosition(x, 0, z)
end

-- 生成连环闪电攻击（10道闪电从近到远）
local function DoLightingAttack(inst)
    local target = inst.components.combat.target
    if not (target and target:IsValid()) then
        return
    end
    
    local dist = math.clamp(inst:GetDistanceSqToInst(target), 1, 12)
    if dist > 900 then  -- 最大距离30单位
        return
    end
    
    local x, y, z = inst.Transform:GetWorldPosition()
    
    -- 从近到远生成10道闪电
    for i = 1, 10 do
        local radius = 1 + i * 5
        if not (target and target:IsValid()) then
            return
        end
        
        local angle = inst:GetAngleToPoint(target.Transform:GetWorldPosition()) * DEGREES
        local offset = Vector3(radius * math.cos(angle), 0, radius * -math.sin(angle))
        inst:DoTaskInTime(5 * FRAMES * i, SpawnMoonstormLighting, x + offset.x, y, z + offset.z)
    end
end

-- 月亮风暴闪电触发击打效果
local function MoonstormSendLighting(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 3, nil, LIGHTNING_EXCLUDE_TAGS)
    for _, entity in pairs(ents) do
        if entity and entity:IsValid() and entity.prefab ~= "alterguardian_phase2" then
            entity:PushEvent("lightningstrike")
            if entity.components.playerlightningtarget then
                entity.components.playerlightningtarget:DoStrike()
            end
        end
    end
end

-- 模块级标记：是否正在进行闪电攻击（用于协调多个prefab）
-- 注意：这是一个模块级变量，会在第二阶段战斗期间被设置
local is_phase2_lightning_active = false

-- 增强月亮风暴闪电效果
AddPrefabPostInit("moonstorm_lightning", function(inst)
    if not TheWorld.ismastersim then
        return
    end
    
    if is_phase2_lightning_active then
        inst:DoTaskInTime(0, MoonstormSendLighting)
    end
end)

-- 月亮风暴玻璃快速消失（减少掉落）
AddPrefabPostInit("moonstorm_glass", function(inst)
    if not TheWorld.ismastersim then
        return
    end
    
    if is_phase2_lightning_active then
        if inst.components.lootdropper then
            inst.components.lootdropper:SetChanceLootTable()
        end
        if inst.components.timer and inst.components.timer:TimerExists("defusetime") then
            inst.components.timer:SetTimeLeft("defusetime", 1.5)
        end
    end
end)

-- 尖刺轨迹优先命中玩家
AddPrefabPostInit("alterguardian_phase2spiketrail", function(inst)
    if not TheWorld.ismastersim then
        return
    end
    
    local emerge_fn
    if inst._emerge_task and inst._emerge_task.fn then
        emerge_fn = inst._emerge_task.fn
        if is_phase2_lightning_active then
            inst._emerge_task:Cancel()
            inst._emerge_task = inst:DoTaskInTime(2, emerge_fn)
        end
    end
    
    -- 如果有临时目标，则追踪该目标
    if emerge_fn and phase2_spike_target and phase2_spike_target:IsValid() then
        inst.target2hm = phase2_spike_target
        
        if inst._watertest_task and inst._watertest_task.fn then
            local original_fn = inst._watertest_task.fn
            inst._watertest_task.fn = function(inst, ...)
                if not inst.startpos2hm then
                    inst.startpos2hm = inst:GetPosition()
                end
                
                -- 检查是否到达目标位置（距离差小于2）
                if inst.target2hm and inst.target2hm:IsValid() then
                    local target_dist_sq = inst.target2hm:GetDistanceSqToPoint(inst.startpos2hm.x, 0, inst.startpos2hm.z)
                    local current_dist_sq = inst:GetDistanceSqToPoint(inst.startpos2hm.x, 0, inst.startpos2hm.z)
                    if math.abs(target_dist_sq - current_dist_sq) <= 2 then
                        emerge_fn(inst)
                        if inst._watertest_task ~= nil then
                            inst._watertest_task:Cancel()
                            inst._watertest_task = nil
                        end
                        return
                    end
                end
                original_fn(inst, ...)
            end
        end
    end
end)



-- ----------------------------------------------------------------------------
-- 第二阶段状态图增强
-- ----------------------------------------------------------------------------

AddStategraphPostInit("alterguardian_phase2", function(sg)
    -- 海上时优先使用旋转攻击
    local original_doattack = sg.events.doattack.fn
    sg.events.doattack.fn = function(inst, data, ...)
        if not inst:IsOnValidGround() and 
           not (inst.components.health:IsDead() or inst.sg:HasStateTag("busy")) and 
           data.target ~= nil and data.target:IsValid() then
            local dist_sq = inst:GetDistanceSqToInst(data.target)
            local spin_range_sq = TUNING.ALTERGUARDIAN_PHASE2_SPIN_RANGE * TUNING.ALTERGUARDIAN_PHASE2_SPIN_RANGE * 2
            local chop_range_sq = TUNING.ALTERGUARDIAN_PHASE2_CHOP_RANGE * TUNING.ALTERGUARDIAN_PHASE2_CHOP_RANGE
            
            local attack_state = (not inst.components.timer:TimerExists("spin_cd") and dist_sq < spin_range_sq and "spin_pre") or
                                 (not inst.components.timer:TimerExists("summon_cd") and "atk_summon") or
                                 (dist_sq < chop_range_sq and "atk_chop") or nil
            if attack_state ~= nil then
                inst.sg:GoToState(attack_state, data.target)
                return
            end
        end
        return original_doattack(inst, data, ...)
    end
    
    -- 空闲状态：重置旋转计数和锁定季节
    local OnEnterIdle = sg.states.idle.onenter
    sg.states.idle.onenter = function(inst, ...)
        inst.spinattackindex2hm = 0
        OnEnterIdle(inst, ...)
        TryLockSeason(inst)
    end
    
    -- 尖刺攻击：触发连环闪电
    local OnEnterAtkSpike = sg.states.atk_spike.onenter
    sg.states.atk_spike.onenter = function(inst, ...)
        OnEnterAtkSpike(inst, ...)
        local x, y, z = inst.Transform:GetWorldPosition()
        if TheWorld.components.dockmanager ~= nil then
            TheWorld.components.dockmanager:DamageDockAtPoint(x, y, z, 1000)
        end
    end
    
    AddStateTimeEvent2hm(sg.states.atk_spike, 32 * FRAMES, function(inst)
        is_phase2_lightning_active = true
        DoLightingAttack(inst)
    end)
    
    local OnEnterAtkSpikePst = sg.states.atk_spike_pst.onenter
    sg.states.atk_spike_pst.onenter = function(inst, ...)
        OnEnterAtkSpikePst(inst, ...)
    end
    
    -- 已有龙卷风不触发原地旋转
    local OnEnterSpinPre = sg.states.spin_pre.onenter
    sg.states.spin_pre.onenter = function(inst, ...)
        OnEnterSpinPre(inst, ...)
        

        if not inst.umstormready2hm and 
           TUNING.DSTU and TUNING.DSTU.STORMS and 
           TheWorld.components.um_stormspawner and 
           TheWorld.state.isspring and
           (inst.umstorm2hm == nil or not inst.umstorm2hm:IsValid() or not inst:IsNear(inst.umstorm2hm, 100)) and 
           not HasNearbyTornado(inst, 50) and
           math.random() < 0.75 then
            inst.umstormready2hm = true
            if inst.components.rooted == nil then
                inst:AddComponent("rooted")
            end
            inst.components.rooted:AddSource(inst)
            inst.umstorm2hm = nil
        end
    end
    
    -- 旋转循环：动态移速系统（目前仍有问题）
    -- 1. 高DPS时移速乘以1.2倍
    -- 2. 开始和结束2秒内移速从0.8倍平滑过渡到满速/从满速过渡到0.8倍
    local SPIN_RAMPUP_TIME = 2.0        -- 加速时间（秒）
    local SPIN_RAMPDOWN_TIME = 2.0      -- 减速时间（秒）
    local SPIN_MIN_SPEED_MULT = 0.6     -- 最低速度倍率
    local SPIN_HIGH_DPS_MULT = 1.2      -- 高DPS时的额外速度倍率
    
    local OnEnterSpinLoop = sg.states.spin_loop.onenter
    sg.states.spin_loop.onenter = function(inst, data, ...)
        -- 原版速度计算逻辑（基于玩家速度）
        local base_speed = data.speed or TUNING.ALTERGUARDIAN_PHASE2_SPIN_SPEED
        
        -- 检查是否处于高DPS状态，如果是则乘以1.2
        local high_dps = IsHighDPS(inst)
        if high_dps then
            base_speed = base_speed * SPIN_HIGH_DPS_MULT
        end
        
        -- 存储动态移速相关数据
        inst.sg.statemem.base_speed2hm = base_speed
        inst.sg.statemem.high_dps2hm = high_dps
        inst.sg.statemem.spin_start_time2hm = GetTime()
        
        -- 获取总旋转时间用于计算减速
        local loop_len = inst.AnimState:GetCurrentAnimationLength()
        local num_loops = math.random(TUNING.ALTERGUARDIAN_PHASE2_SPINMIN, TUNING.ALTERGUARDIAN_PHASE2_SPINMAX)
        inst.sg.statemem.total_spin_time2hm = loop_len * num_loops
        
        -- 初始速度为最低倍率（加速阶段开始）
        data.speed = base_speed * SPIN_MIN_SPEED_MULT
        
        OnEnterSpinLoop(inst, data, ...)
    end
    
    local OnUpdateSpinLoop = sg.states.spin_loop.onupdate
    sg.states.spin_loop.onupdate = function(inst, dt, ...)
        if OnUpdateSpinLoop then
            OnUpdateSpinLoop(inst, dt, ...)
        end
        
        -- 动态移速计算
        if inst.sg.statemem.base_speed2hm and inst.sg.statemem.spin_start_time2hm then
            local base_speed = inst.sg.statemem.base_speed2hm
            local elapsed = GetTime() - inst.sg.statemem.spin_start_time2hm
            local total_time = inst.sg.statemem.total_spin_time2hm or 5
            local remaining = math.max(0, inst.sg.timeout or 0)
            
            local speed_mult = 1.0
            
            if elapsed < SPIN_RAMPUP_TIME then
                -- 加速阶段：从06平滑过渡到1.0
                local t = elapsed / SPIN_RAMPUP_TIME
                -- 使用平滑插值（ease-in-out）
                t = t * t * (3 - 2 * t)
                speed_mult = SPIN_MIN_SPEED_MULT + (1.0 - SPIN_MIN_SPEED_MULT) * t
            elseif remaining < SPIN_RAMPDOWN_TIME and remaining > 0 then
                -- 减速阶段：从1.0平滑过渡到0.8
                local t = remaining / SPIN_RAMPDOWN_TIME
                -- 使用平滑插值（ease-in-out）
                t = t * t * (3 - 2 * t)
                speed_mult = SPIN_MIN_SPEED_MULT + (1.0 - SPIN_MIN_SPEED_MULT) * t
            end
            
            local final_speed = base_speed * speed_mult
            inst.Physics:SetMotorVelOverride(final_speed, 0, 0)
        end
    end
    
    -- 旋转结束：生成玻璃刺围墙
    local OnEnterSpinPst = sg.states.spin_pst.onenter
    sg.states.spin_pst.onenter = function(inst, speed, ...)
        is_phase2_lightning_active = nil
        
        -- 使用动态移速系统的减速后速度
        if inst.sg.statemem.base_speed2hm then
            speed = inst.sg.statemem.base_speed2hm * SPIN_MIN_SPEED_MULT
        end
        
        OnEnterSpinPst(inst, speed, ...)
        

        -- 先在天体位置生成龙卷风，然后让它围绕竞技场运动
        if inst.umstormready2hm and 
           (inst.umstorm2hm == nil or not inst.umstorm2hm:IsValid() or not inst:IsNear(inst.umstorm2hm, 100)) then
            local tornado = TheSim:FindFirstEntityWithTag("um_tornado")
            local forced = false
            
            if tornado == nil then
                TheWorld:PushEvent("forcetornado")
                tornado = TheSim:FindFirstEntityWithTag("um_tornado")
                forced = true
            end
            
            if tornado ~= nil and tornado:IsValid() and tornado.persists and 
               (forced or FindClosestPlayerToInst(tornado, 36, false) == nil) then
                -- 先将龙卷风放置到天体位置
                local x, y, z = inst.Transform:GetWorldPosition()
                tornado.Transform:SetPosition(x, y, z)
                
                if tornado.startmoving and tornado.is_full then
                    tornado.is_full = false
                    UMTornadoInit(tornado)
                end
                
                -- 生成分身跟随龙卷风位置并播放旋转动画，旋转速度为本体的0.75倍
                SpawnTornadoFollowShadow(inst, tornado, 0.75)
                
                -- 延迟设置圆周运动，让龙卷风先在原地出现一会
                inst:DoTaskInTime(1, function()
                    if tornado and tornado:IsValid() then
                        -- 获取竞技场中心
                        local manager = inst._arena_manager or TheWorld.components.alterguardian_arena_manager2hm
                        local helper = TheWorld.net and TheWorld.net.components.alterguardian_floor_helper2hm
                        
                        local cx, cz
                        if helper and helper.arena_active:value() then
                            cx = helper.arena_origin_x:value()
                            cz = helper.arena_origin_z:value()
                        elseif manager then
                            local marker = manager:GetMarker()
                            if marker and marker:IsValid() then
                                cx, _, cz = marker.Transform:GetWorldPosition()
                            end
                        end
                        
                        -- 没有竞技场，使用天体位置
                        if not cx or not cz then
                            cx, _, cz = inst.Transform:GetWorldPosition()
                        end
                        
                        -- 计算从圆心指向龙卷风当前位置的角度
                        local tx, ty, tz = tornado.Transform:GetWorldPosition()
                        local angle = math.atan2(tz - cz, tx - cx)
                        
                        -- 设置圆周运动
                        SetupTornadoCircling(tornado, cx, cz, angle, math.random() < 0.5)
                    end
                end)
                
                inst.umstorm2hm = tornado
            end
        else
            -- 连续旋转逻辑
            inst.spinattackindex2hm = (inst.spinattackindex2hm or 0) + 1
            
            if inst.spinattackthree2hm and inst.spinattackdouble2hm and math.random() < 0.033 then
                -- 重置三连旋标记
                inst.spinattackdouble2hm = nil
                inst.spinattackthree2hm = nil
                if inst.components.timer and inst.components.timer:TimerExists("spin_cd") then
                    inst.components.timer:StopTimer("spin_cd")
                end
            elseif not inst.spinattackthree2hm and inst.spinattackdouble2hm and inst.spinattackindex2hm < 3 then
                -- 触发三连旋
                inst.spinattackthree2hm = true
                if inst.components.timer and inst.components.timer:TimerExists("spin_cd") then
                    inst.components.timer:StopTimer("spin_cd")
                end
            elseif not inst.spinattackdouble2hm and 
                   math.random() > inst.components.health:GetPercent() and 
                   inst.spinattackindex2hm < 3 then
                -- 触发双连旋（基于血量的概率）
                inst.spinattackdouble2hm = true
                if inst.components.timer and inst.components.timer:TimerExists("spin_cd") then
                    inst.components.timer:StopTimer("spin_cd")
                end
            elseif inst.components.timer then
                -- 随机重置技能CD
                if inst.components.timer:TimerExists("spin_cd") and math.random() < 0.25 then
                    inst.components.timer:StopTimer("spin_cd")
                elseif inst.components.timer:TimerExists("summon_cd") then
                    inst.components.timer:StopTimer("summon_cd")
                end
            end
        end
    end
    
    AddStateTimeEvent2hm(sg.states.spin_pst, 11 * FRAMES, function(inst)
        -- 清理风暴状态
        if inst.umstormready2hm then
            inst.umstormready2hm = nil
            if inst.components.rooted then
                inst.components.rooted:RemoveSource(inst)
            end
        end
        
        -- 旋转攻击结束时，生成玻璃刺围墙
        DoSpikesAttack(inst)
    end)
    
    local OnEnterAtkSummon = sg.states.atk_summon.onenter
    sg.states.atk_summon.onenter = function(inst, ...)
        OnEnterAtkSummon(inst, ...)
        -- 召唤次数用尽时重置尖刺CD
        if inst.sg.mem.num_summons <= 0 and 
           inst.components.timer and 
           inst.components.timer:TimerExists("spike_cd") then
            inst.components.timer:StopTimer("spike_cd")
        end
    end
    
    -- 在召唤虚影的最后一次攻击时生成小旋风
    AddStateTimeEvent2hm(sg.states.atk_summon, 22 * FRAMES, function(inst)
        if inst.sg.mem.num_summons == 0 then
            DoSmallTornadoAttack(inst)
        end
    end)
end)

-- ============================================================================
-- 第三阶段：冰雪激光 + 冬季环境
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 第三阶段AI增强
-- ----------------------------------------------------------------------------
local STRICT_CENTER_THRESHOLD_SQ = 9    -- 3格距离
local AURORA_ABSORB_COOLDOWN = 15       -- 极光吸收冷却时间

-- 残血时会触发躲避技能
local FLEE_SKILL_DURATION = 8           -- 逃避技能持续时间
local FLEE_SKILL_COOLDOWN = 15          -- 逃避技能冷却时间
local FLEE_HP_THRESHOLD = 0.4           -- 触发逃避的血量阈值

-- 获取竞技场中心
local function GetArenaCenter(inst)
    local spawnpoint = inst.components.knownlocations and inst.components.knownlocations:GetLocation("spawnpoint")
    if spawnpoint then
        return spawnpoint.x, spawnpoint.z
    end
    local helper = TheWorld.net and TheWorld.net.components.alterguardian_floor_helper2hm
    if helper and helper.arena_active:value() then
        return helper.arena_origin_x:value(), helper.arena_origin_z:value()
    end
    return nil, nil
end

local function StartFleeSkill(inst)
    if inst._flee_skill_active then return end
    if inst.components.timer and inst.components.timer:TimerExists("flee_skill_cd") then return end
    
    inst._flee_skill_active = true
    
    -- 嘲讽，进入逃避状态
    if inst.sg and not inst.sg:HasStateTag("busy") then
        inst.sg:GoToState("taunt")
    end
    

    inst._flee_skill_task = inst:DoTaskInTime(FLEE_SKILL_DURATION, function()
        if inst:IsValid() and not inst.components.health:IsDead() then
            inst._flee_skill_active = nil
            inst._flee_skill_task = nil
            
            if inst.components.timer then
                inst.components.timer:StartTimer("flee_skill_cd", FLEE_SKILL_COOLDOWN)
            end
        end
    end)
end

local function StopFleeSkill(inst)
    if inst._flee_skill_task then
        inst._flee_skill_task:Cancel()
        inst._flee_skill_task = nil
    end
    inst._flee_skill_active = nil
end

local function IsFleeSkillActive(inst)
    return inst._flee_skill_active == true
end

local function CanStartFleeSkill(inst)
    if inst._flee_skill_active then return false end
    if inst.components.timer and inst.components.timer:TimerExists("flee_skill_cd") then return false end
    if not inst.components.health then return false end
    if inst.components.health:GetPercent() >= FLEE_HP_THRESHOLD then return false end
    return true
end

-- 残血时检查是否可以触发逃避技能
local function StartFleeSkillMonitor(inst)
    if inst._flee_skill_monitor_task then return end
    
    inst._flee_skill_monitor_task = inst:DoPeriodicTask(1, function()
        if not inst:IsValid() then
            if inst._flee_skill_monitor_task then
                inst._flee_skill_monitor_task:Cancel()
                inst._flee_skill_monitor_task = nil
            end
            return
        end
        
        -- 死亡时停止监控
        if inst.components.health and inst.components.health:IsDead() then
            if inst._flee_skill_monitor_task then
                inst._flee_skill_monitor_task:Cancel()
                inst._flee_skill_monitor_task = nil
            end
            StopFleeSkill(inst)
            return
        end
        
        -- 检查是否可以触发逃避技能
        if CanStartFleeSkill(inst) then
            StartFleeSkill(inst)
        end
    end)
end

AddBrainPostInit("alterguardian_phase3brain", function(self)
    -- 将 出生点设置为竞技场中心
    local original_OnInitializationComplete = self.OnInitializationComplete
    self.OnInitializationComplete = function(self)
        if original_OnInitializationComplete then
            original_OnInitializationComplete(self)
        end
        local inst = self.inst
        local manager = inst._arena_manager or TheWorld.components.alterguardian_arena_manager2hm
        local helper = TheWorld.net and TheWorld.net.components.alterguardian_floor_helper2hm
        
        local cx, cz
        if helper and helper.arena_active:value() then
            cx = helper.arena_origin_x:value()
            cz = helper.arena_origin_z:value()
        elseif manager then
            local marker = manager:GetMarker()
            if marker and marker:IsValid() then
                cx, _, cz = marker.Transform:GetWorldPosition()
            end
        end

        if cx and cz then
            local center = Point(cx, 0, cz)
            inst.components.knownlocations:RememberLocation("spawnpoint", center)
            inst.components.knownlocations:RememberLocation("geyser", center)
        end
    end
    
    -- boss 在边界时往两侧移动
    local children = self.bt.root.children
    for i, child in ipairs(children) do
        if child.name == "Run Away" and child.children then
            for j, subchild in ipairs(child.children) do
                if subchild.name and subchild.name:find("RUNAWAY") then
                    local PHASE3_HUNTERPARAMS = {
                        tags = { "_combat" },
                        notags = { "INLIMBO", "playerghost" },
                        oneoftags = { "character", "monster", "shadowminion" },
                    }
                    local AVOID_PLAYER_DIST = 3
                    local AVOID_PLAYER_STOP = 5
                    -- safe_point_fn 返回竞技场中心，让 RunAway 在计算逃跑方向时偏向中心
                    child.children[j] = RunAway(self.inst, PHASE3_HUNTERPARAMS, AVOID_PLAYER_DIST, AVOID_PLAYER_STOP, 
                        nil,  -- fn
                        nil,  -- runhome
                        nil,  -- fix_overhang
                        nil,  -- walk_instead
                        function() return GetArenaSafePoint(self.inst) end  -- safe_point_fn
                    )
                    break
                end
            end
            break
        end
    end
    
    table.insert(self.bt.root.children, 2, Follow(self.inst, function()
        -- 只有在逃避技能激活时才触发逃避行为
        if self.inst._flee_skill_active then
            local target = self.inst.components.combat.target
            if target and target:IsValid() and target:IsNear(self.inst, TUNING.ALTERGUARDIAN_PHASE3_TARGET_DIST) then
                return target
            end
        end
    end, math.max(6, TUNING.ALTERGUARDIAN_PHASE3_ATTACK_RANGE - 6), 
        math.max(TUNING.ALTERGUARDIAN_PHASE3_ATTACK_RANGE - 2, 12),
        math.max(14, TUNING.ALTERGUARDIAN_PHASE3_ATTACK_RANGE)))
end)


-- ----------------------------------------------------------------------------
-- 第三阶段事件处理
-- ----------------------------------------------------------------------------

-- 第三阶段死亡事件
local function Phase3OnDeath(inst)
    AddSeasonLock(inst, 4, true)
    if TheWorld.state.precipitation ~= "none" then
        TheWorld:PushEvent("ms_forceprecipitation", false)
    end
    -- 移除所有玩家的虚影攻击标记
    for _, player in ipairs(AllPlayers) do
        if player and player:HasTag("gestalt_possessable") then
            player:RemoveTag("gestalt_possessable")
        end
    end
end

-- 第三阶段受击事件
local function Phase3GetAttacked(inst, data)
    -- 攻击者将被标记为可被虚影攻击
    if data and data.attacker and data.attacker:IsValid() and not data.attacker:HasTag("gestalt_possessable") then
        data.attacker:AddTag("gestalt_possessable")
    end
end



-- 第三阶段暗影世界特殊处理
local function Phase3ShadowWorldFn(inst)
    
    -- 优化目标选择逻辑
    if inst.components.combat and inst.components.combat.targetfn and inst.components.knownlocations then
        local original_targetfn = inst.components.combat.targetfn
        inst.components.combat:SetRetargetFunction(inst.components.combat.retargetperiod or 3, function(inst, ...)
            local GetLocation = inst.components.knownlocations.GetLocation
            inst.components.knownlocations.GetLocation = nilfn
            local target, followtime = original_targetfn(inst, ...)
            inst.components.knownlocations.GetLocation = GetLocation
            return target, followtime
        end)
    end
end

-- 第三阶段目标保持函数
local function Phase3KeepTarget(inst, target)
    if inst.components.combat:CanTarget(target) then
        local x, y, z = inst.Transform:GetWorldPosition()
        if target:GetDistanceSqToPoint(x, y, z) < TUNING.ALTERGUARDIAN_PHASE3_SUMMONRSQ then
            local newtarget = FindClosestPlayerInRange(x, y, z, 12, true)
            if newtarget == nil or newtarget == target then
                return true
            end
        end
    end
end

-- ----------------------------------------------------------------------------
-- 冰岛地皮系统
-- ----------------------------------------------------------------------------

local disable_boat_ice_tile_remove = false  -- 模块级标记：禁用冰船生成
-- 冰面现在绑定到竞技场管理器，由管理器负责保存/加载和清除
local function DelayRemoveIceBoat(inst)
    inst.components.boatphysics = nil
    inst.components.walkableplatform = nil
    inst:Remove()
end

-- 修改海洋冰管理器以防止生成冰船和冰块
AddComponentPostInit("oceanicemanager", function(self)
    local original_QueueDestroyForIceAtPoint = self.QueueDestroyForIceAtPoint
    local destroy_ice_at_point = getupvalue2hm(self.QueueDestroyForIceAtPoint, "destroy_ice_at_point")
    
    if destroy_ice_at_point ~= nil then
        self.QueueDestroyForIceAtPoint = function(self, x, y, z, data, ...)
            local original_DoTaskInTime = TheWorld.DoTaskInTime
            
            if disable_boat_ice_tile_remove then
                data = data or {}
                data.silent = true
                
                TheWorld.DoTaskInTime = function(inst, time, fn, ...)
                    if fn == destroy_ice_at_point then
                        return original_DoTaskInTime(inst, time, function(world, dx, dz, oceanicemanager, ...)
                            local original_DestroyEntity = DestroyEntity
                            DestroyEntity = nilfn
                            local original_SpawnPrefab = SpawnPrefab
                            
                            SpawnPrefab = function(prefab, ...)
                                if prefab == "boat_ice" then
                                    local entity = original_SpawnPrefab("ice")
                                    entity.components.boatphysics = {ApplyRowForce = nilfn}
                                    entity.components.walkableplatform = {platform_radius = 0}
                                    entity:DoTaskInTime(0, DelayRemoveIceBoat)
                                    return entity
                                elseif prefab == "ice" or prefab == "degrade_fx_ice" then
                                    local entity = original_SpawnPrefab(prefab)
                                    entity:DoTaskInTime(0, entity.Remove)
                                    return entity
                                end
                                return original_SpawnPrefab(prefab, ...)
                            end
                            
                            oceanicemanager:DestroyIceAtPoint(dx, 0, dz)
                            SpawnPrefab = original_SpawnPrefab
                            DestroyEntity = original_DestroyEntity
                        end, ...)
                    end
                    return original_DoTaskInTime(inst, time, fn, ...)
                end
            end
            
            original_QueueDestroyForIceAtPoint(self, x, y, z, data, ...)
            TheWorld.DoTaskInTime = original_DoTaskInTime
        end
    end
end)

-- 清除冰地皮CD任务
local function ClearIceTilesCDTask(inst)
    inst.icetilescd2hmtask = nil
end

-- ----------------------------------------------------------------------------
-- 第三阶段暴风雪
local function StartPhase3Snowstorm(inst)
    if not inst:IsValid() or (inst.components.health and inst.components.health:IsDead()) then
        return
    end
    
    -- 启动雪球雨
    if TheWorld.components.waterstreakrain2hm then
        TheWorld.components.waterstreakrain2hm:Enable(true)
    end
    
    -- 启动暴风雪
    if TheWorld.components.um_snow_stormspawner then
        TheWorld:AddTag("snowstormstart")
        if TheWorld.net ~= nil then
            TheWorld.net:AddTag("snowstormstartnet")
        end
    end
end

-- 停止暴风雪
local function StopPhase3Snowstorm(inst)
    if TheWorld.components.waterstreakrain2hm then
        TheWorld.components.waterstreakrain2hm:Enable(false)
    end
    
    if TheWorld.components.um_snow_stormspawner then
        TheWorld:RemoveTag("snowstormstart")
        if TheWorld.net ~= nil then
            TheWorld.net:RemoveTag("snowstormstartnet")
        end
    end
end

-- 持续维持暴风雪
local function MaintainSnowstorm(inst)
    if not inst:IsValid() or (inst.components.health and inst.components.health:IsDead()) then
        StopPhase3Snowstorm(inst)
        return
    end
    
    if TheWorld.state.precipitation == "none" then
        TheWorld:PushEvent("ms_forceprecipitation", true)
    end
    
    if TheWorld.components.um_snow_stormspawner and not TheWorld:HasTag("snowstormstart") then
        TheWorld:AddTag("snowstormstart")
        if TheWorld.net ~= nil then
            TheWorld.net:AddTag("snowstormstartnet")
        end
    end
end

-- ----------------------------------------------------------------------------
-- 第三阶段极光系统
-- ----------------------------------------------------------------------------

-- 极光参数
local AURORA_ORBIT_MIN_RADIUS = 22      -- 极光轨道最小半径
local AURORA_ORBIT_MAX_RADIUS = 28      -- 极光轨道最大半径
local AURORA_BLINK_INTERVAL = 1.5       -- 闪烁间隔（秒）
local AURORA_BLINKS_PER_ICE = 6         -- 每几次闪烁召唤一次冰阵
local AURORA_MOVE_SPEED = 10             -- 极光移动速度
local AURORA_IDLE_ANIMS = {"idle_loop", "idle_loop2", "idle_loop3"}  -- 闪烁动画序列

-- 竞技场边缘环带随机做环绕运动并闪烁
local function Phase3AuroraUpdate(inst)
    if not inst.boss2hm or not inst.boss2hm:IsValid() or 
       not inst.boss2hm.components.health or inst.boss2hm.components.health:IsDead() then
        -- boss 死亡，淡出消失
        if inst.disappear2hm then
            inst.disappear2hm = inst.disappear2hm + 1
            if inst.disappear2hm >= 5 then
                inst:Remove()
                return
            end
        else
            inst.disappear2hm = 1
        end
        inst.AnimState:SetMultColour(1, 1, 1, 0.2)
        return
    end
    
    inst.disappear2hm = nil
    
    -- 获取竞技场中心
    local cx, cz = GetArenaCenter(inst.boss2hm)
    if not cx then return end
    
    local current_time = GetTime()
    local x, y, z = inst.Transform:GetWorldPosition()
    
    -- 初始化极光状态
    if not inst.aurora_init2hm then
        inst.aurora_init2hm = true
        inst.aurora_target_angle2hm = inst.aurora_angle2hm or math.random() * math.pi * 2
        inst.aurora_target_radius2hm = AURORA_ORBIT_MIN_RADIUS + math.random() * (AURORA_ORBIT_MAX_RADIUS - AURORA_ORBIT_MIN_RADIUS)
        inst.aurora_next_change_time2hm = current_time + 3 + math.random() * 4  -- 3-7秒后改变方向
        inst.aurora_blink_count2hm = 0
        inst.aurora_blink_phase2hm = 0  -- 闪烁计数
        
        -- 循环闪烁
        local function PlayRandomAuroraIdle(inst)
            if not inst._killed and not inst:HasTag("INLIMBO") then
                local anim = AURORA_IDLE_ANIMS[math.random(#AURORA_IDLE_ANIMS)]
                inst.AnimState:PlayAnimation(anim)
                
                inst.aurora_blink_phase2hm = (inst.aurora_blink_phase2hm or 0) + 1
                
                if inst.aurora_blink_phase2hm % 3 == 0 then
                    inst.AnimState:SetMultColour(1, 1, 1, 1)
                elseif inst.aurora_blink_phase2hm % 3 == 1 then
                    inst.AnimState:SetMultColour(1, 1, 1, 0.6)
                else
                    inst.AnimState:SetMultColour(1, 1, 1, 0.35)
                end
                
                inst.aurora_blink_count2hm = (inst.aurora_blink_count2hm or 0) + 1
                
                -- 每4次闪烁召唤一次冰阵
                if inst.aurora_blink_count2hm >= AURORA_BLINKS_PER_ICE then
                    inst.aurora_blink_count2hm = 0
                    
                    inst.AnimState:SetMultColour(1, 1, 1, 1)
                    
                    local x, y, z = inst.Transform:GetWorldPosition()
                    local spell = SpawnPrefab("deer_ice_circle")
                    if spell then
                        if spell.TriggerFX then
                            spell:DoTaskInTime(0.5, spell.TriggerFX)
                        end
                        spell.Transform:SetPosition(x, 0, z)
                        spell:DoTaskInTime(1.5, spell.KillFX or spell.Remove)
                    end
                    
                    -- 播放冰阵音效
                    inst.SoundEmitter:PlaySound("dontstarve/creatures/together/deer/ice")
                end
                
                if math.random() < 0.5 then
                    inst.SoundEmitter:PlaySound("dontstarve/common/staff_star_create")
                end
            end
        end
        
        -- 动画结束后循环播放
        inst:ListenForEvent("animover", PlayRandomAuroraIdle)
        
        PlayRandomAuroraIdle(inst)
    end
    
    -- 随机改变目标方向和半径
    if current_time >= inst.aurora_next_change_time2hm then
        -- 0.3-0.8弧度
        local angle_delta = (math.random() * 0.5 + 0.3) * (inst.aurora_direction2hm or 1)  
        if math.random() < 0.3 then
            -- 30%概率反向
            inst.aurora_direction2hm = -(inst.aurora_direction2hm or 1)  
        end
        inst.aurora_target_angle2hm = (inst.aurora_target_angle2hm or 0) + angle_delta
        
        -- 随机选择新的目标半径
        inst.aurora_target_radius2hm = AURORA_ORBIT_MIN_RADIUS + math.random() * (AURORA_ORBIT_MAX_RADIUS - AURORA_ORBIT_MIN_RADIUS)
        
        inst.aurora_next_change_time2hm = current_time + 3 + math.random() * 4
    end
    
    -- 角度归一化
    if inst.aurora_target_angle2hm > math.pi * 2 then
        inst.aurora_target_angle2hm = inst.aurora_target_angle2hm - math.pi * 2
    elseif inst.aurora_target_angle2hm < 0 then
        inst.aurora_target_angle2hm = inst.aurora_target_angle2hm + math.pi * 2
    end
    
    -- 计算目标位置
    local target_x = cx + math.cos(inst.aurora_target_angle2hm) * inst.aurora_target_radius2hm
    local target_z = cz + math.sin(inst.aurora_target_angle2hm) * inst.aurora_target_radius2hm
    
    if inst.components.locomotor then
        local dx = target_x - x
        local dz = target_z - z
        local dist = math.sqrt(dx * dx + dz * dz)
        
        if dist > 1 then
            inst.components.locomotor:Stop()
            inst.components.locomotor:Clear()
            inst.components.locomotor:PushAction(BufferedAction(inst, nil, ACTIONS.WALKTO, nil, Vector3(target_x, 0, target_z)))
        end
    else
        local dx = target_x - x
        local dz = target_z - z
        local dist = math.sqrt(dx * dx + dz * dz)
        
        if dist > 0.5 then
            local move_dist = math.min(dist, AURORA_MOVE_SPEED * 0.5)
            local new_x = x + (dx / dist) * move_dist
            local new_z = z + (dz / dist) * move_dist
            inst.Transform:SetPosition(new_x, 0, new_z)
            x, z = new_x, new_z
        end
    end
    
    -- 检查是否处于逃避技能激活状态
    local is_flee_phase = inst.boss2hm._flee_skill_active == true
    
    -- 检查 boss 是否靠近极光
    local boss_x, boss_y, boss_z = inst.boss2hm.Transform:GetWorldPosition()
    local boss_dist_sq = (boss_x - x) * (boss_x - x) + (boss_z - z) * (boss_z - z)
    local absorb_range_sq = 25  -- 5格距离
    
    -- 检查吸收冷却
    local can_absorb = not inst.boss2hm._aurora_absorb_cd or 
                       (current_time - inst.boss2hm._aurora_absorb_cd) >= AURORA_ABSORB_COOLDOWN
    
    -- 逃避技能期间吸收极光回血
    if is_flee_phase and boss_dist_sq <= absorb_range_sq and can_absorb then
        -- boss 吸收极光，设置冷却
        inst.boss2hm._aurora_absorb_cd = current_time
        inst.boss2hm.components.health:DoDelta(800)
        
        -- 吸收特效
        local fx = SpawnPrefab("spider_heal_target_fx")
        if fx then
            fx.Transform:SetNoFaced()
            fx.Transform:SetPosition(x, y, z)
        end
        fx = SpawnPrefab("spider_heal_target_fx")
        if fx then
            fx.Transform:SetNoFaced()
            fx.Transform:SetPosition(boss_x, boss_y, boss_z)
            fx.Transform:SetScale(3, 3, 3)
        end
        
        -- 更新 boss 的极光计数
        if inst.boss2hm.aurora_count2hm then
            inst.boss2hm.aurora_count2hm = inst.boss2hm.aurora_count2hm - 1
        end
        
        inst.SoundEmitter:PlaySound("dontstarve/common/staff_star_create")
        inst:Remove()
        return
    end
end

-- 生成天三极光的函数
local function GeneratePhase3Auroras(inst)
    if inst:HasTag("swc2hm") then return end
    if not inst:IsValid() or inst:HasTag("INLIMBO") then return end
    
    local static_count = inst.moon_device_static_count2hm or TUNING.moon_device_static_count2hm or 1
    static_count = math.max(1, math.min(3, static_count))
    
    -- 静电数量对应极光数量：1→3, 2→5, 3→7
    local aurora_count = static_count * 2 + 1
    
    -- 如果已有保存的极光数量，使用保存的
    if inst.aurora_count2hm and inst.aurora_count2hm > 0 then
        aurora_count = inst.aurora_count2hm
    end
    
    inst.aurora_count2hm = aurora_count
    
    -- 获取竞技场中心
    local cx, cz = GetArenaCenter(inst)
    if not cx then return end
    
    -- 在环状轨道上均匀分布生成极光
    local angle_step = math.pi * 2 / aurora_count
    local avg_radius = (AURORA_ORBIT_MIN_RADIUS + AURORA_ORBIT_MAX_RADIUS) / 2
    for i = 1, aurora_count do
        local angle = (i - 1) * angle_step + math.random() * 0.5 - 0.25  -- 初始角度有随机偏移
        local spawn_radius = AURORA_ORBIT_MIN_RADIUS + math.random() * (AURORA_ORBIT_MAX_RADIUS - AURORA_ORBIT_MIN_RADIUS)
        local spawn_x = cx + math.cos(angle) * spawn_radius
        local spawn_z = cz + math.sin(angle) * spawn_radius
        
        local aurora = SpawnPrefab("staffcoldlight2hm")
        if aurora then
            aurora.Transform:SetPosition(spawn_x, 0, spawn_z)
            aurora.boss2hm = inst
            aurora.aurora_angle2hm = angle
            aurora.aurora_direction2hm = math.random() > 0.5 and 1 or -1  -- 随机方向
            aurora.aurora_phase2hm = math.random() * math.pi * 2  -- 随机相位（影响闪烁）
            
            aurora.AnimState:SetMultColour(1, 1, 1, 0.6)
            
            -- 标记为天三极光，用于让原始iceboss逻辑跳过处理
            aurora:AddTag("phase3_aurora2hm")
            aurora.phase3_arena_aurora = true  -- 额外标记
            
            if aurora.components.locomotor then
                aurora.components.locomotor:Stop()
                aurora.components.locomotor:Clear()
            end
            
            -- 禁用 timer 防止自动消失
            if aurora.components.timer then
                aurora.components.timer:StopTimer("extinguish")
            end
            
            aurora.task2hm = aurora:DoPeriodicTask(0.5, Phase3AuroraUpdate)
        end
    end
end

-- 保存极光数量
local function SavePhase3AuroraCount(inst, data)
    if inst.aurora_count2hm then
        data.aurora_count = inst.aurora_count2hm
    end
end

-- 加载极光数量并重新生成
local function LoadPhase3AuroraCount(inst, data)
    if data and data.aurora_count then
        inst.aurora_count2hm = data.aurora_count
        if inst.aurora_count2hm > 0 then
            inst:DoTaskInTime(1, GeneratePhase3Auroras)
        end
    end
end

-- ----------------------------------------------------------------------------
-- 第三阶段初始化
-- ----------------------------------------------------------------------------

AddPrefabPostInit("alterguardian_phase3", function(inst)
    inst:AddTag("toughworker")
    
    if not TheWorld.ismastersim then return end
    
    if inst.components.freezable then inst:RemoveComponent("freezable") end
    
    AddMinimapIcon(inst)
    AddPrototyper(inst)
    -- 锁定冬季
    AddSeasonLock(inst, 3) 
    
    inst:ListenForEvent("getattacked2hm", Phase3GetAttacked)
    inst:ListenForEvent("death", Phase3OnDeath)
    
    -- 逃避技能监控
    inst:DoTaskInTime(1, StartFleeSkillMonitor)
    
    -- 死亡时停止逃避技能
    inst:ListenForEvent("death", function(inst)
        StopFleeSkill(inst)
        if inst._flee_skill_monitor_task then
            inst._flee_skill_monitor_task:Cancel()
            inst._flee_skill_monitor_task = nil
        end
    end)
    
    if not inst.components.persistent2hm then inst:AddComponent("persistent2hm") end
    
    -- 初始化静电数量
    inst.moon_device_static_count2hm = TUNING.moon_device_static_count2hm or 1
    
    -- 血量保存和恢复机制
    inst.onsave2hm = function(inst, data)
        data.static_count = inst.moon_device_static_count2hm
        if inst.components.health then
            data.health_percent = inst.components.health:GetPercent()
        end
        SavePhase3AuroraCount(inst, data)
    end
    
    inst.onload2hm = function(inst, data)
        if data then
            if data.static_count then
                inst.moon_device_static_count2hm = data.static_count
                -- 更新全局 TUNING
                TUNING.moon_device_static_count2hm = data.static_count
                UpdateAlterguardianHealth(data.static_count)
            end
            LoadPhase3AuroraCount(inst, data)
        end
    end
    
    inst:DoTaskInTime(0, function()
        if inst:IsValid() and not inst:HasTag("swc2hm") and not inst:HasTag("skill_shadow2hm") then
            SetupAlterguardianHealth(inst, 3)
        end
    end)
    
    if TUNING.shadowworld2hm then
        inst.swp2hmfn = Phase3ShadowWorldFn
    else
        Phase3ShadowWorldFn(inst)
    end
    

    if inst.components.combat then
        inst.components.combat:SetKeepTargetFunction(Phase3KeepTarget)
    end
    
    -- 月能汲取
    AddMoonEnergyAbsorption(inst)
    inst:ListenForEvent("death", function(inst)
        RemoveMoonEnergyAbsorption(inst)
    end)
    
    -- 暴风雪
    inst:DoTaskInTime(0.5, StartPhase3Snowstorm)
    inst._snowstorm_task = inst:DoPeriodicTask(10, MaintainSnowstorm)
    -- 死亡/移除时停止
    inst:ListenForEvent("death", StopPhase3Snowstorm)
    inst:ListenForEvent("onremove", function(inst)
        StopPhase3Snowstorm(inst)
        if inst._snowstorm_task then
            inst._snowstorm_task:Cancel()
            inst._snowstorm_task = nil
        end
    end)
    
    -- 禁用脱加载回血
    inst._start_sleep_time = nil
    if inst.OnEntitySleep then
        inst:RemoveEventCallback("entitysleep", inst.OnEntitySleep)
    end
    if inst.OnEntityWake then
        inst:RemoveEventCallback("entitywake", inst.OnEntityWake)
    end
    inst.OnEntitySleep = function(inst) end
    inst.OnEntityWake = function(inst) end
    
    -- 阶段切换时继承竞技场状态
    inst:DoTaskInTime(0, function()
        if not inst:IsValid() or inst:HasTag("INLIMBO") then return end
        
        if inst:HasTag("swc2hm") or inst:HasTag("skill_shadow2hm") then return end
        
        local manager = TheWorld.components.alterguardian_arena_manager2hm
        if not manager then return end
        
        if inst._arena_manager or manager:GetBoss() == inst then
            inst._arena_manager = manager
        else
            if manager:TryRestoreConnection(inst) then
                inst._arena_manager = manager
            else
                local helper = TheWorld.net and TheWorld.net.components.alterguardian_floor_helper2hm
                local marker = helper and helper:GetMarker()
                
                manager:TrackBoss(inst)
                inst._arena_manager = manager
                if manager:GetPhase() ~= 3 then
                    manager:SetPhase(3)
                end

                if not manager:IsBarrierUp() and marker then
                    manager:RaiseBarrier()
                end
            end
        end
        
        -- 将出生点设置为竞技场中心
        local cx, cy, cz = manager:GetArenaCenter()
        if cx and cz and inst.components.knownlocations then
            local center = Point(cx, cy or 0, cz)
            inst.components.knownlocations:RememberLocation("spawnpoint", center)
            inst.components.knownlocations:RememberLocation("geyser", center)
            
            -- 是否需要移动到中心
            local dist_sq = inst:GetDistanceSqToPoint(cx, cy or 0, cz)
            if dist_sq > STRICT_CENTER_THRESHOLD_SQ then
                inst:DoTaskInTime(0.5, function()
                    if inst:IsValid() and inst.sg and not inst.sg:HasStateTag("busy") then
                        inst.sg:GoToState("move_to_center", {center = center, next_state = "idle"})
                    end
                end)
            end
        end
        
        -- 生成极光（如果不是从存档加载的）
        if not inst.aurora_count2hm then
            inst:DoTaskInTime(1.5, GeneratePhase3Auroras)
        end
    end)
    
    -- 关闭竞技场并移除 marker
    inst:ListenForEvent("death", function(inst)
        local manager = inst._arena_manager or TheWorld.components.alterguardian_arena_manager2hm
        if manager and manager:GetBoss() == inst then
            manager:OnBossDefeated()
            manager:RemoveArenaMarker()
        end
    end)
    
    inst:ListenForEvent("onremove", function(inst)
        local manager = inst._arena_manager or TheWorld.components.alterguardian_arena_manager2hm
        if manager and manager:IsInBattle() and manager:GetBoss() == inst then
            manager:OnBossDefeated()
            manager:RemoveArenaMarker()
        end
    end)

end)

-- ----------------------------------------------------------------------------
-- 旧靴子免疫冰地皮
-- ----------------------------------------------------------------------------

-- 取消旧靴子效果
local function BootlegCancel(inst)
    local old_owner = inst.oldowner2hm
    inst.oldowner2hm = nil
    
    if old_owner and old_owner:IsValid() and old_owner.bootlegs2hm then
        for i = #old_owner.bootlegs2hm, 1, -1 do
            if old_owner.bootlegs2hm[i] == inst then
                table.remove(old_owner.bootlegs2hm, i)
                break
            end
        end
        

        if IsTableEmpty(old_owner.bootlegs2hm) then
            old_owner.bootlegs2hm = nil

            if old_owner.bootleg_speedcheck_task2hm then
                old_owner.bootleg_speedcheck_task2hm:Cancel()
                old_owner.bootleg_speedcheck_task2hm = nil
            end
            
            -- 恢复滑倒效果
            if not old_owner:HasTag("playerghost") and not old_owner.components.slipperyfeet then
                old_owner:AddComponent("slipperyfeet")
            end
        end
    end
end

local function CheckSpeedAndUpdateSlippery(owner)
    if not owner or not owner:IsValid() or owner:HasTag("playerghost") then
        return
    end
    
    local has_bootleg = owner.bootlegs2hm and not IsTableEmpty(owner.bootlegs2hm)
    if not has_bootleg then
        return
    end
    
    local speed = 0
    if owner.components.locomotor then
        speed = owner.components.locomotor:GetRunSpeed()
    end
    
    if speed < 8 then
        if owner.components.slipperyfeet then
            owner:RemoveComponent("slipperyfeet")
        end
    else
        if not owner.components.slipperyfeet then
            owner:AddComponent("slipperyfeet")
        end
    end
end

-- 更新旧靴子效果
local function BootlegUpdate(inst)
    local owner = inst.components.inventoryitem:GetGrandOwner()
    if owner == inst.oldowner2hm then
        CheckSpeedAndUpdateSlippery(owner)
        return
    end
    
    BootlegCancel(inst)
    
    if owner and owner:IsValid() and owner:HasTag("player") then
        inst.oldowner2hm = owner
        owner.bootlegs2hm = owner.bootlegs2hm or {}
        table.insert(owner.bootlegs2hm, inst)
        
        CheckSpeedAndUpdateSlippery(owner)
        
        if not owner.bootleg_speedcheck_task2hm then
            owner.bootleg_speedcheck_task2hm = owner:DoPeriodicTask(.5, function()
                CheckSpeedAndUpdateSlippery(owner)
            end)
        end
    end
end

local function DelayBootlegUpdate(inst)
    inst:DoTaskInTime(0, BootlegUpdate)
end

AddPrefabPostInit("bootleg", function(inst)
    if not TheWorld.ismastersim then
        return
    end
    
    inst:ListenForEvent("onputininventory", DelayBootlegUpdate)
    inst:ListenForEvent("ondropped", DelayBootlegUpdate)
    inst:ListenForEvent("onremove", BootlegCancel)
end)

-- ----------------------------------------------------------------------------
-- 第三阶段冰岛地皮生成
-- ----------------------------------------------------------------------------

local ICE_AOE_TARGET_TAGS = {"_combat"}
local ICE_AOE_TARGET_CANT_TAGS = {"INLIMBO", "flight", "invisible", "playerghost", "lunar_aligned"}
local MIN_DISTANCE_FROM_ENTITIES = ((TILE_SCALE / 2) + 1.0) * 1.4142
local CUSTOM_DEPLOY_IGNORE_TAGS = {
    "NOBLOCK", "player", "FX", "INLIMBO", "DECOR",
    "ignorewalkableplatforms", "ignorewalkableplatformdrowning",
    "activeprojectile", "flying", "kelp", "_inventoryitem", "_health", "moonglass"
}

-- 创建区域冰地皮（从内到外按圈生成）
local function CreateAreaIceTiles(inst, immediate)
    if not TheWorld.components.oceanicemanager then
        return
    end
    
    local manager = inst._arena_manager or TheWorld.components.alterguardian_arena_manager2hm
    if not manager then return end
    
    -- 如果管理器已经有冰面数据了，不重复创建
    if manager:HasArenaIceTiles() then
        return
    end
    
    -- 必须处于三阶段战斗状态
    if manager:GetState() ~= manager.STATES.PHASE3 then
        return
    end
    
    -- 获取竞技场中心位置（而非Boss当前位置）
    local cx, cy, cz = manager:GetArenaCenter()
    if not cx or not cz then
        return
    end
    
    local tile_x, tile_y = TheWorld.Map:GetTileCoordsAtPoint(cx, 0, cz)
    local center_x, center_y, center_z = TheWorld.Map:GetTileCenterPoint(tile_x, tile_y)
    
    -- 存储冰面数据到管理器
    local data = {}
    manager:SetArenaIceTiles(data)
    
    -- 扫描竞技场内所有可以生成冰的瓦片，并按到中心的距离分组
    local max_radius = 25
    local tiles_by_ring = {}  -- {distance = {tiles}}
    
    -- 先扫描整个区域，统计所有可以生成的冰面
    for dx = -max_radius, max_radius, 4 do
        for dz = -max_radius, max_radius, 4 do
            local px = center_x + dx
            local pz = center_z + dz
            local dist_sq = dx * dx + dz * dz
            
            if dist_sq <= max_radius * max_radius then
                local ptile_x, ptile_y = TheWorld.Map:GetTileCoordsAtPoint(px, 0, pz)
                local tile = TheWorld.Map:GetTileAtPoint(px, 0, pz)
                
                local can_ice = false
                if tile == WORLD_TILES.OCEAN_ICE then
                    can_ice = false
                elseif IsLandTile(tile) then
                    can_ice = true
                else
                    can_ice = true
                    local tile_center_x, tile_center_y, tile_center_z = TheWorld.Map:GetTileCenterPoint(ptile_x, ptile_y)
                    if not IsTableEmpty(TheSim:FindEntities(tile_center_x, 0, tile_center_z, MIN_DISTANCE_FROM_ENTITIES, nil, CUSTOM_DEPLOY_IGNORE_TAGS)) then
                        can_ice = false
                    end
                end
                
                if can_ice then
                    -- 按距离分组（每4个距离单位为一圈）
                    local ring = math.floor(math.sqrt(dist_sq) / 4)
                    tiles_by_ring[ring] = tiles_by_ring[ring] or {}
                    table.insert(tiles_by_ring[ring], {x = ptile_x, y = ptile_y})
                end
            end
        end
    end
    
    -- 从内到外，按圈生成冰面
    local max_ring = math.floor(max_radius / 4)
    for ring = 0, max_ring do
        local tiles = tiles_by_ring[ring]
        if tiles and #tiles > 0 then
            local delay = immediate and 0 or (ring * 6 * FRAMES)  
            
            TheWorld:DoTaskInTime(delay, function()
                -- 检查管理器是否仍处于三阶段
                if not manager or manager:GetState() ~= manager.STATES.PHASE3 then
                    return
                end
                
                for _, tile_pos in ipairs(tiles) do
                    table.insert(data, tile_pos)
                    TheWorld.components.oceanicemanager:CreateIceAtTile(tile_pos.x, tile_pos.y)
                end
            end)
        end
    end
end
-- ----------------------------------------------------------------------------
-- 第三阶段虚影攻击
-- ----------------------------------------------------------------------------

-- 虚影消失
local function KillGestalt(inst)
    inst.components.health:Kill()
end

-- 虚影攻击计数
local function OnGestaltAttack(inst)
    inst.attacktimes = (inst.attacktimes or 0) + 1
    if inst.attacktimes >= 2 then
        inst:DoTaskInTime(30 * FRAMES, KillGestalt)
    end
end

-- 生成大虚影攻击
local function DoGestaltAttack(inst)
    if inst._stop_task and 
       TUNING.alterguardianseason2hm == 3 and 
       TheWorld.state.isalterawake then
        local x, y, z = inst.Transform:GetWorldPosition()
        local gestalt = SpawnPrefab("gestalt_guard")
        gestalt.AnimState:SetAddColour(5 / 255, 87 / 255, 255 / 255, 0.8)
        gestalt.Transform:SetPosition(x, 0, z)
        gestalt.persists = false
        gestalt.entity:SetCanSleep(false)
        gestalt:ListenForEvent("doattack", OnGestaltAttack)
        gestalt:DoTaskInTime(math.random(15, 45), KillGestalt)
        
        if inst.find_attack_victim then
            local attack_target = inst:find_attack_victim()
            if attack_target ~= nil then
                gestalt.components.combat:SetTarget(attack_target)
            end
        end
    end
end

-- 虚影投射物动画结束时生成虚影
local function OnGestaltProjAnimOver(inst)
    if TUNING.alterguardianseason2hm == 3 and 
       TheWorld.state.isalterawake and
       (inst.AnimState:IsCurrentAnimation("emerge") or inst.AnimState:IsCurrentAnimation("attack")) then
        inst:DoTaskInTime(24 * FRAMES, DoGestaltAttack)
    end
end

AddPrefabPostInit("gestalt_alterguardian_projectile", function(inst)
    if not TheWorld.ismastersim then
        return
    end
    
    if TUNING.alterguardianseason2hm == 3 and 
       TheWorld.state.isalterawake and 
       math.random() < 0.5 then
        inst:ListenForEvent("animover", OnGestaltProjAnimOver)
    end
end)

-- ----------------------------------------------------------------------------
-- 第三阶段陷阱攻击
-- ----------------------------------------------------------------------------

SetSharedLootTable2hm("moonglass_trap", {{"moonglass", 0.05}})

-- 生成保护陷阱
local function SpawnProtectTrap(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local trap = SpawnPrefab("alterguardian_phase3trap")
    trap.persists = false
    trap.components.lootdropper:SetChanceLootTable()
    trap.Transform:SetPosition(x, y, z)
    trap.AnimState:SetScale(0.6, 0.6)
    inst:Remove()
end

-- 环绕陷阱攻击
local function DoTrapAttack(inst)

    local POINTS_ANGLE_DIFF = PI / 18
    local RADIUS = math.sqrt(TUNING.ALTERGUARDIAN_PHASE3_SUMMONRSQ)
    local ix, _, iz = inst.Transform:GetWorldPosition()
    local angle = 0
    
    while angle < 2 * PI do
        local x = ix + RADIUS * math.cos(angle)
        local z = iz + RADIUS * math.sin(angle)
        local projectile = SpawnPrefab("alterguardian_phase3trapprojectile")
        projectile.Transform:SetPosition(x, 0, z)
        projectile.AnimState:SetScale(0.6, 0.6)
        projectile:SetGuardian(inst)
        angle = angle + POINTS_ANGLE_DIFF
        
        if projectile.event_listeners and projectile.event_listeners.animover then
            for _, listeners in pairs(projectile.event_listeners.animover) do
                for index, _ in pairs(listeners) do
                    listeners[index] = SpawnProtectTrap
                    break
                end
            end
        end
    end
end

-- 陷阱移除时生成冰法阵
local function OnPhase3TrapProjectileRemove(inst)
    if inst.components.lootdropper and inst.components.lootdropper.chanceloottable then
        local spell = SpawnPrefab("deer_ice_circle")
        if spell.TriggerFX then
            spell:DoTaskInTime(1, spell.TriggerFX) 
        end
        spell.Transform:SetPosition(inst.Transform:GetWorldPosition())
        spell:DoTaskInTime(1.5, spell.KillFX) 
        
        local x, y, z = inst.Transform:GetWorldPosition()
        if TheWorld.components.dockmanager ~= nil then
            TheWorld.components.dockmanager:DamageDockAtPoint(x, y, z, 1000)
        end
    end
end

AddPrefabPostInit("alterguardian_phase3trap", function(inst)
    if not TheWorld.ismastersim then return end
    inst:ListenForEvent("onremove", OnPhase3TrapProjectileRemove)
end)

-- ----------------------------------------------------------------------------
-- 第三阶段激光冰冻增强
-- ----------------------------------------------------------------------------

local MIN_LASER_TEMPERATURE = -10  -- 激光降温的下限
local LASER_TEMP_DELTA = -5       -- 每次激光的降温量


-- 原版逻辑：解冻/减少冰冻层数 + 升温
--   if IsFrozen then Unfreeze() 
--   elseif coldness > 0 then AddColdness(-2)
--   if temp < 10 then DoDelta(升温到10)
-- 监听原版命中后发送的onalterguardianlasered 事件，在原版逻辑执行后的下一帧反转效果
local function OnAlterGuardianLasered(inst)
    if not inst:IsValid() or not inst.components.health or inst.components.health:IsDead() then
        return
    end
    
    local freezable = inst.components.freezable
    local temperature = inst.components.temperature
    
    local pre_coldness = freezable and freezable.coldness or 0
    local pre_frozen = freezable and freezable:IsFrozen() or false
    local pre_temp = temperature and temperature:GetCurrent() or nil
    
    inst:DoTaskInTime(0, function()
        if not inst:IsValid() or not inst.components.health or inst.components.health:IsDead() then
            return
        end
        
        local cur_freezable = inst.components.freezable
        local cur_temperature = inst.components.temperature
        
        if cur_freezable then
            local cur_coldness = cur_freezable.coldness or 0
            
            if pre_frozen then

                cur_freezable.coldness = pre_coldness + 1
                if cur_freezable.coldness >= cur_freezable.resistance then
                    cur_freezable:Freeze()
                end
            elseif pre_coldness > 0 and cur_coldness < pre_coldness then

                cur_freezable:AddColdness(pre_coldness + 1 - cur_coldness)
            else
                cur_freezable:AddColdness(1)
            end
        end
    
        if cur_temperature and pre_temp then
            local cur_temp = cur_temperature:GetCurrent()
            if cur_temp > pre_temp then
                cur_temperature:SetTemperature(pre_temp)
            end
            
            local new_temp = math.max(MIN_LASER_TEMPERATURE, cur_temperature:GetCurrent() + LASER_TEMP_DELTA)
            cur_temperature:SetTemperature(new_temp)
        elseif cur_temperature then
            local new_temp = math.max(MIN_LASER_TEMPERATURE, cur_temperature:GetCurrent() + LASER_TEMP_DELTA)
            cur_temperature:SetTemperature(new_temp)
        end
    end)
end

local function SetupLaserFreezeListener(inst)
    if not TheWorld.ismastersim then return end
    
    if inst.components.freezable and not inst._laser_freeze_listener_added then
        inst._laser_freeze_listener_added = true
        inst:ListenForEvent("onalterguardianlasered", OnAlterGuardianLasered)
    end
end

AddPlayerPostInit(SetupLaserFreezeListener)

AddComponentPostInit("freezable", function(self)
    if TheWorld.ismastersim then
        local inst = self.inst
        if not inst._laser_freeze_listener_added then
            inst._laser_freeze_listener_added = true
            inst:ListenForEvent("onalterguardianlasered", OnAlterGuardianLasered)
        end
    end
end)

-- ----------------------------------------------------------------------------
-- 第三阶段激光分身系统
-- ----------------------------------------------------------------------------

-- 移除第三阶段激光分身
local function RemovePhase3LaserShadow(inst)
    if inst._laser_shadow and inst._laser_shadow:IsValid() then
        FadeOutAndRemoveShadow(inst._laser_shadow)
        inst._laser_shadow = nil
    end
end

-- 天三分身（延迟生成，出现时直接攻击）
local function SetupPhase3LaserShadow(inst, target, laser_type)
    if not inst or not inst:IsValid() then return nil end
    
    RemovePhase3LaserShadow(inst)
    
    -- 延迟生成影子
    local SHADOW_SPAWN_DELAY = 1.5
    
    inst:DoTaskInTime(SHADOW_SPAWN_DELAY, function()
        if not inst:IsValid() or not target or not target:IsValid() then return end
        
        local x, y, z = inst.Transform:GetWorldPosition()
        local rotation = inst.Transform:GetRotation()
        
        -- 计算分身的生成位置：在本体侧面
        local side_angle = rotation + (math.random() > 0.5 and 90 or -90)
        local offset_distance = 4
        local rad = side_angle * DEGREES
        local spawn_x = x + math.cos(rad) * offset_distance
        local spawn_z = z - math.sin(rad) * offset_distance
        
        local shadow = SpawnPrefab(inst.prefab)
        if not shadow then return end
        
        shadow.Transform:SetPosition(spawn_x, y, spawn_z)
        shadow.Transform:SetRotation(rotation)
        
        shadow:AddTag("swc2hm")
        shadow:AddTag("skill_shadow2hm")
        shadow:AddTag("laser_shadow2hm")
        shadow:AddTag("notarget")
        shadow:AddTag("NOCLICK")
        shadow.swp2hm = inst
        shadow.persists = false
        shadow.disablesw2hm = true
        
        -- 暗影外观
        if shadow.AnimState then
            shadow.AnimState:SetMultColour(0, 0, 0, 0.5)
        end
        
        -- 禁用不需要的组件
        if shadow.components.lootdropper then
            shadow.components.lootdropper:SetLoot()
            shadow.components.lootdropper:SetChanceLootTable()
        end
        if shadow.components.health then
            shadow.components.health:SetInvincible(true)
        end
        if shadow.components.combat then
            shadow.components.combat:SetTarget(target)
        end
        
        -- 禁用小地图图标
        if shadow.MiniMapEntity then
            shadow.MiniMapEntity:SetEnabled(false)
        end
        
        -- 停止AI
        shadow:StopBrain()
        
        -- 快速淡入效果
        if not shadow.components.spawnfader2hm then
            shadow:AddComponent("spawnfader2hm")
        end
        shadow.components.spawnfader2hm:FadeIn(0.3)  -- 快速淡入
        
        -- 监听分身状态变化，当攻击完成后自动消失
        local function OnShadowStateChanged(shadow, data)
            if not shadow:IsValid() then return end
            
            -- 如果从攻击状态切换到idle，说明攻击完成了
            if data and data.statename == "idle" and shadow._just_attacked then
                shadow:DoTaskInTime(0.3, function()
                    if shadow:IsValid() then
                        FadeOutAndRemoveShadow(shadow)
                    end
                end)
            elseif data and (data.statename == "atk_beam" or data.statename == "atk_sweep") then
                shadow._just_attacked = true
            end
        end
        
        shadow:ListenForEvent("newstate", OnShadowStateChanged)
        
        -- 影子生成后攻击
        shadow:DoTaskInTime(0.2, function()
            if shadow:IsValid() and shadow.sg and target and target:IsValid() then
                local shadow_attack_state
                if laser_type == "beam" then
                    shadow_attack_state = "atk_sweep"  -- 本体用beam，分身用sweep（弧形激光）
                else
                    shadow_attack_state = "atk_beam"   -- 本体用sweep，分身用beam（直线三束激光）
                end
                
                -- 进入攻击状态，状态机会处理激光发射
                shadow.sg:GoToState(shadow_attack_state, target)
            end
        end)
        
        -- 安全移除
        shadow:DoTaskInTime(3, function()
            if shadow:IsValid() and not shadow._removing then
                shadow._removing = true
                FadeOutAndRemoveShadow(shadow)
            end
        end)
        
        inst._laser_shadow = shadow
    end)
end

-- 获取竞技场中心位置
local function GetArenaCenterPosition(inst)
    local manager = inst._arena_manager or TheWorld.components.alterguardian_arena_manager2hm
    if manager then
        local in_battle = manager:IsInBattle()
        if in_battle then
            local cx, cy, cz = manager:GetArenaCenter()
            if cx and cz then
                return Point(cx, cy or 0, cz)
            end
        end
    end
    return nil
end

-- 检查竞技场是否存在且有效
local function IsArenaValid(inst)
    local manager = inst._arena_manager or TheWorld.components.alterguardian_arena_manager2hm
    if not manager then 
        return false 
    end
    
    if not manager:IsInBattle() then 
        return false 
    end
    
    local cx, cy, cz = manager:GetArenaCenter()
    local valid = cx ~= nil and cz ~= nil
    return valid
end

-- 中心才能放场地技能
local function IsAtArenaCenter(inst)
    -- 竞技场不存在，允许使用所有技能
    if not IsArenaValid(inst) then
        return true
    end
    
    local center = GetArenaCenterPosition(inst)
    if center then
        local dist_sq = inst:GetDistanceSqToPoint(center:Get())
        return dist_sq <= STRICT_CENTER_THRESHOLD_SQ
    end
    -- 无法获取中心位置
    return true
end

-- 检查是否处于残血模式（血量低于40%）
local function IsInRageMode(inst)
    return inst.components.health and inst.components.health:GetPercent() < FLEE_HP_THRESHOLD
end

local function NeedsMoveToCenter(inst)
    -- 逃避技能激活时，不回中心
    if IsFleeSkillActive(inst) then
        return false, nil
    end
    
    -- 如果竞技场不存在，不需要移动
    if not IsArenaValid(inst) then
        return false, nil
    end
    
    local center = GetArenaCenterPosition(inst)
    if center then
        local dist_sq = inst:GetDistanceSqToPoint(center:Get())
        local needs = dist_sq > STRICT_CENTER_THRESHOLD_SQ
        return needs, center
    end
    return false, nil
end

-- ----------------------------------------------------------------------------
-- 第三阶段状态机修改
AddStategraphPostInit("alterguardian_phase3", function(sg)
    
    -- 用于出生后回到竞技场中心
    local move_to_center_state = State{
        name = "move_to_center",
        -- 不使用moving标签，避免被CommonHandlers.OnLocomote打断
        tags = {"busy", "charge", "canrotate"},
        
        onenter = function(inst, data)
            -- data = {next_state = "idle", center = center_point}
            inst.sg.statemem.center = data and data.center or GetArenaCenterPosition(inst)
            inst.sg.statemem.next_state = data and data.next_state or "idle"
            inst.sg.statemem.attack_count = 0  -- 跟踪受击次数
            
            if not inst.sg.statemem.center then
                inst.sg:GoToState("idle")
                return
            end
            
            inst.sg.mem.isdodging = true
            -- 使用Physics移动
            inst.components.locomotor:Stop()

            inst:ForceFacePoint(inst.sg.statemem.center:Get())

            local speed = (TUNING.ALTERGUARDIAN_PHASE3_WALK_SPEED or 4) * 1.5
            inst.Physics:SetMotorVelOverride(speed, 0, 0)
            
            inst.AnimState:PlayAnimation("walk_loop", true)
            
            inst.sg:SetTimeout(10) 
        end,
        
        onupdate = function(inst)
            local center = inst.sg.statemem.center
            if center then
                inst:ForceFacePoint(center:Get())
                
                local dist_sq = inst:GetDistanceSqToPoint(center:Get())
                if dist_sq <= STRICT_CENTER_THRESHOLD_SQ then
                    local next_state = inst.sg.statemem.next_state or "idle"
                    inst.sg:GoToState(next_state)
                end
            end
        end,
        
        ontimeout = function(inst)
            inst.sg:GoToState("idle")
        end,
        
        events = {
            EventHandler("locomote", function(inst) end),
            -- 允许受击但不中断移动，只是记录
            EventHandler("attacked", function(inst)
                inst.sg.statemem.attack_count = (inst.sg.statemem.attack_count or 0) + 1
                -- 受击5次以上强制进入idle处理战斗
                if inst.sg.statemem.attack_count >= 5 then
                    inst.sg:GoToState("idle")
                end
            end),
        },
        
        onexit = function(inst)
            inst.Physics:ClearMotorVelOverride()
            inst.Physics:Stop()
            inst.sg.mem.isdodging = nil
        end,
    }
    
    sg.states["move_to_center"] = move_to_center_state
    
    -- 召唤虚影陷阱只能在竞技场中心使用
    local original_doattack = sg.events["doattack"]
    if original_doattack then
        local original_fn = original_doattack.fn
        sg.events["doattack"] = EventHandler("doattack", function(inst, data)
            if not (inst.components.health:IsDead() or inst.sg:HasStateTag("busy"))
                    and (data.target ~= nil and data.target:IsValid()) then
                
                if not IsFleeSkillActive(inst) then
                    local at_center = IsAtArenaCenter(inst)
                    
                    if not at_center then
                        -- 通过让场地技能的条件判断失败来强制使用远程攻击
                        local dsq_to_target = inst:GetDistanceSqToInst(data.target)
                        
                        local use_summon = not inst.components.timer:TimerExists("summon_cd") and 
                                           dsq_to_target < (TUNING.ALTERGUARDIAN_PHASE3_SUMMONRSQ - 36)
                        
                        local geyser_pos = inst.components.knownlocations:GetLocation("geyser")
                        local use_traps = not inst.components.timer:TimerExists("traps_cd")
                                and GetTableSize(inst._traps or {}) <= 4
                                and (geyser_pos == nil
                                    or inst:GetDistanceSqToPoint(geyser_pos:Get()) < (TUNING.ALTERGUARDIAN_PHASE3_GOHOMEDSQ / 2))
                        
                        if use_summon or use_traps then
                            -- 需要使用场地技能但不在中心，重置攻击冷却让brain的GoHome生效
                            inst.components.combat:ResetCooldown()
                            return
                        end
                    end
                end
            end
            
            return original_fn(inst, data)
        end)
    end

    local OnEnterIdle = sg.states.idle.onenter
    sg.states.idle.onenter = function(inst, ...)
        OnEnterIdle(inst, ...)
        TryLockSeason(inst)
        -- 标记所有玩家可被虚影攻击
        for _, player in ipairs(AllPlayers) do
            if player and not player:HasTag("gestalt_possessable") then
                player:AddTag("gestalt_possessable")
            end
        end

        -- 是否需要回到竞技场中心
        local is_shadow = inst:HasTag("skill_shadow2hm") or inst:HasTag("swc2hm") or 
                          inst:HasTag("laser_shadow2hm") or inst.swp2hm ~= nil or 
                          inst.disablesw2hm == true
        
        if not is_shadow then
            local needs_move, center = NeedsMoveToCenter(inst)
            
            if needs_move and center then
                -- 使用 brain 的逻辑强制回家
                inst.sg.mem.isdodging = true
                -- 直接切换到 move_to_center 状态
                inst.sg:GoToState("move_to_center", {center = center, next_state = "idle"})
                return
            end
        end
    end
    
    -- ----------------------------------------------------------------------------
    -- 原版激光：beam在35帧发射，sweep在37帧发射，
    -- 第一波立即发射，第二波在SECOND_BLAST_TIME(22帧)后发射，月火跟随激光同步生成

    local MOONFIRE_SCALE = 1.0              -- 月火大小
    local MOONFIRE_DAMAGE = 20              -- 月火伤害
    local MOONFIRE_PLANAR = 5               -- 月火位面伤害
    local SECOND_BLAST_DELAY = 22 * FRAMES  -- 第二激光延迟
    
    local BEAM_TRIGGER_FRAME = 35        -- beam激光触发帧
    local SWEEP_TRIGGER_FRAME = 37       -- sweep激光触发帧
    local BASE_NUM_STEPS = 10            -- 基础步数
    local STEP = 1.0                     -- 步长
    local BASE_SWEEP_DISTANCE = 8        -- sweep基础距离
    local MIN_SWEEP_DISTANCE = 3         -- sweep最小距离
    local SWEEP_ANGULAR_LENGTH = 75      -- sweep角度范围
    local TRIBEAM_ANGLEOFF = PI/5        -- beam三束激光角度偏移
    
    -- 在指定位置生成单个月火
    local function SpawnMoonfireAtPoint(x, z, owner)
        local fx = SpawnPrefab("warg_mutated_breath_fx")
        if fx then
            fx.Transform:SetPosition(x, 0, z)
            if fx.SetFXOwner then
                fx:SetFXOwner(nil, owner)
            end
            if fx.ConfigureDamage then
                fx:ConfigureDamage(MOONFIRE_DAMAGE, MOONFIRE_PLANAR)
            end
            if fx.RestartFX then
                -- 使用tallflame让火焰持续更久
                fx:RestartFX(MOONFIRE_SCALE, "latefade", nil, true)
            end
        end
        return fx
    end
    
    -- 检查是否是分身（分身不生成月火）
    local function IsShadowEntity(inst)
        return inst:HasTag("skill_shadow2hm") or 
               inst:HasTag("swc2hm") or 
               inst:HasTag("laser_shadow2hm") or 
               inst.swp2hm ~= nil or
               inst.disablesw2hm == true
    end
    
    -- 沿直线激光路径生成月火
    local function SpawnBeamMoonfirePath(inst, target_pos, delay)
        if not inst or not inst:IsValid() or not target_pos then return end
        
        local ix, iy, iz = inst.Transform:GetWorldPosition()
        local target_step_num = math.ceil(BASE_NUM_STEPS * 2/5)
        
        local angle = math.atan2(iz - target_pos.z, ix - target_pos.x)
        local dist_sq = inst:GetDistanceSqToPoint(target_pos:Get())
        
        local gx, gz
        if dist_sq < 4 then
            -- 目标太近，使用最小距离
            gx = ix + (2 * math.cos(angle))
            gz = iz + (2 * math.sin(angle))
        else
            -- 正常情况
            gx = target_pos.x + (target_step_num * STEP * math.cos(angle))
            gz = target_pos.z + (target_step_num * STEP * math.sin(angle))
        end
        
        -- 沿着激光路径生成月火（与激光同步）
        for i = 0, BASE_NUM_STEPS do
            local fire_delay = delay + (math.max(0, i - 1) * FRAMES)
            local x = gx - i * STEP * math.cos(angle)
            local z = gz - i * STEP * math.sin(angle)
            
            inst:DoTaskInTime(fire_delay, function()
                if inst:IsValid() then
                    SpawnMoonfireAtPoint(x, z, inst)
                end
            end)
        end
    end
    
    -- 沿弧形激光路径生成月火
    local function SpawnSweepMoonfirePath(inst, target_pos, delay)
        if not inst or not inst:IsValid() then return end
        
        local ix, iy, iz = inst.Transform:GetWorldPosition()
        
        local angle, dist, angle_step_dir, x_dir
        
        if target_pos == nil then
            angle = DEGREES * (inst.Transform:GetRotation() + (SWEEP_ANGULAR_LENGTH/2))
            dist = BASE_SWEEP_DISTANCE
            x_dir = -1
            angle_step_dir = -1
        else
            angle = math.atan2(iz - target_pos.z, ix - target_pos.x) - (SWEEP_ANGULAR_LENGTH * DEGREES / 2)
            dist = math.max(math.sqrt(inst:GetDistanceSqToPoint(target_pos:Get())), MIN_SWEEP_DISTANCE)
            x_dir = 1
            angle_step_dir = 1
        end
        
        local num_angle_steps = BASE_NUM_STEPS + math.floor((math.abs(dist) - BASE_SWEEP_DISTANCE) / 2)
        local angle_step = (SWEEP_ANGULAR_LENGTH / num_angle_steps) * DEGREES
        
        local current_angle = angle
        for i = 0, num_angle_steps do
            local fire_delay = delay + (math.max(0, i - 1) * FRAMES)
            local x = ix - (x_dir * dist * math.cos(current_angle))
            local z = iz - dist * math.sin(current_angle)
            
            inst:DoTaskInTime(fire_delay, function()
                if inst:IsValid() then
                    SpawnMoonfireAtPoint(x, z, inst)
                end
            end)
            
            current_angle = current_angle + (angle_step_dir * angle_step)
        end
    end
    
    local function StartBeamMoonfireSystem(inst, target_pos)
        if not inst or not inst:IsValid() or not target_pos then return end
        if IsShadowEntity(inst) then return end
        
        local ipos = inst:GetPosition()
        local i_to_target = target_pos - ipos
        
        -- 计算三条路径的目标位置
        local paths = {target_pos}
        
        -- 旋转向量得到另外两条路径
        local cos_off = math.cos(TRIBEAM_ANGLEOFF)
        local sin_off = math.sin(TRIBEAM_ANGLEOFF)
        local cos_neg = math.cos(-TRIBEAM_ANGLEOFF)
        local sin_neg = math.sin(-TRIBEAM_ANGLEOFF)
        
        local offpos1 = Vector3(
            (i_to_target.x * cos_off - i_to_target.z * sin_off) + ipos.x,
            0,
            (i_to_target.x * sin_off + i_to_target.z * cos_off) + ipos.z
        )
        table.insert(paths, offpos1)
        
        local offpos2 = Vector3(
            (i_to_target.x * cos_neg - i_to_target.z * sin_neg) + ipos.x,
            0,
            (i_to_target.x * sin_neg + i_to_target.z * cos_neg) + ipos.z
        )
        table.insert(paths, offpos2)
        
        -- 第一波月火
        for _, path_target in ipairs(paths) do
            SpawnBeamMoonfirePath(inst, path_target, 0)
        end
        
        -- 第二波月火
        for _, path_target in ipairs(paths) do
            SpawnBeamMoonfirePath(inst, path_target, SECOND_BLAST_DELAY)
        end
    end
    
    -- sweep攻击
    local function StartSweepMoonfireSystem(inst, target_pos)
        if not inst or not inst:IsValid() then return end
        if IsShadowEntity(inst) then return end
        
        local paths = {target_pos}
        
        if target_pos ~= nil then
            local itot = target_pos - inst:GetPosition()
            if itot:LengthSq() > 0 then
                local itot_dir, itot_len = itot:GetNormalizedAndLength()
                table.insert(paths, target_pos + (itot_dir * 4.5))
                if itot_len > 4.75 then
                    table.insert(paths, target_pos - (itot_dir * 4.5))
                end
            end
        end
        
        for _, path_target in ipairs(paths) do
            SpawnSweepMoonfirePath(inst, path_target, 0)
        end
        
        for _, path_target in ipairs(paths) do
            SpawnSweepMoonfirePath(inst, path_target, SECOND_BLAST_DELAY)
        end
    end
    
    -- ----------------------------------------------------------------------------
    -- 激光假动作，35%概率假动作二次蓄力再发射
    local FEINT_CHANCE = 0.35       
    local FEINT_CHECK_FRAME = 30        
    
    local function set_lightvalues(inst, val)
        if inst.Light then
            inst.Light:SetIntensity(0.60 + (0.39 * val * val))
            inst.Light:SetRadius(5 * val)
            inst.Light:SetFalloff(0.85)
        end
    end
    
    local atk_beam_feint_state = State{
        name = "atk_beam_feint",
        tags = {"attacking", "busy", "canrotate"},
        
        onenter = function(inst, target)
            inst.Transform:SetEightFaced()
            inst.components.locomotor:StopMoving()
            
            inst.AnimState:PlayAnimation("attk_beam")
            
            inst.sg.statemem.target = target
            inst.sg.statemem.original_target = target  
            
            if target and target:IsValid() then
                inst:ForceFacePoint(target.Transform:GetWorldPosition())
            end
            
            inst.SoundEmitter:PlaySound("moonstorm/creatures/boss/alterguardian3/atk_beam")
        end,
        
        onupdate = function(inst)
            if inst.sg.statemem.target ~= nil and inst.sg.statemem.target:IsValid() then
                local x, _, z = inst.Transform:GetWorldPosition()
                local x1, y1, z1 = inst.sg.statemem.target.Transform:GetWorldPosition()
                local dx, dz = x1 - x, z1 - z
                if (dx * dx + dz * dz) < 256 and math.abs(anglediff(inst.Transform:GetRotation(), math.atan2(-dz, dx) / DEGREES)) < 45 then
                    inst:ForceFacePoint(x1, y1, z1)
                end
            end
        end,
        
        timeline = {
            TimeEvent(1*FRAMES, function(inst) set_lightvalues(inst, 0.9) end),
            TimeEvent(2*FRAMES, function(inst) set_lightvalues(inst, 0.875) end),
            TimeEvent(3*FRAMES, function(inst) set_lightvalues(inst, 0.85) end),
            TimeEvent(4*FRAMES, function(inst) set_lightvalues(inst, 0.825) end),
            TimeEvent(5*FRAMES, function(inst) set_lightvalues(inst, 0.8) end),
            TimeEvent(6*FRAMES, function(inst) set_lightvalues(inst, 0.775) end),
            TimeEvent(7*FRAMES, function(inst) set_lightvalues(inst, 0.75) end),
            TimeEvent(8*FRAMES, function(inst) set_lightvalues(inst, 0.725) end),
            TimeEvent(9*FRAMES, function(inst) set_lightvalues(inst, 0.7) end),
            TimeEvent(10*FRAMES, function(inst) set_lightvalues(inst, 0.675) end),
            TimeEvent(11*FRAMES, function(inst) set_lightvalues(inst, 0.65) end),
            TimeEvent(12*FRAMES, function(inst) set_lightvalues(inst, 0.625) end),
            TimeEvent(13*FRAMES, function(inst) set_lightvalues(inst, 0.6) end),
            TimeEvent(14*FRAMES, function(inst) set_lightvalues(inst, 0.575) end),
            TimeEvent(15*FRAMES, function(inst) set_lightvalues(inst, 0.55) end),
            TimeEvent(16*FRAMES, function(inst) set_lightvalues(inst, 0.525) end),
            TimeEvent(17*FRAMES, function(inst) set_lightvalues(inst, 0.5) end),
            -- 蓄力完成阶段
            TimeEvent(18*FRAMES, function(inst) set_lightvalues(inst, 0.6) end),
            TimeEvent(19*FRAMES, function(inst) set_lightvalues(inst, 0.7) end),
            TimeEvent(20*FRAMES, function(inst) set_lightvalues(inst, 0.8) end),
            TimeEvent(21*FRAMES, function(inst) set_lightvalues(inst, 0.9) end),
            TimeEvent(22*FRAMES, function(inst) set_lightvalues(inst, 0.92) end),
            TimeEvent(23*FRAMES, function(inst) set_lightvalues(inst, 0.94) end),
            TimeEvent(24*FRAMES, function(inst) set_lightvalues(inst, 0.95) end),
            TimeEvent(25*FRAMES, function(inst) set_lightvalues(inst, 0.96) end),
            TimeEvent(26*FRAMES, function(inst) set_lightvalues(inst, 0.97) end),
            TimeEvent(27*FRAMES, function(inst) set_lightvalues(inst, 0.98) end),
            TimeEvent(28*FRAMES, function(inst) set_lightvalues(inst, 0.99) end),
            TimeEvent(29*FRAMES, function(inst) set_lightvalues(inst, 1.0) end),
            
            TimeEvent(FEINT_CHECK_FRAME*FRAMES, function(inst)
                local target = inst.sg.statemem.original_target
                inst._from_feint = true
                inst.sg:GoToState("atk_beam", target)
            end),
        },
        
        onexit = function(inst)
            inst.Transform:SetSixFaced()
        end,
    }
    
    -- sweep 假动作蓄力状态
    local atk_sweep_feint_state = State{
        name = "atk_sweep_feint",
        tags = {"attacking", "busy", "canrotate"},
        
        onenter = function(inst, target)
            inst.Transform:SetFourFaced()
            inst.components.locomotor:StopMoving()
            
            inst.AnimState:PlayAnimation("attk_swipe")
            
            inst.sg.statemem.target = target
            inst.sg.statemem.original_target = target
            
            if target and target:IsValid() then
                inst:ForceFacePoint(target.Transform:GetWorldPosition())
            end
            
            inst.SoundEmitter:PlaySound("moonstorm/creatures/boss/alterguardian3/atk_beam")
        end,
        
        onupdate = function(inst)
            if inst.sg.statemem.target ~= nil and inst.sg.statemem.target:IsValid() then
                local x, _, z = inst.Transform:GetWorldPosition()
                local x1, y1, z1 = inst.sg.statemem.target.Transform:GetWorldPosition()
                local dx, dz = x1 - x, z1 - z
                if (dx * dx + dz * dz) < 256 and math.abs(anglediff(inst.Transform:GetRotation(), math.atan2(-dz, dx) / DEGREES)) < 45 then
                    inst:ForceFacePoint(x1, y1, z1)
                end
            end
        end,
        
        timeline = {
            -- 蓄力阶段的光线变化
            TimeEvent(1*FRAMES, function(inst) set_lightvalues(inst, 0.9) end),
            TimeEvent(2*FRAMES, function(inst) set_lightvalues(inst, 0.875) end),
            TimeEvent(3*FRAMES, function(inst) set_lightvalues(inst, 0.85) end),
            TimeEvent(4*FRAMES, function(inst) set_lightvalues(inst, 0.825) end),
            TimeEvent(5*FRAMES, function(inst) set_lightvalues(inst, 0.8) end),
            TimeEvent(6*FRAMES, function(inst) set_lightvalues(inst, 0.775) end),
            TimeEvent(7*FRAMES, function(inst) set_lightvalues(inst, 0.75) end),
            TimeEvent(8*FRAMES, function(inst) set_lightvalues(inst, 0.725) end),
            TimeEvent(9*FRAMES, function(inst) set_lightvalues(inst, 0.7) end),
            TimeEvent(10*FRAMES, function(inst) set_lightvalues(inst, 0.675) end),
            TimeEvent(11*FRAMES, function(inst) set_lightvalues(inst, 0.65) end),
            TimeEvent(12*FRAMES, function(inst) set_lightvalues(inst, 0.625) end),
            TimeEvent(13*FRAMES, function(inst) set_lightvalues(inst, 0.6) end),
            TimeEvent(14*FRAMES, function(inst) set_lightvalues(inst, 0.575) end),
            TimeEvent(15*FRAMES, function(inst) set_lightvalues(inst, 0.55) end),
            TimeEvent(16*FRAMES, function(inst) set_lightvalues(inst, 0.525) end),
            TimeEvent(17*FRAMES, function(inst) set_lightvalues(inst, 0.5) end),
            -- 蓄力完成阶段（模拟原版攻击前的光照变化）
            TimeEvent(18*FRAMES, function(inst) set_lightvalues(inst, 0.6) end),
            TimeEvent(19*FRAMES, function(inst) set_lightvalues(inst, 0.7) end),
            TimeEvent(20*FRAMES, function(inst) set_lightvalues(inst, 0.8) end),
            TimeEvent(21*FRAMES, function(inst) set_lightvalues(inst, 0.9) end),
            TimeEvent(22*FRAMES, function(inst) set_lightvalues(inst, 0.92) end),
            TimeEvent(23*FRAMES, function(inst) set_lightvalues(inst, 0.94) end),
            TimeEvent(24*FRAMES, function(inst) set_lightvalues(inst, 0.95) end),
            TimeEvent(25*FRAMES, function(inst) set_lightvalues(inst, 0.96) end),
            TimeEvent(26*FRAMES, function(inst) set_lightvalues(inst, 0.97) end),
            TimeEvent(27*FRAMES, function(inst) set_lightvalues(inst, 0.98) end),
            TimeEvent(28*FRAMES, function(inst) set_lightvalues(inst, 0.99) end),
            TimeEvent(29*FRAMES, function(inst) set_lightvalues(inst, 1.0) end),
            
            -- 结束蓄力，切换到真正的攻击状态（sweep在第37帧触发）
            TimeEvent(FEINT_CHECK_FRAME*FRAMES, function(inst)
                local target = inst.sg.statemem.original_target
                inst._from_feint = true
                inst.sg:GoToState("atk_sweep", target)
            end),
        },
        
        onexit = function(inst)
            inst.Transform:SetSixFaced()
        end,
    }
    
    -- 注册假动作状态
    sg.states["atk_beam_feint"] = atk_beam_feint_state
    sg.states["atk_sweep_feint"] = atk_sweep_feint_state
    
    -- ----------------------------------------------------------------------------

    -- beam 激光状态
    local OnEnterAtkBeam = sg.states.atk_beam.onenter
    sg.states.atk_beam.onenter = function(inst, target, ...)
        -- 分身不做假动作
        if IsShadowEntity(inst) then
            OnEnterAtkBeam(inst, target, ...)
            return
        end
        
        if inst._from_feint then
            inst._from_feint = nil
            OnEnterAtkBeam(inst, target, ...)
            
            -- 假动作后激光动作加速
            inst.AnimState:SetDeltaTimeMultiplier(1.4)
            inst._feint_speedup = true
            
            -- 生成分身
            if inst.sg.statemem.target then
                SetupPhase3LaserShadow(inst, inst.sg.statemem.target, "beam")
            end
            return
        end
        
        -- 35%概率进入假动作状态
        if math.random() < FEINT_CHANCE then
            inst.sg:GoToState("atk_beam_feint", target)
            return
        end
        
        -- 65%概率正常攻击
        OnEnterAtkBeam(inst, target, ...)
        
        if inst.sg.statemem.target then
            SetupPhase3LaserShadow(inst, inst.sg.statemem.target, "beam")
        end
    end
    
    -- beam 激光在35帧触发，我们在同一时机启动月火系统
    AddStateTimeEvent2hm(sg.states.atk_beam, BEAM_TRIGGER_FRAME * FRAMES, function(inst)
        if not IsShadowEntity(inst) then
            local target_pos = inst.sg.statemem.target_pos
            if target_pos == nil then
                local angle = inst.Transform:GetRotation() * DEGREES
                local ipos = inst:GetPosition()
                local OFFSET = 2 - STEP
                target_pos = ipos + Vector3(OFFSET * math.cos(angle), 0, -OFFSET * math.sin(angle))
            end
            
            StartBeamMoonfireSystem(inst, target_pos)
        end
    end)
    
    -- beam 激光状态退出
    local OriginalAtkBeamOnExit = sg.states.atk_beam.onexit
    sg.states.atk_beam.onexit = function(inst, ...)
        -- 恢复动画速度
        if inst._feint_speedup then
            inst.AnimState:SetDeltaTimeMultiplier(1)
            inst._feint_speedup = nil
        end
        if OriginalAtkBeamOnExit then
            OriginalAtkBeamOnExit(inst, ...)
        end
    end
    
    -- sweep 激光状态进入
    local OriginalAtkSweepOnEnter = sg.states.atk_sweep.onenter
    sg.states.atk_sweep.onenter = function(inst, target, ...)
        if IsShadowEntity(inst) then
            OriginalAtkSweepOnEnter(inst, target, ...)
            return
        end
        
        if inst._from_feint then
            inst._from_feint = nil
            OriginalAtkSweepOnEnter(inst, target, ...)
            
            -- 假动作后加速1.5倍
            inst.AnimState:SetDeltaTimeMultiplier(1.4)
            inst._feint_speedup = true
            
            if inst.sg.statemem.target then
                SetupPhase3LaserShadow(inst, inst.sg.statemem.target, "sweep")
            end
            return
        end
        
        if math.random() < FEINT_CHANCE then
            inst.sg:GoToState("atk_sweep_feint", target)
            return
        end
        
        OriginalAtkSweepOnEnter(inst, target, ...)
        
        if inst.sg.statemem.target then
            SetupPhase3LaserShadow(inst, inst.sg.statemem.target, "sweep")
        end
    end
    
    -- sweep 激光在37帧触发
    AddStateTimeEvent2hm(sg.states.atk_sweep, SWEEP_TRIGGER_FRAME * FRAMES, function(inst)
        if not IsShadowEntity(inst) then

            local target_pos = inst.sg.statemem.target_pos
            
            StartSweepMoonfireSystem(inst, target_pos)
        end
    end)
    
    -- sweep 激光状态清理
    local OriginalAtkSweepOnExit = sg.states.atk_sweep.onexit
    sg.states.atk_sweep.onexit = function(inst, ...)
        -- 恢复动画速度
        if inst._feint_speedup then
            inst.AnimState:SetDeltaTimeMultiplier(1)
            inst._feint_speedup = nil
        end
        if OriginalAtkSweepOnExit then
            OriginalAtkSweepOnExit(inst, ...)
        end
    end
    
    local OnEnterAtkSummonPre = sg.states.atk_summon_pre.onenter
    sg.states.atk_summon_pre.onenter = function(inst, ...)
        OnEnterAtkSummonPre(inst, ...)
        
        if inst.candeerice2hm then
            OnPhase3TrapProjectileRemove(inst)
        else
            inst.candeerice2hm = true
        end
    end

    local OnEnterAtkSummonLoop = sg.states.atk_summon_loop.onenter
    sg.states.atk_summon_loop.onenter = function(inst, ...)
        OnEnterAtkSummonLoop(inst, ...)
        -- 召唤虚影时间缩短
        local manager = inst._arena_manager or TheWorld.components.alterguardian_arena_manager2hm
        if manager and manager:IsInBattle() then
            local max_loops = 2
            if inst.sg.mem.summon_loops and inst.sg.mem.summon_loops >= max_loops then
                inst.sg.statemem.ready_to_finish = true
            end
        end
    end
    
    local OnExitAtkSummonPre = sg.states.atk_summon_pre.onexit
    sg.states.atk_summon_pre.onexit = function(inst, ...)
        if OnExitAtkSummonPre then
            OnExitAtkSummonPre(inst, ...)
        end
    end
    
    -- 陷阱攻击
    local OnEnterAtkTraps = sg.states.atk_traps.onenter
    sg.states.atk_traps.onenter = function(inst, ...)
        OnEnterAtkTraps(inst, ...)
    end
    
    -- 原版在44帧生成4个，54帧生成6个，现在改为44帧生成6个，54帧生成9个
    AddStateTimeEvent2hm(sg.states.atk_traps, 44 * FRAMES, function(inst)
        -- 额外生成2个陷阱
        if inst.DoTraps then
            inst:DoTraps(
                2,
                TUNING.ALTERGUARDIAN_PHASE3_TRAP_MINRANGE,
                TUNING.ALTERGUARDIAN_PHASE3_TRAP_MAXRANGE
            )
        end
    end)
    
    AddStateTimeEvent2hm(sg.states.atk_traps, 54 * FRAMES, function(inst)
        -- 额外生成3个陷阱
        if inst.DoTraps then
            inst:DoTraps(
                3,
                TUNING.ALTERGUARDIAN_PHASE3_TRAP_MINRANGE + 3.5,
                TUNING.ALTERGUARDIAN_PHASE3_TRAP_MAXRANGE + 3.5
            )
        end
    end)
    
    AddStateTimeEvent2hm(sg.states.atk_traps, 69 * FRAMES, function(inst)
        CreateAreaIceTiles(inst, true)
    end)
    
    local OnEnterAtkStab = sg.states.atk_stab.onenter
    sg.states.atk_stab.onenter = function(inst, ...)
        OnEnterAtkStab(inst, ...)
        if inst.candeerice2hm then
            inst.candeerice2hm = nil
            OnPhase3TrapProjectileRemove(inst)
        end
    end

    -- 原有的两种额外激光攻击移除了
end)

-- ============================================================================
-- 第四阶段：安逸休闲 + 秋季环境
-- ============================================================================

-- 第三阶段死亡工作完成
local function OnPhase3DeadWorkFinished(inst)
    if TUNING.alterguardianseason2hm > 0 then
        -- 强制设置为秋天
        if TheWorld.state.season ~= "autumn" then
            SetWorldSeason("autumn")
        end
        TheWorld:PushEvent("delayrefreshseason2hm")
    end
    TUNING.alterguardianseason2hm = 0
end

-- 第三阶段死亡天体球
AddPrefabPostInit("alterguardian_phase3deadorb", function(inst)
    if not TheWorld.ismastersim then
        return
    end
    
    AddMinimapIcon(inst)
    AddPrototyper(inst)
    inst:DoTaskInTime(0, AddSeasonLock, 4, true)
end)

-- 第三阶段死亡遗骸
AddPrefabPostInit("alterguardian_phase3dead", function(inst)
    if not TheWorld.ismastersim then
        return
    end
    
    AddMinimapIcon(inst)
    AddPrototyper(inst)
    inst:DoTaskInTime(0, AddSeasonLock, 4, true)
    
    if inst.components.workable then
        inst.components.workable:SetRequiresToughWork(true)
    end
    
    inst:ListenForEvent("onremove", OnPhase3DeadWorkFinished)
    
    -- 额外掉落
    if inst.components.lootdropper then
        local static_count = TUNING.moon_device_static_count2hm or 1
        static_count = math.max(1, math.min(3, static_count)) - 1
        
        -- 根据静电数量添加对应数量的启迪之冠
        if not TUNING.noalterguardianhat2hm then
            for i = 1, static_count do
                inst.components.lootdropper:AddChanceLoot("alterguardianhat", 1.00)
            end
        elseif TUNING.noalterguardianhat2hm then
            inst.components.lootdropper:AddChanceLoot("alterguardianhat", 1.00)
            inst.components.lootdropper:AddChanceLoot("alterguardianhat", 1.00)
        end
    end
end)



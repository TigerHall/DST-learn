--[[
    蟾蜍和苦难蟾蜍增强
    血量减半，召唤孢子帽速度翻倍，仇恨距离翻倍
    脱战后自动回血，孢子帽也提供回血，砍倒时扣血
    苦难蟾蜍蘑菇炸弹会弹射，召唤孢子帽时召唤蘑菇炸弹
    孢子炸弹和毒雾根据季节变化，会跟随玩家
    远离巢穴自动返回，并切换巢穴位置
    每个阶段均移动震地，转阶段震地次数增加
    毒菌蟾蜍额外掉落睡袋，毒雾持续时间减半
    召唤孢子帽由冷却时间触发改为每损失15%生命值触发
    召唤孢子帽结束时依次激活，需手持斧头砍伐
--]]

require "behaviours/doaction"
require "brains/toadstoolbrain"

-- ============================================================================
-- 定义全局变量
local lasttoadstool = nil
local _spawners = nil
local springauraexcludetags = nil
local userealspawnpoint = false

-- ============================================================================
-- 基础属性调整
-- 简单模式：血量减半
if TUNING.easymode2hm then
    TUNING.TOADSTOOL_HEALTH = TUNING.TOADSTOOL_HEALTH / 2
    TUNING.TOADSTOOL_DARK_HEALTH = TUNING.TOADSTOOL_DARK_HEALTH / 2
end

-- 仇恨和脱仇恨距离翻倍
TUNING.TOADSTOOL_AGGRO_DIST = TUNING.TOADSTOOL_AGGRO_DIST * 2
TUNING.TOADSTOOL_DEAGGRO_DIST = TUNING.TOADSTOOL_DEAGGRO_DIST * 2

-- 蘑菇树生长速度翻倍
TUNING.TOADSTOOL_MUSHROOMSPROUT_DURATION = TUNING.TOADSTOOL_MUSHROOMSPROUT_DURATION / 2
TUNING.TOADSTOOL_MUSHROOMSPROUT_TICK = TUNING.TOADSTOOL_MUSHROOMSPROUT_TICK / 2

-- 种树冷却设置为超长时间，禁用原版种树机制
TUNING.TOADSTOOL_MUSHROOMSPROUT_CD = 9999

-- 蘑菇树砍伐次数改为1次
TUNING.TOADSTOOL_MUSHROOMSPROUT_CHOPS = 1       -- 10→1
TUNING.TOADSTOOL_DARK_MUSHROOMSPROUT_CHOPS = 1  -- 14→1
-- ============================================================================
-- 脱战回血
local function onremove(inst)
    if lasttoadstool == inst then
        lasttoadstool = nil
    end
    
    if inst._tree_regen_task_2hm then
        inst._tree_regen_task_2hm:Cancel()
        inst._tree_regen_task_2hm = nil
    end
    
    -- 清理待激活队列中的树（_links中的树会被原版机制自动清理）
    if inst._pending_trees_2hm then
        for i, tree in ipairs(inst._pending_trees_2hm) do
            if tree and tree:IsValid() and tree.components.workable then
                tree.components.workable:Destroy(tree)
            end
        end
        inst._pending_trees_2hm = {}
    end
end

local function onlosttarget(inst)
    if inst.components.health and not inst.components.health:IsDead() and inst.components.timer then
        if inst.components.health:GetPercent() >= 1 then
            -- 满血逃跑
            inst:PushEvent("flee")
        else
            -- 未满血回血，参考疯猪
            inst.components.health:StartRegen(
                TUNING.DAYWALKER_COMBAT_STALKING_HEALTH_REGEN,
                TUNING.DAYWALKER_COMBAT_HEALTH_REGEN_PERIOD,
                false
            )
        end
    end
end

-- 获得新目标时停止回血
local function onnewcombattarget(inst, data)
    if inst.components.health and not inst.components.health:IsDead() and 
       data and data.oldtarget == nil then
        inst.components.health:StopRegen()
    end
end

-- 苦难蟾蜍弹射蘑菇炸弹
local function bouncethrow2hmfn(self, inst)
    local toadstool = inst.components.entitytracker and inst.components.entitytracker:GetEntity("toadstool")
    
    if inst.components.complexprojectile and toadstool ~= nil and toadstool:IsValid() then
        -- 生成新的蘑菇炸弹投射物
        local newproj = SpawnPrefab("mushroombomb_projectile")
        newproj.components.entitytracker:TrackEntity("toadstool", toadstool)
        newproj.components.complexprojectile:SetHorizontalSpeed(inst.components.complexprojectile.horizontalSpeed)
        return newproj
    end
end

-- ============================================================================
-- 孢子炸弹季节效果，孢子帽顶炸弹特殊处理
AddPrefabPostInit("sporebomb", function(inst)
    if not TheWorld.ismastersim then return end
    
    inst:DoTaskInTime(0, function()

        if inst._treetop_mode_2hm then
            inst.AnimState:SetScale(1.5, 1.5, 1.5)
            
            local original_detach = inst.components.debuff.detachedfn
            
            inst.components.debuff.detachedfn = function(bomb, target)
                if bomb._exploded_2hm then return end
                bomb._exploded_2hm = true
                
                local x, y, z = bomb.Transform:GetWorldPosition()
                
                local cloud = SpawnPrefab("sporecloud")
                if cloud then
                    cloud.Transform:SetPosition(x, 0, z)
                    cloud:FadeInImmediately()
                    cloud._treetop_mode_2hm = true
                    
                    cloud:DoTaskInTime(0, function()
                        if cloud.components.timer then
                            if cloud.components.timer:TimerExists("disperse") then
                                cloud.components.timer:StopTimer("disperse")
                            end
                            cloud.components.timer:StartTimer("disperse", 5)
                        end
                    end)
                end
                
                if bomb._tree_2hm and bomb._tree_2hm:IsValid() then
                    bomb._tree_2hm:PushEvent("treetopbomb_exploded_2hm", {
                        bomb = bomb, 
                        tree_chopped = bomb._tree_chopped_2hm
                    })
                end
                
                bomb:Remove()
            end
            
            inst:ListenForEvent("timerdone", function(bomb, data)
                if data.name == "explode" then
                    if bomb.components.debuff and bomb.components.debuff.detachedfn then
                        bomb.components.debuff.detachedfn(bomb, nil)
                    else
                        bomb:Remove()
                    end
                end
            end)
            
            return
        end
        
        -- 季节效果
        if lasttoadstool and lasttoadstool:IsValid() then
            local color
            local season = TheWorld.state.season
            
            if season == "winter" then
                -- 冬季蓝色降温
                if not inst.components.heater then
                    inst:AddComponent("heater")
                    inst.components.heater.heat = -20
                    inst.components.heater:SetThermics(false, true)
                end
                color = "blue"
            
            elseif season == "summer" then
                -- 夏季橙色升温
                if not inst.components.heater then
                    inst:AddComponent("heater")
                    inst.components.heater.heat = 90
                    inst.components.heater:SetThermics(true, false)
                end
                color = "orange"
            
            elseif season == "spring" then
                -- 春季绿色带电
                SpawnPrefab("electricchargedfx"):SetTarget(inst)
                color = "green"
                
            else
                -- 默认秋季催眠
                color = "yellow"
            end
            
            SetAnimColor2hm(inst, color)
        end
    end)
end)

-- ============================================================================
-- 毒雾对目标应用季节效果
local function sporecloudseasontarget(inst, target, force)
    if IsEntityDeadOrGhost(target) then return end
    
    if inst.season2hm == "winter" then
        -- 冬季效果：冰冻和降温
        if target.components.freezable and not target.components.freezable:IsFrozen() then
            local hasfx = false
            
            -- 初次冰冻时生成特效
            if target.components.freezable.coldness <= 0 then
                hasfx = true
                target.components.freezable:SpawnShatterFX()
            end
            
            -- 增加寒冷度
            target.components.freezable:AddColdness(0.5)
            
            -- 冰冻成功后补充特效
            if not hasfx and target.components.freezable:IsFrozen() then
                target.components.freezable:SpawnShatterFX()
            end
        end
        
        -- 降低温度
        if target.components.temperature and target.components.temperature.current > 0 then
            target.components.temperature:DoDelta(-10)
        end
        
    elseif inst.season2hm == "summer" then
        -- 夏季效果：燃烧和升温
        if target.components.temperature and target.components.temperature.current < 70 then
            target.components.temperature:DoDelta(10)
        end
        
        if target.components.burnable and not target.components.burnable:IsBurning() then
            if not target.components.burnable:IsSmoldering() then
                target.components.burnable:StartWildfire()
            else
                target.components.burnable:Ignite(true, inst)
            end
        end
        
    elseif inst.season2hm == "spring" then
        -- 春季效果：潮湿和电击
        if target.components.moisture then
            local delta = TUNING.moisturerate2hm and 0.5 or 2
            target.components.moisture:DoDelta(delta)
        end
        
        -- force参数为true时造成电击伤害
        if force and target.components.combat then
            local IsInsulated = target:HasTag("electricdamageimmune") or 
                              (target.components.inventory ~= nil and target.components.inventory:IsInsulated())
            
            -- 未绝缘时生成电击特效
            if not IsInsulated then
                SpawnPrefab("electrichitsparks"):AlignToTarget(target, inst, true)
            end
            
            -- 计算电击伤害（潮湿时伤害更高）
            local moisturepercent = target.components.moisture ~= nil and target.components.moisture:GetMoisturePercent() or
                                  (target:GetIsWet() and 1 or 0)
            local damage_mult = IsInsulated and 1 or (TUNING.ELECTRIC_DAMAGE_MULT + moisturepercent)
            local damage = TUNING.TOADSTOOL_SPORECLOUD_DAMAGE * damage_mult
            
            target.components.combat:GetAttacked(inst, damage, nil, not IsInsulated and "electric" or nil)
        end
        
    else
        -- 秋季效果：催眠
        if not (target.sg ~= nil and target.sg:HasStateTag("waking")) then
            -- 对坐骑施加睡眠效果
            local mount = target.components.rider ~= nil and target.components.rider:GetMount() or nil
            if mount ~= nil then
                mount:PushEvent("ridersleep", {sleepiness = 4, sleeptime = 6})
            end
            
            -- 对玩家施加眩晕或睡眠
            if target.components.grogginess ~= nil then
                if not (target.sg ~= nil and target.sg:HasStateTag("knockout")) then
                    target.components.grogginess:AddGrogginess(1, 6)
                end
            elseif target.components.sleeper ~= nil then
                if not (target.sg ~= nil and target.sg:HasStateTag("sleeping")) then
                    target.components.sleeper:AddSleepiness(1, 6)
                end
            end
        end
    end
end

-- 毒雾击中非玩家实体时触发
local function onsporecloudhitother(inst, data)
    if lasttoadstool and lasttoadstool:IsValid() and 
       inst:IsNear(lasttoadstool, 40) and 
       data.target and not data.target:HasTag("player") and 
       inst.persists then
        sporecloudseasontarget(inst, data.target)
    end
end

-- 毒雾追踪蟾蜍或其目标
local function checklasttoadstool(inst)
    if not (lasttoadstool and lasttoadstool:IsValid() and inst.persists) then
        -- 蟾蜍已死亡或无效，停止追踪
        if inst.lasttoadstooltask2hm then
            inst.lasttoadstooltask2hm:Cancel()
            inst.lasttoadstooltask2hm = nil
        end
        return
    end
    
    -- 确定追踪目标（优先追踪蟾蜍的战斗目标）
    local target = lasttoadstool
    if lasttoadstool.components.combat and lasttoadstool.components.combat.target then
        target = lasttoadstool.components.combat.target
    end
    
    -- 计算距离并移动
    local x, y, z = target.Transform:GetWorldPosition()
    local distsq = inst:GetDistanceSqToPoint(x, y, z)
    
    -- 保持适当距离（36-1600单位²之间）
    local min_dist = (target == lasttoadstool) and 36 or 4
    if distsq < 1600 and distsq > min_dist then
        local angle = inst:GetAngleToPoint(x, y, z) * DEGREES
        local _x, _y, _z = inst.Transform:GetWorldPosition()
        inst.Transform:SetPosition(
            _x + FRAMES * math.cos(angle), 
            _y, 
            _z - FRAMES * math.sin(angle)
        )
    end
    
    -- 定期对玩家施加季节效果
    inst.idx2hm = inst.idx2hm + 1
    local idx10 = inst.idx2hm >= (inst.nodark2hm and 10 or 30)
    local isspring = inst.season2hm == "spring"
    
    if idx10 or isspring then
        if idx10 then
            inst.idx2hm = 0
            if isspring then
                SpawnPrefab("electricchargedfx"):SetTarget(inst)
            end
        end
        
        -- 对范围内玩家施加效果
        for _, player in ipairs(AllPlayers) do
            if player and player:IsValid() and 
               player:IsNear(inst, TUNING.TOADSTOOL_SPORECLOUD_RADIUS) then
                sporecloudseasontarget(inst, player, idx10)
            end
        end
    end
end
local function processsporecloud(inst)
    if not (lasttoadstool and lasttoadstool:IsValid() and inst.persists) then
        return
    end
    
    if inst._treetop_mode_2hm then
        return
    end
    
    -- 注册击中事件
    inst:ListenForEvent("onhitother", onsporecloudhitother)
    
    -- 根据当前季节设置效果
    inst.season2hm = TheWorld.state.season
    local color
    
    if inst.season2hm == "winter" then
        -- 冬季：降温
        if not inst.components.heater then
            inst:AddComponent("heater")
            inst.components.heater.heat = -20
            inst.components.heater:SetThermics(false, true)
        end
        color = "blue"
        
    elseif inst.season2hm == "summer" then
        -- 夏季：升温
        if not inst.components.heater then
            inst:AddComponent("heater")
            inst.components.heater.heat = 90
            inst.components.heater:SetThermics(true, false)
        end
        color = "orange"
        
    elseif inst.season2hm == "spring" then
        -- 春季：带电（光环不影响玩家）
        inst:AddDebuff("buff_electricattack", "buff_electricattack")
        
        if inst.components.aura and inst.components.aura.auraexcludetags then
            if not springauraexcludetags then
                springauraexcludetags = deepcopy(inst.components.aura.auraexcludetags)
                table.insert(springauraexcludetags, "player")
            end
            inst.components.aura.auraexcludetags = springauraexcludetags
        end
        color = "green"
        
    else
        -- 秋季：催眠
        color = "yellow"
    end
    
    -- 设置毒雾颜色
    SetAnimColor2hm(inst, color)
    
    -- 为毒雾的覆盖特效设置颜色
    if inst._overlayfx then
        for _, fx in ipairs(inst._overlayfx) do
            if fx and fx:IsValid() then
                SetAnimColor2hm(fx, color)
            end
        end
    end
    
    -- 设置颜色
    if inst._overlaytasks then
        for k, v in pairs(inst._overlaytasks) do
            if v and v.fn then
                local fn = v.fn
                v.fn = function(...)
                    fn(...)
                    local fx = inst._overlayfx and inst._overlayfx[#inst._overlayfx]
                    if fx and fx:IsValid() then
                        SetAnimColor2hm(fx, color)
                    end
                end
            end
        end
    end
    
    -- 设置追踪参数
    inst.nodark2hm = (lasttoadstool.prefab == "toadstool")  -- 是否为普通蟾蜍
    inst.idx2hm = inst.nodark2hm and 5 or 15                -- 初始计数器
    
    -- 普通蟾蜍的毒雾存在时间减半（30秒），苦难蟾蜍保持60秒
    if inst.components.timer and inst.components.timer:TimerExists("disperse") then
        if inst.nodark2hm then
            -- 普通蟾蜍：将剩余时间设置为30秒
            inst.components.timer:SetTimeLeft("disperse", 30)
        end
    end
    

    inst.lasttoadstooltask2hm = inst:DoPeriodicTask(3 * FRAMES, checklasttoadstool)
end

-- 应用毒雾增强
AddPrefabPostInit("sporecloud", function(inst)
    if not TheWorld.ismastersim then return end
    inst:DoTaskInTime(0, processsporecloud)
end)

-- ============================================================================
-- 远离巢穴时遁地返回，回复少量生命值
AddStategraphState("SGtoadstool", State {
    name = "burrow2hm",
    tags = {"busy", "nosleep", "nofreeze", "noattack", "temp_invincible"},
    
    onenter = function(inst)
        -- 满血状态使用原版逃跑
        if inst.components.health and inst.components.health:GetPercent() >= 1 then
            inst.sg:GoToState("burrow")
            return
        end
        
        -- 进入遁地状态
        inst.components.locomotor:StopMoving()
        inst:ClearBufferedAction()
        inst.AnimState:PlayAnimation("reset")
    end,
    
    timeline = {
        TimeEvent(11 * FRAMES, function(inst)
            inst.SoundEmitter:PlaySound("dontstarve/creatures/together/toad_stool/roar")
        end),
        
        TimeEvent(19 * FRAMES, function(inst)
            inst.DynamicShadow:Enable(false)
        end),
        
        TimeEvent(20 * FRAMES, function(inst)
            inst.SoundEmitter:PlaySound("dontstarve/creatures/together/toad_stool/spawn_appear")
        end),
        
        TimeEvent(21 * FRAMES, function(inst)
            -- 开始震动
            ShakeAllCameras(CAMERASHAKE.VERTICAL, 20 * FRAMES, .03, 2, inst, 40)
        end),
        
        TimeEvent(40 * FRAMES, function(inst)
            -- 持续震动
            ShakeAllCameras(CAMERASHAKE.VERTICAL, 30 * FRAMES, .03, .7, inst, 40)
        end),
        
        TimeEvent(48 * FRAMES, function(inst)
            -- 传送回出生点并回复生命值
            userealspawnpoint = true
            local pt = inst.components.knownlocations:GetLocation("spawnpoint")
            userealspawnpoint = nil
            
            if pt then
                inst.Transform:SetPosition(pt.x, 0, pt.z)
                -- 回复1%生命值
                inst.components.health:DoDelta(inst.components.health.maxhealth * 0.01, nil, nil, true)
                inst.sg:GoToState("surface")
            else
                inst:OnEscaped()
            end
        end)
    },
    
    events = {
        EventHandler("animover", function(inst)
            if inst.AnimState:AnimDone() then
                -- 动画结束时传送回出生点并回复生命值
                userealspawnpoint = true
                local pt = inst.components.knownlocations:GetLocation("spawnpoint")
                userealspawnpoint = nil
                
                if pt then
                    inst.Transform:SetPosition(pt.x, 0, pt.z)
                    -- 回复10%生命值
                    inst.components.health:DoDelta(inst.components.health.maxhealth * 0.1, nil, nil, true)
                    inst.sg:GoToState("surface")
                else
                    inst:OnEscaped()
                end
            end
        end)
    },
    
    onexit = function(inst)
        inst.DynamicShadow:Enable(true)
    end
})

AddStategraphActionHandler("SGtoadstool", ActionHandler(ACTIONS.ACTION2HM, "burrow2hm"))

local function GoHomeAction(inst)
    if inst.sg:HasStateTag("busy") or inst:HasTag("swc2hm") then
        return
    end
    
    userealspawnpoint = true
    local pt = inst.components.knownlocations:GetLocation("spawnpoint")
    userealspawnpoint = nil
    
    -- 超过25单位时返回
    if pt and inst:GetDistanceSqToPoint(pt:Get()) >= 625 then
        return BufferedAction(inst, nil, ACTIONS.ACTION2HM)
    end
end

AddBrainPostInit("toadstoolbrain", function(self)
    if self.bt and self.bt.root and self.bt.root.children then
        local children = self.bt.root.children
        
        -- 在最高优先级插入返回巢穴行为
        table.insert(children, 1, DoAction(self.inst, GoHomeAction))
    end
end)

-- ============================================================================
-- 回巢重生交换位置
local function exchangetoadstoolcap(inst)
    if not _spawners or #_spawners <= 0 then
        return
    end
    
    local length = #_spawners
    
    for i = 1, length, 1 do
        local spawner = _spawners[math.random(length)]
        
        if spawner ~= nil and spawner ~= inst and spawner:IsValid() then
            local x, y, z = inst.Transform:GetWorldPosition()
            inst.Transform:SetPosition(spawner.Transform:GetWorldPosition())
            spawner.Transform:SetPosition(x, y, z)
            break
        end
    end
end

local function capontimerdone(inst, data)
    if data.name == "respawn" or data.name == "respawndark" then
        inst:DoTaskInTime(0, exchangetoadstoolcap)
    end
end

AddPrefabPostInit("toadstool_cap", function(inst)
    if not TheWorld.ismastersim then return end
    
    -- 缓存蟾蜍生成点用于传送
    if _spawners == nil and TheWorld.components.toadstoolspawner ~= nil then
        local GetSpawnedToadstool = getupvalue2hm(
            TheWorld.components.toadstoolspawner.OnPostInit, 
            "GetSpawnedToadstool"
        )
        
        if GetSpawnedToadstool ~= nil then
            _spawners = getupvalue2hm(GetSpawnedToadstool, "_spawners")
        end
    end

    if _spawners ~= nil then
        inst:ListenForEvent("timerdone", capontimerdone)
    end
end)

-- ============================================================================
-- 移除蛤蟆蹲的阶段限制
local function EnablePoundAllPhases(inst)
    if not (TheWorld.ismastersim and inst.components.timer) then return end
    
    inst:DoTaskInTime(0, function()
        -- 转阶段恢复被暂停的震地CD
        inst:ListenForEvent("roar", function(inst)
            if inst.components.timer then
                inst:DoTaskInTime(0, function()
                    if inst.components.timer:TimerExists("pound_cd") and 
                       inst.components.timer:IsPaused("pound_cd") then
                        inst.components.timer:ResumeTimer("pound_cd")
                    elseif not inst.components.timer:TimerExists("pound_cd") then
                        inst.components.timer:StartTimer("pound_cd", 1)
                    end
                end)
            end
        end)
        
        -- 战斗开始恢复
        inst:ListenForEvent("newcombattarget", function(inst, data)
            if data and data.oldtarget == nil and inst.components.timer then
                inst:DoTaskInTime(0, function()
                    if inst.components.timer:IsPaused("pound_cd") then
                        inst.components.timer:ResumeTimer("pound_cd")
                    elseif not inst.components.timer:TimerExists("pound_cd") then
                        inst.components.timer:StartTimer("pound_cd", 0.1)
                    end
                end)
            end
        end)
    end)
end

AddPrefabPostInit("toadstool", EnablePoundAllPhases)
AddPrefabPostInit("toadstool_dark", EnablePoundAllPhases)

local function BounceStuff_2hm(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 6, {"_inventoryitem"}, {"locomotor", "INLIMBO"})
    for _, v in ipairs(ents) do
        if v:IsValid() and v.Physics and v.Physics:IsActive() then
            local hp = v:GetPosition()
            local vel = (hp - inst:GetPosition()):GetNormalized()
            local speed = 4 + math.random() * 2
            local angle = math.atan2(vel.z, vel.x) + (math.random() * 20 - 10) * DEGREES
            v.Physics:Teleport(hp.x, .1, hp.z)
            v.Physics:SetVel(math.cos(angle) * speed, 1.5 * speed + math.random(), math.sin(angle) * speed)
        end
    end
end

local function DoPoundShake_2hm(inst)
    ShakeAllCameras(CAMERASHAKE.VERTICAL, .35, .02, 1, inst, 40)
    BounceStuff_2hm(inst)
end

AddStategraphState("SGtoadstool", State{
    name = "pound_pre_noquake_2hm",
    tags = {"attack", "busy", "pounding", "nosleep", "nofreeze", "noelectrocute"},

    onenter = function(inst)
        inst.components.locomotor:StopMoving()
        inst.AnimState:PlayAnimation("attack_pound_pre")
        
        inst.pound_speed = math.min(6, inst.pound_speed + 1)
        local cooldown = inst.pound_cd * (1 - inst.pound_speed / 12)
        inst.components.timer:StartTimer("pound_cd", cooldown)
        
        if inst.components.combat and inst.components.combat.target then
            local target = inst.components.combat.target
            if target:IsValid() then
                inst.pound_target_2hm = target
                inst.pound_speed_2hm = 1 + (inst._numlinks or 0) * 0.1
            end
        end
    end,

    onupdate = function(inst, dt)
        if inst.pound_target_2hm and inst.pound_target_2hm:IsValid() then
            local target = inst.pound_target_2hm
            local x, y, z = target.Transform:GetWorldPosition()
            local inst_x, inst_y, inst_z = inst.Transform:GetWorldPosition()
            local dx, dz = x - inst_x, z - inst_z
            local dist = math.sqrt(dx * dx + dz * dz)
            
            if dist > 1 then
                local move_dist = (inst.pound_speed_2hm or 1) * 2 * dt
                if move_dist < dist then
                    inst.Transform:SetPosition(
                        inst_x + (dx / dist) * move_dist,
                        inst_y,
                        inst_z + (dz / dist) * move_dist
                    )
                end
            end
        end
    end,

    timeline = {
        TimeEvent(11 * FRAMES, function(inst)
            inst.SoundEmitter:PlaySound("dontstarve/creatures/together/toad_stool/roar")
        end),
        FrameEvent(36, function(inst)
            DoPoundShake_2hm(inst)
            inst.components.groundpounder:GroundPound()
            inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/bearger/groundpound")
        end),
    },

    events = {
        EventHandler("animover", function(inst)
            if inst.AnimState:AnimDone() then
                if inst.pound_jumps_remaining_2hm and inst.pound_jumps_remaining_2hm >= 0 then
                    inst.sg:GoToState("pound_loop_noquake_2hm")
                else
                    inst.sg:GoToState("pound_loop_quake_2hm")
                end
            end
        end),
    },
})

AddStategraphState("SGtoadstool", State{
    name = "pound_loop_noquake_2hm",
    tags = {"attack", "busy", "pounding", "nosleep", "nofreeze", "noelectrocute"},

    onenter = function(inst)
        inst.AnimState:PlayAnimation("attack_pound_loop")
    end,

    onupdate = function(inst, dt)
        if inst.pound_target_2hm and inst.pound_target_2hm:IsValid() then
            local target = inst.pound_target_2hm
            local x, y, z = target.Transform:GetWorldPosition()
            local inst_x, inst_y, inst_z = inst.Transform:GetWorldPosition()
            local dx, dz = x - inst_x, z - inst_z
            local dist = math.sqrt(dx * dx + dz * dz)
            
            if dist > 1 then
                local move_dist = (inst.pound_speed_2hm or 1) * 2 * dt
                if move_dist < dist then
                    inst.Transform:SetPosition(
                        inst_x + (dx / dist) * move_dist,
                        inst_y,
                        inst_z + (dz / dist) * move_dist
                    )
                end
            end
        end
    end,

    timeline = {
        FrameEvent(7, function(inst)
            DoPoundShake_2hm(inst)
            inst.components.groundpounder:GroundPound()
            inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/bearger/groundpound")
        end),
    },

    events = {
        EventHandler("animover", function(inst)
            if inst.AnimState:AnimDone() then
                if inst.pound_jumps_remaining_2hm and inst.pound_jumps_remaining_2hm > 0 then
                    inst.pound_jumps_remaining_2hm = inst.pound_jumps_remaining_2hm - 1
                    inst.sg:GoToState("pound_loop_noquake_2hm")
                else
                    inst.sg:GoToState("pound_loop_quake_2hm")
                end
            end
        end),
    },
})

AddStategraphState("SGtoadstool", State{
    name = "pound_loop_quake_2hm",
    tags = {"attack", "busy", "pounding", "nosleep", "nofreeze", "noelectrocute"},

    onenter = function(inst)
        inst.AnimState:PlayAnimation("attack_pound_loop")
    end,

    onupdate = function(inst, dt)
        if inst.pound_target_2hm and inst.pound_target_2hm:IsValid() then
            local target = inst.pound_target_2hm
            local x, y, z = target.Transform:GetWorldPosition()
            local inst_x, inst_y, inst_z = inst.Transform:GetWorldPosition()
            local dx, dz = x - inst_x, z - inst_z
            local dist = math.sqrt(dx * dx + dz * dz)
            
            if dist > 1 then
                local move_dist = (inst.pound_speed_2hm or 1) * 2 * dt
                if move_dist < dist then
                    inst.Transform:SetPosition(
                        inst_x + (dx / dist) * move_dist,
                        inst_y,
                        inst_z + (dz / dist) * move_dist
                    )
                end
            end
        end
    end,

    timeline = {
        FrameEvent(7, function(inst)
            inst.components.groundpounder:GroundPound()
            BounceStuff_2hm(inst)
            inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/bearger/groundpound")
            

            local jump_count = (inst.pound_total_jumps_2hm or 2)
            local debris_num = 20 + (jump_count - 2) * 10  
            local quake_duration = 2.5 + (jump_count - 2) * 1.25  
            TheWorld:PushEvent("ms_miniquake", {rad = 20, num = debris_num, duration = quake_duration, target = inst})
        end),
    },

    events = {
        EventHandler("animover", function(inst)
            if inst.AnimState:AnimDone() then
                inst.sg:GoToState("pound_pst")
            end
        end),
    },
})

AddStategraphPostInit("SGtoadstool", function(sg)
    if not (sg.states and sg.states.pound_pre) then return end
    
    local old_onenter = sg.states.pound_pre.onenter
    sg.states.pound_pre.onenter = function(inst)
        local hp_percent = inst.components.health:GetPercent()
        local is_dark = inst.prefab == "toadstool_dark"
        local jump_count = 1
        
        if is_dark then
            if hp_percent > 0.7 then
                jump_count = 2
            elseif hp_percent > 0.4 then
                jump_count = 3
            elseif hp_percent > 0.2 then
                jump_count = 4
            else
                jump_count = 5
            end
        else
            if hp_percent > 0.7 then
                jump_count = 2
            elseif hp_percent > 0.4 then
                jump_count = 3
            else
                jump_count = 4
            end
        end
        
        inst.pound_total_jumps_2hm = jump_count
        inst.pound_jumps_remaining_2hm = jump_count - 3
        inst.sg:GoToState("pound_pre_noquake_2hm")
    end
end)

-- ============================================================================
-- 监听种树开始和结束
AddStategraphPostInit("SGtoadstool", function(sg)
    if not sg.states.channel then return end
    
    local old_onenter = sg.states.channel.onenter
    sg.states.channel.onenter = function(inst, ...)
        inst:PushEvent("startchannel")
        return old_onenter(inst, ...)
    end
    
    if not sg.states.channel_pst then return end
    
    local old_pst_onenter = sg.states.channel_pst.onenter
    sg.states.channel_pst.onenter = function(inst, ...)
        inst:PushEvent("stopchannel")
        return old_pst_onenter(inst, ...)
    end
end)

-- 伤害累计触发种树
local function doDamageDeltaList(inst, delta, afflicter)
    if not (inst.damage_accumulate_2hm and inst.components.health) then
        return
    end
    
    -- 累计所有来源的伤害
    inst.damage_accumulate_2hm.totalDelta = inst.damage_accumulate_2hm.totalDelta + delta
    
    local threshold = inst.components.health.maxhealth * 0.15
    
    if inst.damage_accumulate_2hm.totalDelta >= threshold then
        inst.damage_accumulate_2hm.totalDelta = 0
        
        if inst.sg and not inst.sg:HasStateTag("busy") then
            inst.sg:GoToState("channel_pre")
        else
            inst.sg.mem.wantstochannel = true
        end
    end
end

-- 初始化伤害累计系统
local function InitDamageAccumulate(inst)
    inst.damage_accumulate_2hm = {
        totalDelta = 0
    }
    
    if inst.components.health then
        local oldSetVal = inst.components.health.SetVal
        inst.components.health.SetVal = function(self, val, cause, afflicter)
            local delta = self.currenthealth - val
            if delta > 0 then
                doDamageDeltaList(inst, delta, afflicter)
            end
            return oldSetVal(self, val, cause, afflicter)
        end
    end
end

-- 蘑菇树只能由玩家手持斧子砍伐已激活状态的
local function SetupMushroomSproutWorkable(inst)
    if not inst.components.workable then 
        return 
    end
    
    inst._should_shake_2hm = false
    
    inst.components.workable:SetShouldRecoilFn(function(tree, worker, tool, numworks)   -- 返回值：(是否击退, 实际消耗的工作量)
        local toadstool_alive = false
        if tree._link and tree._link:IsValid() and tree._link.components.health and not tree._link.components.health:IsDead() then
            toadstool_alive = true
        end
        -- 如果蟾蜍已死亡或消失，则允许任意方式砍倒树
        if not toadstool_alive then
            return false, numworks
        end
        
        -- 非玩家不击退，不消耗工作量
        if not (worker and worker:HasTag("player")) then
            return false, 0
        end
        
        -- 检查玩家装备栏是否手持斧头（不判断tool参数确保手持）
        local is_axe = false
        if worker.components.inventory then
            local equipped = worker.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            if equipped then
                is_axe = equipped:HasTag("axe") or 
                         (equipped.components.tool and equipped.components.tool:CanDoAction(ACTIONS.CHOP))
            end
        end
        
        -- 未手持斧头
        if not is_axe then
            worker:DoTaskInTime(0.01, function()
                if worker and worker:IsValid() and worker.components.talker then
                    worker.components.talker:Say(TUNING.isch2hm and "I have to do it myself!" or "我只能亲自来！")
                end
            end)
            return true, 0
        end
        
        -- 未激活
        if not tree._should_shake_2hm then
            worker:DoTaskInTime(0.01, function()
                if worker and worker:IsValid() and worker.components.talker then
                    worker.components.talker:Say(TUNING.isch2hm and "Not yet." or "现在还不行！")
                end
            end)
            return true, 0
        end
        
        -- 树已激活且手持斧头：允许砍伐，不击退，消耗正常工作量
        return false, numworks
    end)
    
    local old_onfinish = inst.components.workable.onfinish
    inst.components.workable:SetOnFinishCallback(function(tree, worker)
        if tree._link and tree._link:IsValid() then
            tree._link:PushEvent("mushroomchopped_2hm", {tree = tree})
        end
        
        if old_onfinish then
            old_onfinish(tree, worker)
        end
    end)
end

-- 应用到普通和暗黑蘑菇树
AddPrefabPostInit("mushroomsprout", function(inst)
    if not TheWorld.ismastersim then return end
    
    inst:DoTaskInTime(0, function()
        SetupMushroomSproutWorkable(inst)
        
        if not inst._link or not inst._link:IsValid() then
            inst._should_shake_2hm = true
        end
    end)
    
    inst:ListenForEvent("treetopbomb_exploded_2hm", function(tree, data)
        if data and tree._link and tree._link:IsValid() then
            if not data.tree_chopped then
                tree._link:PushEvent("tree_auto_switch_2hm", {tree = tree})
            end
        end
    end)
end)

AddPrefabPostInit("mushroomsprout_dark", function(inst)
    if not TheWorld.ismastersim then return end
    
    inst:DoTaskInTime(0, function()
        SetupMushroomSproutWorkable(inst)
        
        if not inst._link or not inst._link:IsValid() then
            inst._should_shake_2hm = true
        end
    end)
    
    inst:ListenForEvent("treetopbomb_exploded_2hm", function(tree, data)
        if data and tree._link and tree._link:IsValid() then
            if not data.tree_chopped then
                tree._link:PushEvent("tree_auto_switch_2hm", {tree = tree})
            end
        end
    end)
end)

local function SetupToadstoolTreeManagement(inst, is_dark)

    inst._pending_trees_2hm = {}       
    inst._active_tree_2hm = nil         
    inst._planting_2hm = false
    inst._is_dark_2hm = is_dark
    
    -- 树回血任务
    local function UpdateTreeRegen(inst)
        if inst._tree_regen_task_2hm then
            inst._tree_regen_task_2hm:Cancel()
            inst._tree_regen_task_2hm = nil
        end
        
        local alive_tree_count = inst._numlinks or 0
        
        if alive_tree_count > 0 and inst.components.health and not inst.components.health:IsDead() then
            inst._tree_regen_task_2hm = inst:DoPeriodicTask(1, function()
                local count = inst._numlinks or 0
                
                if count > 0 and inst.components.health and not inst.components.health:IsDead() then
                    inst.components.health:DoDelta(count * 10, false, nil, true)
                else
                    if inst._tree_regen_task_2hm then
                        inst._tree_regen_task_2hm:Cancel()
                        inst._tree_regen_task_2hm = nil
                    end
                end
            end)
        end
    end
    
    inst:ListenForEvent("linkmushroomsprout", function(toadstool, tree)
        if tree and tree:IsValid() then
            if inst._planting_2hm then
                local already_in_queue = false
                for _, t in ipairs(inst._pending_trees_2hm) do
                    if t == tree then
                        already_in_queue = true
                        break
                    end
                end
                
                if not already_in_queue then
                    table.insert(inst._pending_trees_2hm, tree)
                end
            end
            
            UpdateTreeRegen(inst)
        end
    end)
    
    inst:ListenForEvent("unlinkmushroomsprout", function(toadstool, tree)
        for i, t in ipairs(inst._pending_trees_2hm) do
            if t == tree then
                table.remove(inst._pending_trees_2hm, i)
                break
            end
        end
        
        if inst._active_tree_2hm == tree then
            inst._active_tree_2hm = nil
        end
        
        UpdateTreeRegen(inst)
    end)

    inst:ListenForEvent("startchannel", function(inst)
        inst._planting_2hm = true
    end)
    
    -- 种树结束后开始激活流程
    inst:ListenForEvent("stopchannel", function(inst)
        if inst._planting_2hm then
            inst._planting_2hm = false
            
            inst:DoTaskInTime(0.5, function()
                if #inst._pending_trees_2hm <= 0 then
                    return
                end
                
                local shuffled = {}
                for i, tree in ipairs(inst._pending_trees_2hm) do
                    local pos = math.random(1, #shuffled + 1)
                    table.insert(shuffled, pos, tree)
                end
                inst._pending_trees_2hm = shuffled
                
                inst:PushEvent("activate_next_tree_2hm")
            end)
        end
    end)
    
    inst:ListenForEvent("activate_next_tree_2hm", function(inst)
        while #inst._pending_trees_2hm > 0 do
            local next_tree = table.remove(inst._pending_trees_2hm, 1)
            
            if next_tree and next_tree:IsValid() then
                inst._active_tree_2hm = next_tree
                next_tree._should_shake_2hm = true
                
                local bomb = SpawnPrefab("sporebomb")
                if bomb then
                    bomb._treetop_mode_2hm = true
                    bomb._tree_2hm = next_tree
                    bomb._timer_set_2hm = false
                    
                    bomb.entity:SetParent(next_tree.entity)
                    bomb.Transform:SetPosition(0, 4, 0)
                    next_tree._sporebomb_2hm = bomb
                    
                    local bomb_time = inst._is_dark_2hm and 5 or 10
                    bomb:DoTaskInTime(0.1, function()
                        if not bomb._timer_set_2hm and bomb.components.timer then
                            if bomb.components.timer:TimerExists("explode") then
                                bomb.components.timer:StopTimer("explode")
                            end
                            bomb.components.timer:StartTimer("explode", bomb_time)
                            bomb._timer_set_2hm = true
                        end
                    end)
                end
                
                return  
            end
        end
        
        inst._active_tree_2hm = nil
    end)
    
    -- 炸弹爆炸但树未被砍倒
    inst:ListenForEvent("tree_auto_switch_2hm", function(inst, data)
        if data and data.tree and data.tree:IsValid() then
            local current_tree = data.tree
            current_tree._should_shake_2hm = false
            current_tree._sporebomb_2hm = nil
            
            table.insert(inst._pending_trees_2hm, current_tree)
            
            inst:PushEvent("activate_next_tree_2hm")
        end
    end)
    
    -- 树被砍倒事件
    inst:ListenForEvent("mushroomchopped_2hm", function(inst, data)
        if data and data.tree then
            local tree = data.tree
            
            -- 爆炸孢子炸弹
            if tree._sporebomb_2hm and tree._sporebomb_2hm:IsValid() then
                local bomb = tree._sporebomb_2hm
                bomb._tree_chopped_2hm = true
                if bomb.components.debuff and bomb.components.debuff.detachedfn then
                    bomb.components.debuff.detachedfn(bomb, nil)
                else
                    bomb:Remove()
                end
            end
            
            -- 砍倒树时扣血
            if inst.components.health and not inst.components.health:IsDead() and inst.components.combat then
                local damage = inst._is_dark_2hm and 400 or 200
                inst.components.combat:GetAttacked(tree, damage, nil, "chop_tree")
            end
            
            if inst._active_tree_2hm == tree then
                inst._active_tree_2hm = nil
                inst:PushEvent("activate_next_tree_2hm")
            end
        end
    end)
end

-- 应用到毒菌蟾蜍和苦难蟾蜍
AddPrefabPostInit("toadstool", function(inst)
    if not TheWorld.ismastersim then return end
    inst:DoTaskInTime(0, function()
        SetupToadstoolTreeManagement(inst, false)
    end)
end)

AddPrefabPostInit("toadstool_dark", function(inst)
    if not TheWorld.ismastersim then return end
    inst:DoTaskInTime(0, function()
        SetupToadstoolTreeManagement(inst, true)
    end)
end)

-- ============================================================================
-- 其他增强都应用一下
local function swp2hmfn(inst)
    lasttoadstool = inst
    inst:ListenForEvent("onremove", onremove)
    
    -- 初始化伤害累计系统
    InitDamageAccumulate(inst)
    
    -- 种树时召唤蘑菇炸弹
    inst:ListenForEvent("timerdone", function(inst, data)
        if data and data.name == "channeltick" and 
           inst.components.health and not inst.components.health:IsDead() and 
           inst.components.combat and
           (inst.components.combat.target ~= nil or (GetTime() - inst.components.combat.lastwasattackedtime < 3)) and 
           inst.components.timer and
           not inst.components.timer:TimerExists("mushroombomb_cd") and 
           inst.DoMushroomBomb and inst.sg.mem and inst.SoundEmitter then
            
            inst.SoundEmitter:PlaySound("dontstarve/creatures/together/toad_stool/spore_shoot")
            inst:DoMushroomBomb()
            inst.sg.mem.mushroombomb_chains = (inst.sg.mem.mushroombomb_chains or 0) + 1
            if inst.sg.mem.mushroombomb_chains >= inst.mushroombomb_maxchain then
                inst.sg.mem.mushroombomb_chains = 0
                inst.components.timer:StartTimer("mushroombomb_cd", inst.mushroombomb_cd)
            end
        end
    end)
    
    if inst.prefab == "toadstool_dark" then
        inst.bouncethrow2hm = 2
        inst.bouncethrow2hmfn = bouncethrow2hmfn
    end
    
    if inst.components.lootdropper then
        for _, loot in ipairs({
            "red_mushroomhat_blueprint",
            "green_mushroomhat_blueprint",
            "blue_mushroomhat_blueprint",
            "mushroom_light_blueprint",
            "mushroom_light2_blueprint"
        }) do
            inst.components.lootdropper:AddChanceLoot(loot, 1)
        end
        -- 毒菌蟾蜍额外掉落3个睡袋
        if inst.prefab == "toadstool" then
            inst.components.lootdropper:AddChanceLoot("sleepbomb", 1)
            inst.components.lootdropper:AddChanceLoot("sleepbomb", 1)
            inst.components.lootdropper:AddChanceLoot("sleepbomb", 1)
        end
    end
    
    -- 战斗中返回当前位置，而非真实出生点
    if inst.components.knownlocations then
        local GetLocation = inst.components.knownlocations.GetLocation
        inst.components.knownlocations.GetLocation = function(self, name, ...)
            if name == "spawnpoint" and not userealspawnpoint then
                return inst:GetPosition()
            end
            return GetLocation(self, name, ...)
        end
    end
    
    inst:ListenForEvent("losttarget", onlosttarget)
    inst:ListenForEvent("newcombattarget", onnewcombattarget)
end

local function processtoadstool(inst)
    if not TheWorld.ismastersim then return end
    
    if TUNING.shadowworld2hm then
        inst.swp2hmfn = swp2hmfn
    else
        swp2hmfn(inst)
    end
end

AddPrefabPostInit("toadstool", processtoadstool)
AddPrefabPostInit("toadstool_dark", processtoadstool)



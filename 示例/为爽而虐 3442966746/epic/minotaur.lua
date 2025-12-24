-- ==============================================================================
-- 远古守护者增强
-- 1. 血量上限增加6000
-- 2. 碰撞石柱或累计受击15次触发召唤恶魔植物，诱惑采集
-- 3. 宝箱奖励限制，潜伏梦魇挑战
-- 4. 阵亡后20天重置远古
-- 5. 石虾雇佣缩短，会被boss破防，地下禁种海星
-- 6. 距离过远回城
-- 7. 更多触手

-- =============================================================================
TUNING.MINOTAUR_HEALTH = TUNING.MINOTAUR_HEALTH + 6000

-- 暗影触手存活状态：1=普通 2=战斗中
local bigshadowtentacleexist = 1

-- ==============================================================================

local function IsValidForAction(inst)
    return not inst:HasTag("swc2hm") and not inst:IsAsleep()
end

-- 是否为残血阶段
local function IsDangerPhase(inst)
    return inst.components.health and inst.components.health:GetPercent() < 0.6
end

-- 寻找有效的生成点
local function FindValidSpawnPoint(inst, center_pos, homepos)
    local angle = inst:GetAngleToPoint(center_pos)
    if homepos and angle then 
        angle = -angle 
    end
    
    local iscave = TheWorld:HasTag("cave")
    local check_radius = bigshadowtentacleexist > 1 and 0.5 or 1
    
    for i = 1, 15 do
        local radius = math.random(homepos and iscave and 25 or 5, iscave and 36 or 25) + math.random()
        local theta = (angle + GetRandomWithVariance(0, 90)) * DEGREES
        local offset = Vector3(radius * math.cos(theta), 0, -radius * math.sin(theta))
        local newpt = center_pos + offset
        
        if TheWorld.Map:IsPassableAtPoint(newpt.x, 0, newpt.z, false, true) and
           #TheSim:FindEntities(newpt.x, 0, newpt.z, check_radius, {"devil_plant2hm"}, {"player"}) <= 0 then
            return newpt, theta
        end
    end
    
    return nil, nil
end

-- 生成恶魔植物
local function SpawnDevilPlant(inst, pos)
    if not IsValidForAction(inst) then return end
    
    if not inst.plantsnumber2hm then 
        inst.plantsnumber2hm = #(TUNING.DEVILPLANTS2HM) 
    end
    -- 固定花园中心优先为犀牛出生点
    local homepos = inst.spawnlocation or (inst.components.knownlocations and inst.components.knownlocations:GetLocation("home"))
    local center_pos = pos or homepos or inst:GetPosition()
    local spawn_pos, theta
    
    if not pos then
        spawn_pos, theta = FindValidSpawnPoint(inst, center_pos, inst.spawnlocation or homepos)
        if not spawn_pos then return end
    else
        local check_radius = bigshadowtentacleexist > 1 and 0.5 or 1
        if #TheSim:FindEntities(pos.x, 0, pos.z, check_radius, {"devil_plant2hm"}, {"player"}) > 0 then
            return
        end
        spawn_pos = pos
    end
    
    local prefabname = TUNING.DEVILPLANTS2HM[math.random(inst.plantsnumber2hm)]
    local plant = SpawnPrefab(prefabname)
    plant.Transform:SetPosition(spawn_pos.x, 0, spawn_pos.z)
    if theta then 
        plant.Transform:SetRotation(theta / DEGREES - 180) 
    end
end

-- 生成血液特效
local function SpawnBloodDrops(inst, is_danger)
    if not inst.SpawnBigBloodDrop then return end
    
    local drop_chances = is_danger and {1, 0.75, 0.5} or {0.75, 0.5, 0.25}
    for _, chance in ipairs(drop_chances) do
        if math.random() < chance then
            inst:SpawnBigBloodDrop()
        end
    end
end

-- 概率生成恶魔植物
local function SpawnDevilPlantsWithChance(inst, is_danger)
    local chance = is_danger and 0.25 or 0.15
    local max_index = is_danger and 4 or 6
    
    for index = 2, max_index do
        if math.random() < index * chance then
            SpawnDevilPlant(inst)
        end
    end
end

-- ==============================================================================
-- 潜伏梦魇

-- 计算需要生成的潜伏梦魇数量
local function CalculateNightmareCount(chest)
    if not (chest and chest:IsValid()) then return 1 end
    
    local x, y, z = chest.Transform:GetWorldPosition()
    local players = TheSim:FindEntities(x, y, z, 25, {"player"}, {"playerghost", "INLIMBO"})
    local player_count = #players
    return math.max(1, player_count) 
end

-- 设置潜伏梦魇的监听器和行为
local function SetupLurkingNightmare(nightmare, chest, spawn_pos)
    if not (nightmare and nightmare:IsValid()) then return end
    
    nightmare.chest2hm = chest
    nightmare.spawn_pos2hm = spawn_pos or (chest and Vector3(chest.Transform:GetWorldPosition()))
    
    nightmare:AddTag("lurking_nightmare2hm")

    -- 受到单次大于50点伤害后消失
    if not nightmare.attacked_listener_setup2hm then
        nightmare.attacked_listener_setup2hm = true
        nightmare:ListenForEvent("attacked", function(inst, data)
            if data and data.damage and data.damage > 50 then
                inst:Remove()
            end
        end)
    end
    
    -- 监听死亡事件
    if not nightmare.death_listener_setup2hm then
        nightmare.death_listener_setup2hm = true
        nightmare:ListenForEvent("death", function(inst)
            if inst.chest2hm and inst.chest2hm:IsValid() and inst.spawn_pos2hm then
                local fx = SpawnPrefab("sanity_raise")
                if fx then
                    fx.Transform:SetPosition(inst.spawn_pos2hm:Get())
                    if fx.AnimState then
                        fx.AnimState:SetScale(2, 2, 2)
                    end
                end
                
                -- 增加宝箱可领取奖励数+2
                if inst.chest2hm.itemlimit2hm then
                    local old_limit = inst.chest2hm.itemlimit2hm
                    inst.chest2hm.itemlimit2hm = inst.chest2hm.itemlimit2hm + 2
                end
            end
        end)
    end
    
    -- 距离检测
    if not nightmare.distance_check_setup2hm then
        nightmare.distance_check_setup2hm = true
        nightmare:DoPeriodicTask(0.5, function(inst)
            if not (inst.chest2hm and inst.chest2hm:IsValid() and inst.spawn_pos2hm) then
                inst:Remove()
                return
            end
            
            local dist = inst:GetDistanceSqToPoint(inst.spawn_pos2hm:Get())
            if dist > 60 * 60 then
                inst:Remove()
            end
        end)
    end
    
    -- 停止监听暴动平息
    if nightmare.OnNightmareDawn then
        nightmare:StopWatchingWorldState("isnightmaredawn", nightmare.OnNightmareDawn)
    end
end

-- 生成潜伏梦魇
local function SpawnLurkingNightmare(chest)
    if not (chest and chest:IsValid()) then return end
    
    local x, y, z = chest.Transform:GetWorldPosition()

    local fx = SpawnPrefab("shadow_despawn")
    if fx then fx.Transform:SetPosition(x, y, z) end
    
    local nightmare = SpawnPrefab("ruinsnightmare")
    if not nightmare then return end
    
    nightmare.Transform:SetPosition(x, y, z)

    SetupLurkingNightmare(nightmare, chest, Vector3(x, y, z))
    
    return nightmare
end

-- ================================================================================
-- 潜伏梦魇初始化
AddPrefabPostInit("ruinsnightmare", function(inst)
    if not TheWorld.ismastersim then return end
 
    local old_OnSave = inst.OnSave
    inst.OnSave = function(inst, data)
        if old_OnSave then old_OnSave(inst, data) end
        
        if inst:HasTag("lurking_nightmare2hm") then

            if inst.chest2hm and inst.chest2hm:IsValid() then
                local cx, cy, cz = inst.chest2hm.Transform:GetWorldPosition()
                data.chest_pos2hm = {x = cx, y = cy, z = cz}
            end
            if inst.spawn_pos2hm then
                data.spawn_pos2hm = {x = inst.spawn_pos2hm.x, y = inst.spawn_pos2hm.y, z = inst.spawn_pos2hm.z}
            end
        end
    end
  
    local old_OnLoad = inst.OnLoad
    inst.OnLoad = function(inst, data)
        if old_OnLoad then old_OnLoad(inst, data) end
        
        if data and (data.chest_pos2hm or data.spawn_pos2hm) then
            inst:AddTag("lurking_nightmare2hm")

            if data.spawn_pos2hm then
                inst.spawn_pos2hm = Vector3(data.spawn_pos2hm.x, data.spawn_pos2hm.y, data.spawn_pos2hm.z)
            end

            -- 使用位置匹配来绑定原有的宝箱
            if data.chest_pos2hm then
                inst:DoTaskInTime(0, function()
                    local cx, cy, cz = data.chest_pos2hm.x, data.chest_pos2hm.y, data.chest_pos2hm.z
                    local chests = TheSim:FindEntities(cx, cy, cz, 2, {"chest"})

                    local found_chest = nil
                    for _, chest in ipairs(chests) do
                        if chest.prefab == "minotaurchest" then
                            local chestx, chesty, chestz = chest.Transform:GetWorldPosition()
                            local dist = math.sqrt((chestx - cx)^2 + (chestz - cz)^2)

                            if dist < 0.5 then
                                found_chest = chest
                                break
                            end
                        end
                    end
                    
                    if found_chest then
                        SetupLurkingNightmare(inst, found_chest, inst.spawn_pos2hm)
                    else
                        SetupLurkingNightmare(inst, nil, inst.spawn_pos2hm)
                    end
                end)
            else
                inst:DoTaskInTime(0, function()
                    SetupLurkingNightmare(inst, nil, inst.spawn_pos2hm)
                end)
            end
        end
    end
end)

-- ==============================================================================
-- 各种事件处理，碰撞石柱触发
local function OnCollisionStun(inst)
    if not IsValidForAction(inst) then return end
    if inst.summoncdtask2hm then return end
    if not inst.components.health or inst.components.health:IsDead() then return end
    
    local is_danger = IsDangerPhase(inst)
    local cooldown = is_danger and 4 or 13
    local attack_reduction = is_danger and 8 or 15
    
    inst.summoncdtask2hm = inst:DoTaskInTime(cooldown, function() 
        inst.summoncdtask2hm = nil 
    end)
    inst.attackedindex2hm = math.clamp(inst.attackedindex2hm - attack_reduction, 0, 15)
    
    SpawnBloodDrops(inst, is_danger)
    SpawnDevilPlantsWithChance(inst, is_danger)
end

-- 受到攻击触发
local function OnAttacked(inst)
    if not inst.attacked2hm then 
        inst.attacked2hm = true 
    end
    
    if not IsValidForAction(inst) then return end
    
    -- 累计受击15次触发
    inst.attackedindex2hm = inst.attackedindex2hm + 1
    if not inst.summoncdtask2hm and inst.attackedindex2hm >= 15 then
        OnCollisionStun(inst)
    end
end

-- 死亡处理
local function OnDeath(inst)
    if inst:HasTag("swc2hm") then return end
    
    -- 启动远古重置定时器
    if TheWorld:HasTag("cave") and TheWorld.components.worldsettingstimer then
        if TheWorld.components.worldsettingstimer:TimerExists("mod_minotaur_resurrect") and
           not TheWorld.components.worldsettingstimer:ActiveTimerExists("mod_minotaur_resurrect") then
            TheWorld.components.worldsettingstimer:StartTimer("mod_minotaur_resurrect", TUNING.ATRIUM_GATE_COOLDOWN)
        end
    end
    
    -- 重置触手状态
    bigshadowtentacleexist = 1
    
    -- 清理恶魔植物
    local x, y, z = inst.Transform:GetWorldPosition()
    local plants = TheSim:FindEntities(x, y, z, 100, {"devil_plant2hm"}, {"player"})
    for _, plant in ipairs(plants) do
        plant:DoTaskInTime(math.random(10, 30), plant.KillPlant or plant.Remove)
    end
end

-- 脱战恢复
local function DelayOnEntitySleep(inst)
    inst.sleeptask2hm = nil
    
    if not inst:HasTag("swc2hm") then
        bigshadowtentacleexist = 1
    end
    
    if inst.components.health and not inst.components.health:IsDead() then
        if TUNING.DSTU then
            local x, y, z = inst.Transform:GetWorldPosition()
            inst.Transform:SetPosition(x, 0, z)
            if inst.sg then 
                inst.sg:GoToState("idle") 
            end
        elseif inst.attacked2hm then
            inst.attacked2hm = nil
            inst.components.health:DoDelta(inst.components.health.maxhealth * 0.05, nil, nil, true)
        end
    end
end

-- 进入睡眠状态
local function OnEntitySleep(inst)
    if not inst.sleeptask2hm then
        inst.sleeptask2hm = inst:DoTaskInTime(3, DelayOnEntitySleep)
    end
end

-- 唤醒状态
local function OnEntityWake(inst)
    if inst:IsAsleep() then return end
    
    if inst.components.health and not inst.components.health:IsDead() and not inst:HasTag("swc2hm") then
        bigshadowtentacleexist = inst.refreshcd2hm and 3 or 2
    end
    
    if inst.sleeptask2hm then
        inst.sleeptask2hm:Cancel()
        inst.sleeptask2hm = nil
    end
end

-- ===============================================================================
-- 犀牛初始化部分

AddPrefabPostInit("minotaur", function(inst)
    if not TheWorld.ismastersim then return end
    
    inst.attackedindex2hm = 0
    inst.chargecount = 0
    
    inst:ListenForEvent("blocked", OnAttacked)
    inst:ListenForEvent("attacked", OnAttacked)
    inst:ListenForEvent("collision_stun", OnCollisionStun)
    inst:ListenForEvent("death", OnDeath)
    inst:ListenForEvent("entitysleep", OnEntitySleep)
    inst:ListenForEvent("entitywake", OnEntityWake)
    
    inst:DoTaskInTime(0, OnEntityWake)
end)

-- 添加冰冻抗性
AddPrefabPostInit("minotaur", function(inst)
    if not TheWorld.ismastersim then return end
    if inst.components.freezable then
        inst.components.freezable.diminishingreturns = true
    end
end)

-- =============================================================================
-- 石虾BOSS可以破盾、缩短雇佣时长
local function onrockyattacked(inst, data)
    if data and data.attacker and data.attacker:IsValid() and data.attacker:HasTag("epic") and 
       inst.sg and inst.sg.currentstate and inst.sg.currentstate.name == "shield" and 
       not inst.components.health:IsDead() then
        inst.sg:GoToState("shield_end")
    end
end

AddPrefabPostInit("rocky", function(inst)
    if not TheWorld.ismastersim then return end
    
    inst:ListenForEvent("attacked", onrockyattacked)
    
    if inst.components.follower then
        -- 180s
        inst.components.follower.maxfollowtime = TUNING.PIG_LOYALTY_MAXTIME * 0.15
    end
end)

-- =============================================================================
-- 回城技能
AddStategraphPostInit("minotaur", function(sg)
    if not (TUNING.DSTU and sg.states.arena_return_pre and sg.states.arena_return_pre.ontimeout) then
        return
    end
    
    local ontimeout = sg.states.arena_return_pre.ontimeout
    sg.states.arena_return_pre.ontimeout = function(inst, ...)
        ontimeout(inst, ...)
        
        if inst.sg.statemem.minotaurhome2hm then return end
        
        inst.sg.statemem.minotaurhome2hm = true
        
        -- 恢复10%生命值
        if inst.components.health and not inst.components.health:IsDead() and inst.attacked2hm then
            inst.attacked2hm = nil
            inst.components.health:DoDelta(inst.components.health.maxhealth * 0.1)
        end
        
        -- 重置召唤CD并减少受击计数
        if inst.summoncdtask2hm then
            inst.summoncdtask2hm = nil
            local is_danger = IsDangerPhase(inst)
            inst.attackedindex2hm = math.clamp(inst.attackedindex2hm - (is_danger and 8 or 15), 0, 15)
        end
        
        SpawnDevilPlant(inst, inst:GetPosition())
        OnCollisionStun(inst)
    end
end)

-- =============================================================================
-- 远古守护者死亡20天后重置远古，击败远古织影者可提前重置
local function OnTimer(inst, data)
    if data and data.name == "mod_minotaur_resurrect" then
        inst:PushEvent("resetruins")
    end
end

local function OnResetRuins(inst)
    if inst.components.worldsettingstimer and 
       inst.components.worldsettingstimer:ActiveTimerExists("mod_minotaur_resurrect") then
        inst.components.worldsettingstimer:StopTimer("mod_minotaur_resurrect")
    end
end

AddPrefabPostInit("world", function(inst)
    if not inst.ismastersim or not inst:HasTag("cave") or not inst.components.worldsettingstimer then
        return inst
    end
    
    inst.components.worldsettingstimer:AddTimer("mod_minotaur_resurrect", TUNING.ATRIUM_GATE_COOLDOWN, true)
    inst:ListenForEvent("timerdone", OnTimer)
    inst:ListenForEvent("resetruins", OnResetRuins)
end)

-- =============================================================================
-- 海星在洞穴中禁种

local function ClearStarfishTrap(inst)
    if inst.components.workable then
        inst.components.workable:WorkedBy(inst, 1)
    end
end

AddPrefabPostInit("trap_starfish", function(inst)
    if not TheWorld.ismastersim or not TheWorld:HasTag("cave") then
        return inst
    end
    inst:DoTaskInTime(0, ClearStarfishTrap)
end)

-- =============================================================================
-- 协助作战的暗影触手，死亡后留下邪恶花
local function ShadowTentacleShouldKeepTarget(inst, target)
    return target ~= nil and target:IsValid() and target.entity:IsVisible() and 
           target.components.health ~= nil and not target.components.health:IsDead() and
           target:IsNear(inst, TUNING.TENTACLE_STOPATTACK_DIST) and 
           (target:HasTag("player") or not (target.sg and target.sg:HasStateTag("hiding")))
end

local function OnBigShadowTentacleRemove(inst)
    if bigshadowtentacleexist == 1 then return end
    
    -- 留下邪恶花作为痕迹
    local flower_evil = SpawnPrefab("flower_evil")
    flower_evil.persists = false
    flower_evil.Transform:SetPosition(inst.Transform:GetWorldPosition())
    flower_evil:DoTaskInTime(120, flower_evil.Remove)
end

AddPrefabPostInit("bigshadowtentacle", function(inst)
    if not TheWorld.ismastersim then return end
    
    if bigshadowtentacleexist ~= 1 then
        inst.components.combat:SetKeepTargetFunction(ShadowTentacleShouldKeepTarget)
    end
    
    inst:ListenForEvent("onremove", OnBigShadowTentacleRemove)
end)

AddStategraphPostInit("bigshadowtentacle", function(sg)
    sg.states.attack_post.events.animover.fn = function(inst, ...)
        if inst.AnimState:AnimDone() then
            inst.existindex2hm = (inst.existindex2hm or 0) + 1
            if inst.existindex2hm >= bigshadowtentacleexist then
                inst:Remove()
            else
                inst.sg:GoToState("arrive")
            end
        end
    end
end)

-- =============================================================================
-- 恶魔植物诱惑采集动作
local forcepickstate = State {
    name = "forcepick2hm",
    tags = {"doing", "busy", "nodangle", "nopredict"},
    
    onenter = function(inst)
        inst.components.locomotor:Stop()
        inst.components.inventory:Hide()
        inst:PushEvent("ms_closepopups")
        
        if inst.components.playercontroller ~= nil then
            inst.components.playercontroller:EnableMapControls(false)
            inst.components.playercontroller:Enable(false)
        end

        inst.sg:SetTimeout(math.random() + 1.5)
        inst.SoundEmitter:PlaySound("dontstarve/wilson/make_trap", "make")
        
        if not (inst.weremode and inst.weremode:value() ~= 0) then
            inst.AnimState:PlayAnimation("build_pre")
            inst.AnimState:PushAnimation("build_loop", true)
        end
    end,
    
    ontimeout = function(inst)
        -- 生成暗影触手惩罚
        local tent = SpawnPrefab("bigshadowtentacle")
        tent.Transform:SetPosition(inst.Transform:GetWorldPosition())
        tent:PushEvent("arrive")
        
        -- 强制采集植物
        if inst.forcepicktarget2hm and inst.forcepicktarget2hm.components and 
           inst.forcepicktarget2hm.components.pickable then
            inst.forcepicktarget2hm.components.pickable:Pick(inst)
            inst.forcepicktarget2hm = nil
        end
        
        inst.SoundEmitter:KillSound("make")
        if not (inst.weremode and inst.weremode:value() ~= 0) then
            inst.AnimState:PlayAnimation("build_pst")
        end
        inst.sg:GoToState("idle")
    end,
    
    onexit = function(inst)
        inst.SoundEmitter:KillSound("make")
        inst.components.inventory:Show()
        
        if inst.components.playercontroller ~= nil then
            inst.components.playercontroller:EnableMapControls(true)
            inst.components.playercontroller:Enable(true)
        end
    end
}

AddStategraphState("wilson", forcepickstate)

local function ForcepickDevilPlant2hm(inst, target)
    inst.forcepicktarget2hm = target
    if not inst.sg:HasStateTag("dead") then
        inst.sg:GoToState("forcepick2hm")
    end
end

AddPlayerPostInit(function(inst)
    if not TheWorld.ismastersim then return end
    inst.forcepickdevilplant2hm = ForcepickDevilPlant2hm
end)

-- =============================================================================
-- 传送魔杖使用时触发地震并吸引怪物仇恨
AddPrefabPostInit("telestaff", function(inst)
    if not TheWorld.ismastersim then return end
    if not (inst.components.spellcaster and inst.components.spellcaster.spell) then return end
    
    local spell = inst.components.spellcaster.spell
    inst.components.spellcaster.spell = function(inst, target, pos, caster, ...)
        -- 洞穴中使用时触发地震
        if caster and caster:IsValid() and TheWorld:HasTag("cave") then
            TheWorld:PushEvent("ms_miniquake", {rad = 3, num = 5, duration = 1.5, target = caster})
        end
        
        -- 传送怪物时引发仇恨
        if target and target:IsValid() and not target:HasTag("player") and target.components.combat then
            target.components.combat:SuggestTarget(caster)
        end
        
        return spell(inst, target, pos, caster, ...)
    end
end)

-- =============================================================================
-- 大华丽宝箱限制玩家从中获取道具的数量（2-3个）

-- 显示宝箱限制提示
local function SayMinotaurChestText(inst, itemlimit2hm)
    inst.sayminotaurchesttexttask2hm = nil
    
    if not inst.components.talker then return end
    
    local desc
    if itemlimit2hm then
        desc = (TUNING.isCh2hm and "你可以从这个箱子里拿走" or "You can get ") .. 
               itemlimit2hm .. 
               (TUNING.isCh2hm and "个道具" or " items form the chest.")
    else
        desc = TUNING.isCh2hm and "箱子的道具拿走限制已经解除了" or "The chest's items limit now stop."
    end
    
    inst.components.talker:Say(desc, nil, true)
end

-- 打开宝箱时提示
local function MinotaurChestOnOpen(inst, data)
    -- 生成潜伏梦魇
    if inst.nightmare_count2hm and inst.nightmare_count2hm > 0 then
        for i = 1, inst.nightmare_count2hm do
            inst:DoTaskInTime((i - 1) * 0.2, function()
                if inst:IsValid() then
                    SpawnLurkingNightmare(inst)
                end
            end)
        end
        inst.nightmare_count2hm = nil -- 只在第一次打开时生成
    end
    
    if not inst.itemlimit2hm or not inst.components.inspectable then return end
    if not (data and data.doer and data.doer:IsValid() and data.doer:HasTag("player") and data.doer.components.talker) then return end
    
    local desc, text_filter_context, original_author = inst.components.inspectable:GetDescription(data.doer)
    desc = (TUNING.isCh2hm and "你可以从这个箱子里拿走" or "You can get ") .. 
           inst.itemlimit2hm .. 
           (TUNING.isCh2hm and "个道具" or " items form the chest.")
    
    if desc ~= nil then
        data.doer.components.talker:Say(desc, nil, true, nil, nil, nil, text_filter_context, original_author)
    end
end

-- 处理道具限制逻辑
local minotaurchestinit

local function MinotaurChestProcess(inst, limit, recordslots)
    if inst.itemlimit2hm ~= nil or not inst.components.container then return end
    
    inst.itemlimit2hm = limit
    if limit == nil then
        local x, y, z = inst.Transform:GetWorldPosition()
        local node = TheWorld.Map:FindVisualNodeAtPoint(x, 0, z, "Nightmare")
        inst.itemlimit2hm = node ~= nil and 3 or 2
    end
    
    inst.limitfn2hm = function(item)
        if not (inst.recorditems2hm and inst.recorditems2hm[item]) then return end
        
        inst.itemlimit2hm = inst.itemlimit2hm - 1
        inst.recorditems2hm[item] = nil
        
        if item:IsValid() then
            inst:RemoveEventCallback("onremove", inst.limitfn2hm, item)
            inst:RemoveEventCallback("ondropped", inst.limitfn2hm, item)
            inst:RemoveEventCallback("onputininventory", inst.limitfn2hm, item)
            inst:RemoveEventCallback("stacksizechange", inst.limitfn2hm, item)
        end
        
        -- 达到限制后清理剩余道具
        if inst.itemlimit2hm <= 0 then
            inst.itemlimit2hm = nil
            
            for v, value in pairs(inst.recorditems2hm) do
                if v and v:IsValid() and value then
                    inst:RemoveEventCallback("onremove", inst.limitfn2hm, v)
                    inst:RemoveEventCallback("ondropped", inst.limitfn2hm, v)
                    inst:RemoveEventCallback("onputininventory", inst.limitfn2hm, v)
                    inst:RemoveEventCallback("stacksizechange", inst.limitfn2hm, v)
                    v:DoTaskInTime(0, v.Remove)
                end
            end
            
            inst.limitfn2hm = nil
            inst.recorditems2hm = nil
            inst:RemoveEventCallback("onopen", MinotaurChestOnOpen)
            
            SpawnPrefab("collapse_big").Transform:SetPosition(inst.Transform:GetWorldPosition())
            if TheNet:IsServerPaused() then
                TheNet:SetServerPaused(false)
            end
            return
        end
        
        -- 更新提示信息
        if inst.components.container and inst.components.container:IsOpen() then
            local player = FindClosestPlayerToInst(inst, 10, true)
            if player then
                if player.sayminotaurchesttexttask2hm then
                    player.sayminotaurchesttexttask2hm:Cancel()
                    player.sayminotaurchesttexttask2hm = nil
                end
                
                if not (inst.components.workable and inst.components.workable.workleft <= 0) then
                    player.sayminotaurchesttexttask2hm = player:DoTaskInTime(0, SayMinotaurChestText, inst.itemlimit2hm)
                end
            end
        end
    end
    
    -- 记录箱子中的所有道具
    local total = 0
    inst.recorditems2hm = {}
    
    for i = 1, inst.components.container.numslots do
        local v = inst.components.container.slots[i]
        if (recordslots == nil or table.contains(recordslots, i)) and 
           v ~= nil and v:IsValid() and v.components.inventoryitem then
            inst.recorditems2hm[v] = true
            inst:ListenForEvent("onremove", inst.limitfn2hm, v)
            inst:ListenForEvent("ondropped", inst.limitfn2hm, v)
            inst:ListenForEvent("onputininventory", inst.limitfn2hm, v)
            inst:ListenForEvent("stacksizechange", inst.limitfn2hm, v)
            total = total + 1
        end
    end
    
    -- 道具数量不超过限制则取消限制
    if total == 0 or total <= inst.itemlimit2hm then
        inst.itemlimit2hm = nil
        
        for v, value in pairs(inst.recorditems2hm) do
            if v and v:IsValid() and value then
                inst:RemoveEventCallback("onremove", inst.limitfn2hm, v)
                inst:RemoveEventCallback("ondropped", inst.limitfn2hm, v)
                inst:RemoveEventCallback("onputininventory", inst.limitfn2hm, v)
                inst:RemoveEventCallback("stacksizechange", inst.limitfn2hm, v)
            end
        end
        
        inst.recorditems2hm = nil
        inst.limitfn2hm = nil
        return
    end
    
    inst:ListenForEvent("onopen", MinotaurChestOnOpen)
end

local function MinotaurChestOnLoad(inst, data)
    if data and data.itemlimit2hm then
        inst:DoTaskInTime(0, MinotaurChestProcess, data.itemlimit2hm, data.recordslots2hm)
    end

    if data and data.nightmare_count2hm then
        inst.nightmare_count2hm = data.nightmare_count2hm
    end
end

local function MinotaurChestOnSave(inst, data)
    data.itemlimit2hm = inst.itemlimit2hm
    
    if inst.itemlimit2hm and inst.recorditems2hm then
        data.recordslots2hm = {}
        for i = 1, inst.components.container.numslots do
            local v = inst.components.container.slots[i]
            if v and inst.recorditems2hm[v] then
                table.insert(data.recordslots2hm, i)
            end
        end
    end

    if inst.nightmare_count2hm then
        data.nightmare_count2hm = inst.nightmare_count2hm
    end
end

AddPrefabPostInit("minotaurchest", function(inst)
    if not TheWorld.ismastersim then return end
    
    SetOnLoad(inst, MinotaurChestOnLoad)
    SetOnSave(inst, MinotaurChestOnSave)
    
    if minotaurchestinit then
        inst:DoTaskInTime(0, MinotaurChestProcess)
        inst:DoTaskInTime(0, function()
            inst.nightmare_count2hm = CalculateNightmareCount(inst)
        end)
    end
end)

-- 宝箱内容初始化
AddPrefabPostInit("minotaurchestspawner", function(inst)
    if not TheWorld.ismastersim then return end
    if inst.task and inst.task.fn then
        local fn = inst.task.fn
        inst.task.fn = function(...)
            minotaurchestinit = true
            fn(...)
            minotaurchestinit = nil
        end
    end
end)

-- 齿轮替换为巨石枝种子
AddSimPostInit(function()
    local ctor = GLOBAL.Prefabs["minotaurchestspawner"].fn
    local dospawnchest = getupvalue2hm(ctor, "dospawnchest")
    if dospawnchest then
        local chest_loot = getupvalue2hm(dospawnchest, "chest_loot")
        if chest_loot and #chest_loot >= 9 then
            -- 原表的第9项是齿轮，替换为巨石枝种子
            chest_loot[9] = {item = {"tree_rock_seed"}, count = {6, 9}}
        end
    end
end)

-- =============================================================================
-- 巨石枝种子掉落概率调整  
AddSimPostInit(function()

    if LootTables and LootTables['tree_rock1_mine'] then
        local loot = LootTables['tree_rock1_mine']

        for i, item in ipairs(loot) do
            if item[1] == 'tree_rock_seed' then
                item[2] = 0.70  -- 1.00 -> 0.70
                break
            end
        end
    end
    
    -- 被大虫子破坏的
    if LootTables and LootTables['tree_rock1_mine_break'] then
        local loot = LootTables['tree_rock1_mine_break']

        for i, item in ipairs(loot) do
            if item[1] == 'tree_rock_seed' then
                item[2] = 0.70  
                break
            end
        end
    end
end)

-- ===============================================================================
-- 限制犀牛飞扑跳跃距离，最多16单位
AddStategraphPostInit("minotaur", function(sg)
    -- 原版飞扑
    if sg.states and sg.states.leap_attack_pre and sg.states.leap_attack_pre.ontimeout then
        local _original_ontimeout = sg.states.leap_attack_pre.ontimeout
        
        sg.states.leap_attack_pre.ontimeout = function(inst, target)
            if inst.sg.statemem.startpos and inst.sg.statemem.targetpos then
                local start_pos = inst.sg.statemem.startpos
                local target_pos = inst.sg.statemem.targetpos
                
                local dx = target_pos.x - start_pos.x
                local dz = target_pos.z - start_pos.z
                local distance = math.sqrt(dx * dx + dz * dz)
                
                if distance > 16 then
                    local ratio = 16 / distance
                    inst.sg.statemem.targetpos = Vector3(
                        start_pos.x + dx * ratio,
                        0,
                        start_pos.z + dz * ratio
                    )
                end
            end
            
            _original_ontimeout(inst, target)
        end
    end
    
    -- 妥协的连续飞扑
    if TUNING.DSTU and sg.states and sg.states.leap_attack_pre_quick and sg.states.leap_attack_pre_quick.ontimeout then
        local _original_quick_ontimeout = sg.states.leap_attack_pre_quick.ontimeout
        
        sg.states.leap_attack_pre_quick.ontimeout = function(inst, target)
            if inst.sg.statemem.startpos and inst.sg.statemem.targetpos then
                local start_pos = inst.sg.statemem.startpos
                local target_pos = inst.sg.statemem.targetpos

                local dx = target_pos.x - start_pos.x
                local dz = target_pos.z - start_pos.z
                local distance = math.sqrt(dx * dx + dz * dz)

                if distance > 16 then
                    local ratio = 16 / distance
                    inst.sg.statemem.targetpos = Vector3(
                        start_pos.x + dx * ratio,
                        0,
                        start_pos.z + dz * ratio
                    )
                end
            end
            
            _original_quick_ontimeout(inst, target)
        end
    end
end)

-- ===============================================================================
-- 妥协连续飞扑晕眩时间延长
if TUNING.DSTU then
    AddStategraphPostInit("minotaur", function(sg)
        if not (sg.states and sg.states.leap_attack and sg.states.leap_attack.events and sg.states.leap_attack.events.animover) then 
            return 
        end

        local _original_leap_attack_animover = sg.states.leap_attack.events.animover.fn
        
        sg.states.leap_attack.events.animover.fn = function(inst, ...)
            inst._saved_combo_for_stun = inst.combo or 0
            _original_leap_attack_animover(inst, ...)
        end
    end)
    
    AddStategraphPostInit("minotaur", function(sg)
        if not (sg.states and sg.states.stun) then return end

        local _original_stun_onenter = sg.states.stun.onenter
        
        sg.states.stun.onenter = function(inst, data, ...)
            local saved_combo = inst._saved_combo_for_stun or 0
            local should_extend = data and data.land_stun and saved_combo > 0
            
            _original_stun_onenter(inst, data, ...)
            
            if should_extend then
                if inst.components.timer and inst.components.timer:TimerExists("endstun") then
                    local original_time = inst.components.timer:GetTimeLeft("endstun")
                    local combo_bonus = saved_combo * 0.9
                    local new_time = original_time + combo_bonus
                    
                    inst.components.timer:SetTimeLeft("endstun", new_time)
                    
                    inst._extended_stun_time = new_time
                    inst._stun_restore_once = true
                    inst._saved_combo_for_stun = nil
                end
            end
        end
        
        if sg.states.stun_loop then
            local _original_stun_loop_onenter = sg.states.stun_loop.onenter
            sg.states.stun_loop.onenter = function(inst, ...)
                if _original_stun_loop_onenter then
                    _original_stun_loop_onenter(inst, ...)
                end
                
                if inst._stun_restore_once and inst._extended_stun_time 
                    and inst.components.timer and inst.components.timer:TimerExists("endstun") then
                    local current_time = inst.components.timer:GetTimeLeft("endstun")
                    if current_time < inst._extended_stun_time then
                        inst.components.timer:SetTimeLeft("endstun", inst._extended_stun_time)
                    end
                    inst._stun_restore_once = nil
                end
            end
        end

        if sg.states.stun_pst then
            local _original_stun_pst_onenter = sg.states.stun_pst.onenter
            sg.states.stun_pst.onenter = function(inst, ...)
                inst._extended_stun_time = nil
                inst._stun_restore_once = nil
                inst._saved_combo_for_stun = nil
                
                if _original_stun_pst_onenter then
                    _original_stun_pst_onenter(inst, ...)
                end
            end
        end
    end)
end

-- ===============================================================================
-- 冲撞追踪目标，弧形轨迹
AddStategraphPostInit("minotaur", function(sg)
    if not (sg.states and sg.states.run) then return end

    local original_onenter = sg.states.run.onenter
    local original_onupdate = sg.states.run.onupdate
    
    sg.states.run.onenter = function(inst, ...)
        if original_onenter then
            original_onenter(inst, ...)
        end
        
        if inst.components.combat and inst.components.combat.target then
            inst.sg.statemem.charge_target = inst.components.combat.target
        end
    end
    
    sg.states.run.onupdate = function(inst, dt)
        if original_onupdate then original_onupdate(inst, dt) end
        
        local target = inst.sg.statemem.charge_target
        if target and target:IsValid() and not target:HasTag("INLIMBO") then
            local target_x, target_y, target_z = target.Transform:GetWorldPosition()
            local inst_x, inst_y, inst_z = inst.Transform:GetWorldPosition()

            local dx = target_x - inst_x
            local dz = target_z - inst_z
            local target_angle = math.atan2(-dz, dx) / DEGREES
            
            local current_angle = inst.Transform:GetRotation()
            
            local angle_diff = target_angle - current_angle
            
            -- 归一化角度差到 -180 到 180 度之间
            while angle_diff > 180 do
                angle_diff = angle_diff - 360
            end
            while angle_diff < -180 do
                angle_diff = angle_diff + 360
            end
            
            -- 每帧最大转向角度（度数），控制转弯的平滑度
            -- 值越小转弯越平滑，弧度越大；值越大转弯越急
            local max_turn_per_frame = 90 * dt  -- 每秒最多转90度
            
            -- 限制每帧的转向量
            local turn_amount = math.clamp(angle_diff, -max_turn_per_frame, max_turn_per_frame)
            
            -- 应用新的朝向
            inst.Transform:SetRotation(current_angle + turn_amount)
            
            -- 锁头追踪
            -- inst:ForceFacePoint(target_x, target_y, target_z)
        end
    end
end)

-- ================================================================================
-- 修复妥协的动画bank切换错误leap_attack_pre_quick 和 belch 状态在 onexit 时才恢复 bank
-- 导致下一个状态的 onenter 在错误的 bank 里尝试播放动画

-- ================================================================================
-- 修复犀牛死亡后状态未清理导致复活异常的问题
AddPrefabPostInit("minotaur", function(inst)
    if not TheWorld.ismastersim then return end
    
    -- 在死亡时清理所有相关状态
    inst:DoTaskInTime(0, function()
        inst:ListenForEvent("death", function(inst)
            inst.forceleap = nil
            inst.forcebelch = nil
            inst.have_a_heart = nil
            inst.tentbelch = nil
            
            inst._saved_combo_for_stun = nil
            inst._extended_stun_time = nil
            inst._stun_restore_once = nil
            inst.combo = nil
            
            if inst.components.timer then
                if inst.components.timer:TimerExists("forceleapattack") then
                    inst.components.timer:StopTimer("forceleapattack")
                end
                if inst.components.timer:TimerExists("forcebelch") then
                    inst.components.timer:StopTimer("forcebelch")
                end
            end
        end)
    end)
end)



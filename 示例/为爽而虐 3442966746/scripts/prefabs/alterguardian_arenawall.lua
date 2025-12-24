
local assets = {
    Asset("ANIM", "anim/alterguardian_meteor.zip"),
    -- 备用动画
    Asset("ANIM", "anim/wagpunk_cagewall.zip"),    
}

local prefabs = {
    "alterguardian_phase3trapgroundfx",            
}

local function PlayLoopingSFX(inst)
    inst.SoundEmitter:PlaySound("moonstorm/creatures/boss/alterguardian3/atk_trap_LP", "arenawall_LP")
end

local function StopLoopingSFX(inst)
    if inst.loopingsfxtask ~= nil then
        inst.loopingsfxtask:Cancel()
        inst.loopingsfxtask = nil
    end
    inst.SoundEmitter:KillSound("arenawall_LP")
end

-- 催眠脉冲
local PULSE_MUST_TAGS = { "_health" }
local PULSE_CANT_TAGS = {
    "brightmareboss",
    "brightmare",
    "DECOR",
    "epic",
    "FX",
    "ghost",
    "INLIMBO",
    "noauradamage",
    "playerghost",
}

local function DoGrogginessPulse(inst)
    if not inst.extended or not inst:IsValid() then
        return
    end
    
    local ix, iy, iz = inst.Transform:GetWorldPosition()
    local nearby_targets = TheSim:FindEntities(
        ix, iy, iz, TUNING.ALTERGUARDIAN_PHASE3_TRAP_AOERANGE or 3,
        PULSE_MUST_TAGS, PULSE_CANT_TAGS
    )

    for _, target in ipairs(nearby_targets) do
        if target.entity:IsVisible()
                and target.components.health ~= nil
                and not target.components.health:IsDead()
                and target.sg ~= nil then
            -- 催眠效果
            if target.components.grogginess ~= nil and not target.sg:HasStateTag("knockout") then
                target.components.grogginess:AddGrogginess(
                    TUNING.ALTERGUARDIAN_PHASE3_TRAP_GROGGINESS or 2, 
                    TUNING.ALTERGUARDIAN_PHASE3_TRAP_KNOCKOUTTIME or 4
                )
                if target.components.grogginess.knockoutduration == 0 then
                    target:PushEvent("attacked", {attacker = inst, damage = 0})
                    if target.components.sanity ~= nil then
                        target.components.sanity:DoDelta(TUNING.GESTALT_ATTACK_DAMAGE_SANITY or -10)
                    end
                end
            elseif target.components.sleeper ~= nil and not target.sg:HasStateTag("sleeping") then
                target.components.sleeper:AddSleepiness(
                    TUNING.ALTERGUARDIAN_PHASE3_TRAP_GROGGINESS or 2, 
                    TUNING.ALTERGUARDIAN_PHASE3_TRAP_KNOCKOUTTIME or 4
                )
                if not target.components.sleeper:IsAsleep() then
                    target:PushEvent("attacked", {attacker = inst, damage = 0})
                    if target.components.sanity ~= nil then
                        target.components.sanity:DoDelta(TUNING.GESTALT_ATTACK_DAMAGE_SANITY or -10)
                    end
                end
            elseif target:HasTag("shadowminion") then
                target:PushEvent("attacked", { attacker = inst, damage = 0 })
            end
        end
    end
end

local NUM_PULSE_LOOPS = 3               
local PULSE_TICK_TIME = 24 * FRAMES     
-- 稍微延长脉冲间隔
local START_CHARGE_TIME = 8.0           

local StartCharge
local StartPulse
local FinishPulse
local DoPulseTick
local ScheduleNextPulse

-- 开始充能
StartCharge = function(inst)
    if not inst.extended or not inst:IsValid() then
        return
    end
    
    inst.AnimState:PlayAnimation("meteor_charge")
    inst.AnimState:PushAnimation("meteor_idle", true)
    
    local charge_time = inst.AnimState:GetCurrentAnimationLength()
    if inst.charge_task then inst.charge_task:Cancel() end
    inst.charge_task = inst:DoTaskInTime(charge_time, function()
        if inst:IsValid() and inst.extended then
            StartPulse(inst)
        end
    end)
end

-- 结束脉冲
FinishPulse = function(inst)
    if not inst:IsValid() then return end
    
    if inst._pulse_fx ~= nil and inst._pulse_fx:IsValid() then
        inst._pulse_fx.AnimState:PlayAnimation("meteorground_pst")
        local pulse_pst_len = inst._pulse_fx.AnimState:GetCurrentAnimationLength()
        inst._pulse_fx:DoTaskInTime(pulse_pst_len, inst._pulse_fx.Hide)
    end
    
    inst.SoundEmitter:KillSound("trap_LP")
    
    if inst.pulse_tick_task then
        inst.pulse_tick_task:Cancel()
        inst.pulse_tick_task = nil
    end
    
    -- 随机延迟后下一次充能
    local next_charge_time = START_CHARGE_TIME + math.random() * 5  -- 8-13秒
    if inst.charge_task then inst.charge_task:Cancel() end
    inst.charge_task = inst:DoTaskInTime(next_charge_time, function()
        if inst:IsValid() and inst.extended then
            StartCharge(inst)
        end
    end)
end

-- 单次脉冲
DoPulseTick = function(inst)
    if not inst.extended or not inst:IsValid() then
        return
    end
    
    DoGrogginessPulse(inst)
    
    inst._pulse_count = (inst._pulse_count or 0) + 1
    
    if inst._pulse_count >= NUM_PULSE_LOOPS then
        FinishPulse(inst)
    else
        if inst.pulse_tick_task then inst.pulse_tick_task:Cancel() end
        inst.pulse_tick_task = inst:DoTaskInTime(PULSE_TICK_TIME, DoPulseTick)
    end
end

-- 开始脉冲
StartPulse = function(inst)
    if not inst.extended or not inst:IsValid() then
        return
    end
    
    inst.AnimState:PlayAnimation("meteor_idle", true)
    
    if inst._pulse_fx == nil or not inst._pulse_fx:IsValid() then
        inst._pulse_fx = SpawnPrefab("alterguardian_phase3trapgroundfx")
        inst._pulse_fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    else
        inst._pulse_fx:Show()
    end
    
    inst._pulse_fx.AnimState:PlayAnimation("meteorground_pre")
    local pulse_pre_len = inst._pulse_fx.AnimState:GetCurrentAnimationLength()
    
    inst._pulse_fx.AnimState:PushAnimation("meteorground_loop", true)
    local pulse_loop_len = inst._pulse_fx.AnimState:GetCurrentAnimationLength()
    
    inst.SoundEmitter:PlaySound("moonstorm/creatures/boss/alterguardian3/atk_trap_LP", "trap_LP")
    
    inst._pulse_count = 0
    
    if inst.pulse_tick_task then inst.pulse_tick_task:Cancel() end
    inst.pulse_tick_task = inst:DoTaskInTime(pulse_pre_len * 0.66, DoPulseTick)

    if inst.finish_pulse_task then inst.finish_pulse_task:Cancel() end
    inst.finish_pulse_task = inst:DoTaskInTime(pulse_pre_len + (pulse_loop_len * NUM_PULSE_LOOPS), FinishPulse)
end

-- 下一次脉冲周期
ScheduleNextPulse = function(inst)
    if not inst.extended or not inst:IsValid() then
        return
    end
    
    -- 随机延迟后开始充能
    local initial_delay = math.random() * START_CHARGE_TIME
    
    if inst.charge_task then
        inst.charge_task:Cancel()
    end
    
    inst.charge_task = inst:DoTaskInTime(initial_delay, function()
        if inst:IsValid() and inst.extended then
            StartCharge(inst)
        end
    end)
end

local function ExtendWall(inst)
    if inst.extended then
        return
    end
    inst.extended = true
    
    -- 先隐藏墙体，落下墙体动画结束后再显示
    inst:Hide()
    inst:AddTag("NOCLICK")
    
    local projectile = SpawnPrefab("alterguardian_phase3trapprojectile")
    if projectile then
        local x, y, z = inst.Transform:GetWorldPosition()
        projectile.Transform:SetPosition(x, y, z)
        projectile.AnimState:SetScale(1.5, 1.5)
        
        -- 清空anim监听器，防止它生成trap
        if projectile.event_listeners and projectile.event_listeners.animover then
            projectile.event_listeners.animover = nil
        end
        if projectile.event_listening and projectile.event_listening.animover then
            for source, fns in pairs(projectile.event_listening.animover) do
                if source and source.event_listeners and source.event_listeners.animover then
                    source.event_listeners.animover[projectile] = nil
                end
            end
            projectile.event_listening.animover = nil
        end
        
        -- 显示墙体
        projectile:ListenForEvent("animover", function()
            if inst:IsValid() then
                inst:Show()
                inst:RemoveTag("NOCLICK")
                
                if inst:IsAsleep() then
                    inst.AnimState:PlayAnimation("meteor_idle", true)
                    if inst.sfxlooper then
                        inst:PlayLoopingSFX()
                    end
                else
                    inst.AnimState:PlayAnimation("meteor_charge")
                    inst.AnimState:PushAnimation("meteor_idle", true)
                    inst.SoundEmitter:PlaySound("moonstorm/creatures/boss/alterguardian3/atk_traps")
                    
                    if inst.sfxlooper then
                        if inst.loopingsfxtask ~= nil then
                            inst.loopingsfxtask:Cancel()
                            inst.loopingsfxtask = nil
                        end
                        local anim_length = inst.AnimState:GetCurrentAnimationLength()
                        inst.loopingsfxtask = inst:DoTaskInTime(anim_length * 0.5, inst.PlayLoopingSFX)
                    end
                end
                
                if TheWorld.ismastersim then
                    ScheduleNextPulse(inst)
                end
            end
            projectile:Remove()
        end)
    else
        inst:Show()
        inst:RemoveTag("NOCLICK")
        
        if inst:IsAsleep() then
            inst.AnimState:PlayAnimation("meteor_idle", true)
            if inst.sfxlooper then
                inst:PlayLoopingSFX()
            end
        else
            inst.AnimState:PlayAnimation("meteor_charge")
            inst.AnimState:PushAnimation("meteor_idle", true)
            inst.SoundEmitter:PlaySound("moonstorm/creatures/boss/alterguardian3/atk_traps")
            
            if inst.sfxlooper then
                if inst.loopingsfxtask ~= nil then
                    inst.loopingsfxtask:Cancel()
                    inst.loopingsfxtask = nil
                end
                local anim_length = inst.AnimState:GetCurrentAnimationLength()
                inst.loopingsfxtask = inst:DoTaskInTime(anim_length * 0.5, inst.PlayLoopingSFX)
            end
        end
        
        if TheWorld.ismastersim then
            ScheduleNextPulse(inst)
        end
    end
end

local function RetractWall(inst)
    if not inst.extended then return end
    inst.extended = false
    inst:AddTag("NOCLICK")

    if inst.sfxlooper then
        inst:StopLoopingSFX()
    end
    
    if inst.charge_task then
        inst.charge_task:Cancel()
        inst.charge_task = nil
    end
    
    if inst.pulse_tick_task then
        inst.pulse_tick_task:Cancel()
        inst.pulse_tick_task = nil
    end
    
    if inst.finish_pulse_task then
        inst.finish_pulse_task:Cancel()
        inst.finish_pulse_task = nil
    end
    
    inst.SoundEmitter:KillSound("trap_LP")

    if inst._pulse_fx ~= nil and inst._pulse_fx:IsValid() then
        inst._pulse_fx:Remove()
        inst._pulse_fx = nil
    end
    
    -- 消失
    inst.AnimState:PlayAnimation("meteor_pst")
    if not inst:IsAsleep() then
        inst.SoundEmitter:PlaySound("turnoftides/common/together/moon_glass/mine")
    end
end


local function ExtendWallWithJitter(inst, jitter)
    inst:DoTaskInTime(math.random() * jitter, inst.ExtendWall)
end

local function RetractWallWithJitter(inst, jitter)
    inst:DoTaskInTime(math.random() * jitter, inst.RetractWall)
end


local function OnSave(inst, data)
    data.extended = inst.extended
    data.sfxlooper = inst.sfxlooper
end

local function OnLoad(inst, data)
    if data then
        inst.sfxlooper = data.sfxlooper
        if data.extended then
            inst.extended = false
            inst:ExtendWall()
        end
    end
end


local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.Transform:SetEightFaced()

    local success = pcall(function()
        inst.AnimState:SetBank("alterguardian_meteor")
        inst.AnimState:SetBuild("alterguardian_meteor")
        inst.AnimState:PlayAnimation("meteor_pre")
    end)
    
    if not success then
        inst.AnimState:SetBank("wagpunk_fence")
        inst.AnimState:SetBuild("wagpunk_cagewall")
        inst.AnimState:PlayAnimation("idle_off")
    end
    
    inst:AddTag("NOCLICK")
    inst:AddTag("FX")
    inst:AddTag("alterguardian_arenawall")
    inst:AddTag("moonglass")

    inst.entity:SetPristine()
    
    if not TheWorld.ismastersim then return inst end

    inst.persists = false

    inst:AddComponent("inspectable")
    inst.components.inspectable.nameoverride = "ALTERGUARDIAN_ARENA_WALL"

    inst.extended = false
    inst.sfxlooper = true 

    inst.ExtendWall = ExtendWall
    inst.RetractWall = RetractWall
    inst.ExtendWallWithJitter = ExtendWallWithJitter
    inst.RetractWallWithJitter = RetractWallWithJitter
    inst.PlayLoopingSFX = PlayLoopingSFX
    inst.StopLoopingSFX = StopLoopingSFX
    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

return Prefab("alterguardian_arenawall", fn, assets, prefabs)

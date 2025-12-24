-- WX78系统过载Buff

local function OnAttached(inst, target)
    inst.entity:SetParent(target.entity)
    inst.Transform:SetPosition(0, 0, 0)
    
    if not target._wx78_overload_original_speed then
        target._wx78_overload_original_speed = target.components.locomotor.runspeed
    end
    
    -- 增加移速30%
    local runspeed_bonus = 0.3
    target.components.locomotor.runspeed = TUNING.WILSON_RUN_SPEED * (1 + runspeed_bonus)
    
    -- 发光效果：过载buff独立提供3半径光源
    target._overload_light_bonus = 3
    
    if not target._light_modules or target._light_modules == 0 then
        -- 没有照明电路，创建新光源
        target.Light:Enable(true)
        target.Light:SetRadius(3)
        target.Light:SetFalloff(0.75)
        target.Light:SetIntensity(0.9)
        target.Light:SetColour(235/255, 121/255, 12/255) -- 橙色过载光
    else
        -- 已有照明电路，在原有基础上增加3半径
        local current_radius = target.Light:GetRadius()
        target.Light:SetRadius(current_radius + 3)
    end
    
    -- 温度最低值设置为10度
    if target.components.temperature then
        inst._saved_mintemp = target.components.temperature.mintemp
        target.components.temperature.mintemp = 10
    end
    
    -- 添加攻击带电效果
    if target.components.electricattacks == nil then
        target:AddComponent("electricattacks")
    end
    target.components.electricattacks:AddSource(inst)
    
    if inst._onattackother == nil then
        inst._onattackother = function(attacker, data)
            if data.weapon ~= nil then
                if data.projectile == nil then
                    if data.weapon.components.projectile ~= nil then
                        return
                    elseif data.weapon.components.complexprojectile ~= nil then
                        return
                    elseif data.weapon.components.weapon:CanRangedAttack() then
                        return
                    end
                end
                if data.weapon.components.weapon ~= nil and data.weapon.components.weapon.stimuli == "electric" then
                    return
                end
            end

            SpawnElectricHitSparks(data.projectile ~= nil and data.projectile:IsValid() and data.projectile or attacker, data.target, true)
        end
        inst:ListenForEvent("onattackother", inst._onattackother, target)
    end
    
    SpawnPrefab("electricchargedfx"):SetTarget(target)
    
    if target.AnimState then
        target.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    end
    
    if target.SoundEmitter then
        target.SoundEmitter:KillSound("overcharge_sound")
        target.SoundEmitter:PlaySound("dontstarve/characters/wx78/charged", "overcharge_sound")
        target.SoundEmitter:SetParameter("overcharge_sound", "intensity", 0.5)
    end
    
    if target.components.talker then
        target.components.talker:Say(TUNING.isCh2hm and "系统过载" or "SYSTEM OVERLOAD")
    end

    -- 过载时充满电量
    if target.components.upgrademoduleowner then
        local max_charge = target.components.upgrademoduleowner.max_charge or TUNING.WX78_MAXELECTRICCHARGE
        target.components.upgrademoduleowner:SetChargeLevel(max_charge)
    end
    
    -- 标记过载状态，阻止耗电
    if TUNING.DSTU and TUNING.DSTU.WXLESS then
        target._overload_no_drain2hm = true
    end

    -- 计算过载buff持续时间：每个电气化电路等级提供2分钟
    local overload_duration = TUNING.TOTAL_DAY_TIME  -- 默认8分钟
    if target.components.upgrademoduleowner then
        local total_taser_level = 0
        for _, module in ipairs(target.components.upgrademoduleowner.modules) do
            if module.prefab == "wx78module_taser" and module.level2hm then
                total_taser_level = total_taser_level + module.level2hm:value()
            end
        end
        if total_taser_level > 0 then
            overload_duration = total_taser_level * 120  -- 每级120秒
        end
    end
    
    inst.components.timer:StartTimer("buffover", overload_duration)
    
    inst:ListenForEvent("death", function()
        inst.components.debuff:Stop()
    end, target)
    
    -- 触发饥饿速率重新计算（因为过载状态下电气化电路槽位会翻倍）
    if target.components.upgrademoduleowner and target.components.upgrademoduleowner.UpdateActivatedModules then
        target.components.upgrademoduleowner:UpdateActivatedModules()
    end
end

local function OnExtended(inst, target)
    -- 重置计时器，刷新buff持续时间
    if inst.components.timer then
        inst.components.timer:StopTimer("buffover")
        
        -- 计算过载buff持续时间：每个电气化电路等级提供2分钟
        local overload_duration = TUNING.TOTAL_DAY_TIME  -- 默认8分钟
        if target.components.upgrademoduleowner then
            local total_taser_level = 0
            for _, module in ipairs(target.components.upgrademoduleowner.modules) do
                if module.prefab == "wx78module_taser" and module.level2hm then
                    total_taser_level = total_taser_level + module.level2hm:value()
                end
            end
            if total_taser_level > 0 then
                overload_duration = total_taser_level * 120  -- 每级120秒
            end
        end
        
        inst.components.timer:StartTimer("buffover", overload_duration)
    end
    
    -- 再次充满电量
    if target.components.upgrademoduleowner then
        local max_charge = target.components.upgrademoduleowner.max_charge or TUNING.WX78_MAXELECTRICCHARGE
        target.components.upgrademoduleowner:SetChargeLevel(max_charge)
    end
    
    -- 播放刷新提示
    if target and target:IsValid() then
        if target.components.talker then
            target.components.talker:Say(TUNING.isCh2hm and "系统过载" or "SYSTEM OVERLOAD")
        end
        
        -- 播放特效
        local fx = SpawnPrefab("wx78_big_spark")
        if fx then
            fx.Transform:SetPosition(target.Transform:GetWorldPosition())
        end
    end
end


local function OnDetach(inst, target)
    if inst.task then
        inst.task:Cancel()
        inst.task = nil
    end
    
    if target and target:IsValid() then
        if target._wx78_overload_original_speed and target.components.locomotor then
            target.components.locomotor.runspeed = target._wx78_overload_original_speed
            target._wx78_overload_original_speed = nil
        end
        
        -- 移除过载buff提供的光源（固定3半径）
        if target._overload_light_bonus then
            if not target._light_modules or target._light_modules == 0 then
                -- 没有照明电路，直接关闭光源
                target.Light:Enable(false)
            else
                -- 有照明电路，减去过载buff提供的3半径
                local current_radius = target.Light:GetRadius()
                target.Light:SetRadius(current_radius - 3)
            end
            -- 清除过载光源加成标记
            target._overload_light_bonus = nil
        end
        
        if target.components.temperature and inst._saved_mintemp then
            target.components.temperature.mintemp = inst._saved_mintemp
        end
        
        if target.components.electricattacks ~= nil then
            target.components.electricattacks:RemoveSource(inst)
        end
        if inst._onattackother ~= nil then
            inst:RemoveEventCallback("onattackother", inst._onattackother, target)
            inst._onattackother = nil
        end
        
        if target.AnimState then
            target.AnimState:SetBloomEffectHandle("")
        end
        
        if target.SoundEmitter then
            target.SoundEmitter:KillSound("overcharge_sound")
        end
        
        if target.components.talker then
            target.components.talker:Say(TUNING.isCh2hm and "已完全恢复系统" or "SYSTEMS FULLY RESTORED")
        end
        
        -- 重启妥协耗电
        if TUNING.DSTU and TUNING.DSTU.WXLESS then
            target._overload_no_drain2hm = nil
        end
        
        -- 触发饥饿速率重新计算（因为过载状态移除后电气化电路槽位恢复正常）
        if target.components.upgrademoduleowner and target.components.upgrademoduleowner.UpdateActivatedModules then
            target.components.upgrademoduleowner:UpdateActivatedModules()
        end
    end
    
    inst:Remove()
end

local function OnTimerDone(inst, data)
    if data.name == "buffover" then
        inst.components.debuff:Stop()
    end
end

local function fn()
    local inst = CreateEntity()

    if not TheWorld.ismastersim then
        inst:DoTaskInTime(0, inst.Remove)
        return inst
    end

    inst.entity:AddTransform()

    --[[Non-networked entity]]
    inst.entity:Hide()
    inst.persists = false

    inst:AddTag("CLASSIFIED")

    inst:AddComponent("debuff")
    inst.components.debuff:SetAttachedFn(OnAttached)
    inst.components.debuff:SetDetachedFn(OnDetach)
    inst.components.debuff:SetExtendedFn(OnExtended)
    inst.components.debuff.keepondespawn = true

    inst:AddComponent("timer")
    inst:ListenForEvent("timerdone", OnTimerDone)

    return inst
end

return Prefab("wx78_overload_buff2hm", fn)

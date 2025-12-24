-- 维持35度体温和防水4分钟
local function OnTick(inst, target)
    if target and target:IsValid() and target.components.temperature and target.components.moisture then
        if target.components.temperature:GetCurrent() ~= 35 then
            -- 持续生效需要设置优先级，保护其他的温度变化不被覆盖
            target.components.temperature:SetTemperature(35, 20)
        end
    else
        inst.components.debuff:Stop()
    end
end

local function OnDetach(inst, target)
    if target and target:IsValid() and target.components.moisture then
        target.components.moisture.waterproofnessmodifiers:RemoveModifier(inst)
    end
    inst:Remove()
end

local function OnAttached(inst, target)
    inst.entity:SetParent(target.entity)
    inst.Transform:SetPosition(0, 0, 0)
    
    -- 立即设置温度
    if target.components.temperature then
        target.components.temperature:SetTemperature(35, 20)
    end
    -- 添加100%防水
    if target.components.moisture then
        target.components.moisture.waterproofnessmodifiers:SetModifier(inst, 1.0)
        target.components.moisture:SetMoistureLevel(0)
    end
    
    inst.task = inst:DoPeriodicTask(1, OnTick, nil, target)
    
    inst.components.timer:StartTimer("buffover", 240)
    
    inst:ListenForEvent("death", function()
        inst.components.debuff:Stop()
    end, target)
end

local function OnExtended(inst, target)
    -- 重置计时器
    inst.components.timer:StopTimer("buffover")
    inst.components.timer:StartTimer("buffover", 240)
end

local function OnTimerDone(inst, data)
    if data.name == "buffover" then
        inst.components.debuff:Stop()
    end
end

local function fn()
    local inst = CreateEntity()

    if not TheWorld.ismastersim then
        --Not meant for client!
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

STRINGS.NAMES[string.upper("book_temperature_buff2hm")] = "控温学"

return Prefab("book_temperature_buff2hm", fn)

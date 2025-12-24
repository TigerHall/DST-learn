-- 夜视buff - 夜莓慕斯专用的长时间夜视效果

-- 色彩方案 
local NIGHTVISION_COLOURCUBES = {
    day = "images/colour_cubes/nightvision_fruit_cc.tex",
    dusk = "images/colour_cubes/nightvision_fruit_cc.tex",
    night = "images/colour_cubes/nightvision_fruit_cc.tex",
    full_moon = "images/colour_cubes/nightvision_fruit_cc.tex",

    nightvision_fruit = true,
}

-- 夜视环境光设置 
local NIGHTVISION_AMBIENT_COLOURS = {
	default = { colour = Vector3(255/255, 175/255, 255/255) },
	fixedcolour = true,
}

local function OnAttached(inst, target)
    inst.entity:SetParent(target.entity)
    inst.Transform:SetPosition(0, 0, 0)

    inst:ListenForEvent("death", function()
        inst.components.debuff:Stop()
    end, target)

    -- 给予夜视效果
    if target.components.playervision ~= nil then
        target.components.playervision:PushForcedNightVision(inst, 1, NIGHTVISION_COLOURCUBES, true, NIGHTVISION_AMBIENT_COLOURS)
        inst._enabled:set(true)
    end

    -- 理智减益减半 (原版夜莓是-TUNING.DAPPERNESS_MED_LARGE，慕斯减半)
    if target.components.sanity ~= nil then
        target.components.sanity.externalmodifiers:SetModifier(inst, -TUNING.DAPPERNESS_MED_LARGE / 2)
    end
end

local function OnDetached(inst, target)
    if target ~= nil and target:IsValid() then
        if target.components.playervision ~= nil then
            target.components.playervision:PopForcedNightVision(inst)
            inst._enabled:set(false)
        end

        if target.components.sanity ~= nil then
            target.components.sanity.externalmodifiers:RemoveModifier(inst)
        end
    end

    inst:DoTaskInTime(10*FRAMES, inst.Remove)
end

local function OnExpire(inst)
    inst.components.debuff:Stop()
end

local function OnExtended(inst)
    if inst.task ~= nil then
        inst.task:Cancel()
        inst.task = nil
    end

    -- 持续时间为两天 (2 * TUNING.TOTAL_DAY_TIME)
    local duration = 2 * TUNING.TOTAL_DAY_TIME
    inst.task = inst:DoTaskInTime(duration, OnExpire)
end

local function OnSave(inst, data)
    if inst.task ~= nil then
        data.remaining = GetTaskRemaining(inst.task)
    end
end

local function OnLoad(inst, data)
    if data == nil then
        return
    end

    if data.remaining then
        if inst.task ~= nil then
            inst.task:Cancel()
            inst.task = nil
        end

        inst.task = inst:DoTaskInTime(data.remaining, OnExpire)
    end
end

local function OnLongUpdate(inst, dt)
    if inst.task == nil then
        return
    end

    local remaining = GetTaskRemaining(inst.task) - dt

    inst.task:Cancel()

    if remaining > 0 then
        inst.task = inst:DoTaskInTime(remaining, OnExpire)
    else
        OnExpire(inst)
    end
end

local function OnEnabledDirty(inst)
    if ThePlayer ~= nil and inst.entity:GetParent() == ThePlayer and ThePlayer.components.playervision ~= nil then
        if inst._enabled:value() then
            ThePlayer.components.playervision:PushForcedNightVision(inst, 1, NIGHTVISION_COLOURCUBES, true, NIGHTVISION_AMBIENT_COLOURS)
        else
            ThePlayer.components.playervision:PopForcedNightVision(inst)
        end
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    inst:AddTag("CLASSIFIED")

    inst._enabled = net_bool(inst.GUID, "nightvisionbuff2hm._enabled", "enableddirty")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        inst:ListenForEvent("enableddirty", OnEnabledDirty)
        return inst
    end

    inst.entity:Hide()
    inst.persists = false

    inst:AddComponent("debuff")
    inst.components.debuff:SetAttachedFn(OnAttached)
    inst.components.debuff:SetDetachedFn(OnDetached)
    inst.components.debuff:SetExtendedFn(OnExtended)
    inst.components.debuff.keepondespawn = true

    OnExtended(inst)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
    inst.OnLongUpdate = OnLongUpdate

    return inst
end

-- 设置buff名称
if TUNING.isCh2hm then
    STRINGS.NAMES[string.upper("nightvisionbuff2hm")] = "强化夜视"
else
    STRINGS.NAMES[string.upper("nightvisionbuff2hm")] = "Enhanced Night Vision"
end

return Prefab("nightvisionbuff2hm", fn)

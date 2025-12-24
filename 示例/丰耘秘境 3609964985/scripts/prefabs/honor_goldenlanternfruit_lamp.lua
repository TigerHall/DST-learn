local prefabs =
{
    "collapse_small",
}

local light_str =
{
    {radius = 2.5, falloff = .85, intensity = 0.75},
    {radius = 3.25, falloff = .85, intensity = 0.75},
    {radius = 4.25, falloff = .85, intensity = 0.75},
    {radius = 5.5, falloff = .85, intensity = 0.75},
}

local sounds =
{
    toggle = "dontstarve/common/together/mushroom_lamp/lantern_2_on",
    colour = "dontstarve/common/together/mushroom_lamp/change_colour",
    craft = "dontstarve/common/together/mushroom_lamp/craft_2",
}

local function IsLightOn(inst)
    return inst.Light:IsEnabled()
end

local function TurnOnLamp(inst)
    if not IsLightOn(inst) then
        inst.Light:Enable(true)
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        inst.AnimState:SetSymbolBloom("lampshade")
    end
    inst.AnimState:SetMultColour(.5, .5, .5, 1)
    inst.AnimState:SetLightOverride(0.8)
    inst:AddTag("daylight")

    if inst._hide_glow_task ~= nil then
        inst._hide_glow_task:Cancel()
        inst._hide_glow_task = nil
    end
    inst.AnimState:Show("glow")

    if POPULATING then
        inst.AnimState:PlayAnimation("idle_loop", true)
    else
        inst.AnimState:PlayAnimation("turn_on")
        inst.AnimState:PushAnimation("idle_loop", true)
        inst.SoundEmitter:PlaySound(sounds.toggle)
    end
end

local function HideGlowSymbol(inst)
    inst.AnimState:Hide("glow")
end

local function TurnOffLamp(inst)
    if IsLightOn(inst) then
        inst.Light:Enable(false)
        inst.AnimState:ClearBloomEffectHandle()
        inst.AnimState:ClearSymbolBloom("lampshade")
    end
    inst.AnimState:SetMultColour(.7, .7, .7, 1)
    inst.AnimState:SetLightOverride(0)
    inst:RemoveTag("daylight")

    if POPULATING then
        inst.AnimState:Hide("glow")
        inst.AnimState:PlayAnimation("idle", false)
    else
        inst.AnimState:PlayAnimation("turn_off")

        local delay = inst.AnimState:GetCurrentAnimationLength() - 0.1
        inst._hide_glow_task = inst:DoTaskInTime(delay, HideGlowSymbol)

        inst.AnimState:PushAnimation("idle", false)

        inst.SoundEmitter:PlaySound(sounds.toggle)
    end
end

local function ClearSoundQueue(inst)
    if inst._soundtask ~= nil then
        inst._soundtask:Cancel()
        inst._soundtask = nil
    end
end

local function IsBatteryType(item)
    -- return item:HasTag("goldenlanternfruit_prime")
    return true
end

local function UpdateLightState(inst)
    if inst:HasTag("burnt") then
        return
    end

    ClearSoundQueue(inst)

    local num_batteries = #inst.components.container:FindItems(IsBatteryType)

    if num_batteries > 0 then
        inst.Light:SetRadius(light_str[num_batteries].radius)
        inst.Light:SetFalloff(light_str[num_batteries].falloff)
        inst.Light:SetIntensity(light_str[num_batteries].intensity)

        inst:TurnOnLamp()
    else
        inst:TurnOffLamp()
    end
end

local function OnWorkFinished(inst)
    inst.components.lootdropper:DropLoot()
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("wood")
    if inst.components.container ~= nil then
        inst.components.container:DropEverything()
    end
    inst:Remove()
end

local function OnWorked(inst, worker, workleft)
    if workleft > 0 and not inst:HasTag("burnt") then
        ClearSoundQueue(inst)
        inst.AnimState:PlayAnimation("hit")
        if IsLightOn(inst) then
            inst.AnimState:PushAnimation("idle_loop", true)
        else
            inst.AnimState:PushAnimation("idle", false)
        end

        if inst.components.container ~= nil then
            inst.components.container:DropEverything()
            inst.components.container:Close()
        end
    end
end

local function OnBuilt(inst)
    ClearSoundQueue(inst)
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("idle_loop", true)
    inst.SoundEmitter:PlaySound(sounds.craft)
end

local function GetStatus(inst)
    return (inst:HasTag("burnt") and "BURNT")
           or (IsLightOn(inst) and "ON")
           or "OFF"
end

local function OnSave(inst, data)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() or inst:HasTag("burnt") then
        data.burnt = true
    end
end

local function OnLoad(inst, data)
    if data ~= nil and data.burnt then
        inst.components.burnable.onburnt(inst)
    end
end

local assets =
{
    Asset("ANIM", "anim/honor_goldenlanternfruit_lamp.zip"),
    Asset("ANIM", "anim/ui_lamp_1x4.zip"),
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    inst:SetDeploySmartRadius(0.5) --recipe min_spacing/2

    MakeObstaclePhysics(inst, .25)

    inst.AnimState:SetBank("honor_goldenlanternfruit_lamp")
    inst.AnimState:SetBuild("honor_goldenlanternfruit_lamp")
    inst.AnimState:PlayAnimation("idle_loop", true)

    inst.Light:SetColour(.65, .65, .5)
    inst.Light:Enable(false)

    inst:AddTag("structure")
    inst:AddTag("lamp")

    MakeSnowCoveredPristine(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(3)
    inst.components.workable:SetOnFinishCallback(OnWorkFinished)
    inst.components.workable:SetOnWorkCallback(OnWorked)

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus

    inst:AddComponent("lootdropper")

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("honor_goldenlanternfruit_lamp")

    inst:AddComponent("preserver")
    inst.components.preserver:SetPerishRateMultiplier(TUNING.PERISH_MUSHROOM_LIGHT_MULT)

    inst:ListenForEvent("onbuilt", OnBuilt)
    inst:ListenForEvent("itemget", UpdateLightState)
    inst:ListenForEvent("itemlose", UpdateLightState)
    inst:ListenForEvent("burntup", ClearSoundQueue)

    inst:DoTaskInTime(0, UpdateLightState)

    MakeSmallBurnable(inst, nil, nil, true)
    MakeSmallPropagator(inst)
    MakeHauntableWork(inst)
    MakeSnowCovered(inst)

    inst.TurnOnLamp = TurnOnLamp
    inst.TurnOffLamp = TurnOffLamp
    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

return Prefab("honor_goldenlanternfruit_lamp", fn, assets, prefabs),
       MakePlacer("honor_goldenlanternfruit_lamp_placer", "honor_goldenlanternfruit_lamp", "honor_goldenlanternfruit_lamp", "idle")

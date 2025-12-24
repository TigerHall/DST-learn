-- 眼球炮塔AOE冲击波特效
local assets =
{
    Asset("ANIM", "anim/mushroombomb_base.zip"),
}

local function PlayShockwaveAnim(proxy)
    local inst = CreateEntity()

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    inst.Transform:SetFromProxy(proxy.GUID)

    inst.AnimState:SetBank("mushroombomb_base")
    inst.AnimState:SetBuild("mushroombomb_base")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)
    inst.AnimState:SetFinalOffset(3)
    inst.AnimState:SetScale(1.52, 1.52)             -- 0.8 * 1.9 = 1.52
    
    -- 读取代理实体的颜色数据
    if proxy.color_r and proxy.color_g and proxy.color_b then
        inst.AnimState:SetMultColour(proxy.color_r:value(), proxy.color_g:value(), proxy.color_b:value(), .5)
    else
        inst.AnimState:SetMultColour(0, 0, 0, .5)
    end

    inst:ListenForEvent("animover", inst.Remove)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    -- 传递网络变量的颜色数据
    inst.color_r = net_float(inst.GUID, "eyeturret_shockwave_fx.color_r")
    inst.color_g = net_float(inst.GUID, "eyeturret_shockwave_fx.color_g")
    inst.color_b = net_float(inst.GUID, "eyeturret_shockwave_fx.color_b")
    
    inst.color_r:set(0)
    inst.color_g:set(0)
    inst.color_b:set(0)

    --Dedicated server does not need to spawn the local fx
    if not TheNet:IsDedicated() then
        --Delay one frame so that we are positioned properly before starting the effect
        inst:DoTaskInTime(0, PlayShockwaveAnim)
    end

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false
    inst:DoTaskInTime(1, inst.Remove)  

    return inst
end

return Prefab("eyeturret_shockwave_fx", fn, assets)

local assets = {
-- 
	Asset("ANIM", "anim/tbat_sfx_butterflies_explode.zip"),

}


local function fx()
    local inst = CreateEntity()

    inst.entity:AddSoundEmitter()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    -- inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetBank("fx_moon_tea")
    inst.AnimState:SetBuild("tbat_sfx_butterflies_explode")
    inst.AnimState:PlayAnimation("puff", false)

    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

    inst:AddTag("INLIMBO")
    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    inst:AddTag("NOBLOCK")
    inst:DoTaskInTime(0,function ()
        inst.SoundEmitter:PlaySound("dontstarve/common/fireAddFuel")
    end)

    inst:ListenForEvent("animover",inst.Remove)

    inst.entity:SetPristine()
    inst.persists = false   --- 是否留存到下次存档加载。

    if not TheWorld.ismastersim then
        return inst
    end

    return inst
end

return Prefab("tbat_sfx_butterflies_explode",fx,assets)
local assets = {

	Asset("ANIM", "anim/tbat_sfx_flame.zip"),  -- 动画 size_10  ->  size_1 :   1 -> 0.1
}


local function fx()
    local inst = CreateEntity()

    inst.entity:AddSoundEmitter()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    -- inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetBank("tbat_sfx_flame")
    inst.AnimState:SetBuild("tbat_sfx_flame")
    inst.AnimState:PlayAnimation("red", true)
    inst.AnimState:SetFinalOffset(1)


    inst:AddTag("INLIMBO")
    inst:AddTag("FX")
    inst:AddTag("NOCLICK")


    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    return inst
end

return Prefab("tbat_sfx_flame",fx,assets)
local assets = {
-- 
	Asset("ANIM", "anim/tbat_sfx_maple_leaves_and_flames.zip"),

}


local function fx()
    local inst = CreateEntity()

    inst.entity:AddSoundEmitter()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    -- inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetBank("deer_ice_flakes")
    inst.AnimState:SetBuild("tbat_sfx_maple_leaves_and_flames")
    inst.AnimState:PlayAnimation("idle", true)

    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetFinalOffset(1)

    inst:AddTag("INLIMBO")
    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    inst:AddTag("NOBLOCK")


    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    return inst
end

return Prefab("tbat_sfx_maple_leaves_and_flames",fx,assets)
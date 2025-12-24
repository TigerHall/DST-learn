
local function fn_shield()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
    inst:AddTag('NOCLICK')
    inst:AddTag('NOBLOCK')
    inst.AnimState:SetBank("tbat_item_crystal_bubble")
    inst.AnimState:SetBuild("tbat_item_crystal_bubble")
    inst.AnimState:PlayAnimation("big", true)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    return inst
end
return Prefab("tbat_crystal_bubble_fx", fn_shield, { Asset("ANIM", "anim/tbat_item_crystal_bubble.zip") })

local assets =
{
    Asset("ANIM", "anim/honor_kit.zip"),
    Asset("ATLAS", "images/inventoryimages/honor_kit.xml"),
    Asset("IMAGE", "images/inventoryimages/honor_kit.tex"),
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("honor_kit")
    inst.AnimState:SetBuild("honor_kit")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("honor_kit")
    inst:AddTag("hmr_kit")

    MakeInventoryFloatable(inst, "small", 0.2, { 1.4, 1, 1 })

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_LARGEITEM

    inst:AddComponent("hrepair")
    inst.components.hrepair:SetRepairTag("HONOR")
    inst.components.hrepair:SetRepairAbility(80)

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/honor_kit.xml"

    MakeHauntableLaunch(inst)

    return inst
end


return Prefab("honor_kit", fn, assets)
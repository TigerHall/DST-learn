local assets =
{
    Asset("ANIM", "anim/firefighter_projectile.zip"),
    Asset("ATLAS", "images/inventoryimages/aab_firesuppressor_orient.xml"),
    Asset("ATLAS_BUILD", "images/inventoryimages/aab_firesuppressor_orient.xml", 256), --小木牌和展柜使用
}

RegisterInventoryItemAtlas("images/inventoryimages/aab_firesuppressor_orient.xml", "aab_firesuppressor_orient.tex")

local function Setup(inst, owner)
    inst.owner = owner
    inst:ListenForEvent("onremove", function() inst:Remove() end, owner)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)

    inst.AnimState:SetBank("firefighter_projectile")
    inst.AnimState:SetBuild("firefighter_projectile")
    inst.AnimState:PlayAnimation("spin_loop")
    inst.AnimState:Pause()

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.owner = nil
    inst.Setup = Setup

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/aab_firesuppressor_orient.xml"

    return inst
end

return Prefab("aab_firesuppressor_orient", fn, assets)

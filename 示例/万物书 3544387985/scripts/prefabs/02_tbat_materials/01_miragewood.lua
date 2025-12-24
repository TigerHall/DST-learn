local assets =
{
    Asset("ANIM", "anim/tbat_material_miragewood.zip"),
}
local function shadow_init(inst)
    if inst:IsOnOcean(false) then       --- 如果在海里（不包括船）
        inst.AnimState:PlayAnimation("water")
    else                                
        inst.AnimState:PlayAnimation("idle")
    end
end
local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    MakeInventoryPhysics(inst)
    inst.AnimState:SetBank("tbat_material_miragewood")
    inst.AnimState:SetBuild("tbat_material_miragewood")
    inst.AnimState:PlayAnimation("idle")
    inst:AddTag("log")
    inst.pickupsound = "wood"
    MakeInventoryFloatable(inst, "med", 0.05, {0.85, 0.45, 0.85})
    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end
    inst:AddComponent("tradable")
	inst:AddComponent("edible")
    inst.components.edible.foodtype = FOODTYPE.WOOD
    inst.components.edible.healthvalue = 0
    inst.components.edible.hungervalue = 0
    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.MED_FUEL
    MakeSmallBurnable(inst, TUNING.MED_BURNTIME)
    MakeSmallPropagator(inst)
    MakeHauntableLaunchAndIgnite(inst)
    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:TBATInit("tbat_material_miragewood","images/inventoryimages/tbat_material_miragewood.xml")
    inst:AddComponent("stackable")
    inst:AddComponent("repairer")
    inst.components.repairer.repairmaterial = MATERIALS.WOOD
    inst.components.repairer.healthrepairvalue = TUNING.REPAIR_LOGS_HEALTH
    inst:ListenForEvent("on_landed",shadow_init)
    return inst
end

return Prefab("tbat_material_miragewood", fn, assets)

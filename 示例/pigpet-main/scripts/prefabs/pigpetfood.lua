local assets=
{
    Asset("ANIM", "anim/pigpetfood.zip"),
}

local function common(inst)
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    
    MakeInventoryPhysics(inst)
    inst:AddComponent("edible") 
    inst.components.edible.foodtype = "PigPet"
    
    inst:AddComponent("stackable")
    
    inst:AddComponent("inspectable")
    
    inst:AddComponent("inventoryitem")

    return inst
end

local function fn(Sim)
	local inst = common()
    inst.AnimState:SetBank("pigpetfood")
    inst.AnimState:SetBuild("pigpetfood")
    inst.AnimState:PlayAnimation("idle")
    inst.components.edible.healthvalue = 20
    
    inst.components.inventoryitem.atlasname = "images/inventoryimages/pigpetfood.xml" 

    inst:AddComponent("tradable") 
    
    return inst
end

return Prefab( "common/pigpetfood", fn, assets) 
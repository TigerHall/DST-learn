--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[


]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local assets =
    {
        Asset("ANIM", "anim/tbat_material_liquid_of_maple_leaves.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local function shadow_init(inst)
        if inst:IsOnOcean(false) then       --- 如果在海里（不包括船）
            inst.AnimState:PlayAnimation("item_water")
        else
            inst.AnimState:PlayAnimation("item")
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()
        MakeInventoryPhysics(inst)
        inst.AnimState:SetBank("tbat_material_liquid_of_maple_leaves")
        inst.AnimState:SetBuild("tbat_material_liquid_of_maple_leaves")
        inst.AnimState:PlayAnimation("item")
        MakeInventoryFloatable(inst, "med", 0.05, {0.85, 0.45, 0.85})
        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end
        inst:AddComponent("inspectable")
        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem:TBATInit("tbat_material_liquid_of_maple_leaves","images/inventoryimages/tbat_material_liquid_of_maple_leaves.xml")
        inst:AddComponent("stackable")
        inst.components.stackable.maxsize = TUNING.STACK_SIZE_LARGEITEM
        inst:ListenForEvent("on_landed",shadow_init)
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab("tbat_material_liquid_of_maple_leaves", fn, assets)

local prefs = {}

local function MakeNaturalMaterial(name, data)
    local assets =
    {
        Asset("ANIM", "anim/hmr_naturalmaterials.zip"),
    }

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)

        inst.AnimState:SetBank("hmr_naturalmaterials")
        inst.AnimState:SetBuild("hmr_naturalmaterials")
        inst.AnimState:PlayAnimation(name)

        MakeInventoryFloatable(inst, "small", .1)

        if data.common_postinit ~= nil then
            data.common_postinit(inst)
        end

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("inspectable")
        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.atlasname = "images/inventoryimages/"..name..".xml"
        inst.components.inventoryitem.imagename = name

        inst:AddComponent("stackable")
        inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

        inst:AddComponent("tradable")

        MakeHauntableLaunch(inst)

        return inst
    end

    table.insert(prefs, Prefab(name, fn, assets))
end

-- 自然辉煌
MakeNaturalMaterial("honor_splendor", {})

-- 植物纤维
MakeNaturalMaterial("honor_plantfibre", {})

-- 自然凶险
MakeNaturalMaterial("terror_dangerous", {})

-- 恐怖粘液
MakeNaturalMaterial("terror_mucous", {
    common_postinit = function(inst)
        inst:AddTag("terror_staff_consumable")
    end,
})

return unpack(prefs)
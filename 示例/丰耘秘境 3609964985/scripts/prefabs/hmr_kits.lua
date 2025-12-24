local prefs = {}

local function MakeKit(name, data)
    local assets =
    {
        Asset("ANIM", "anim/"..name..".zip"),
    }

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)

        inst.AnimState:SetBank(name)
        inst.AnimState:SetBuild(name)
        inst.AnimState:PlayAnimation("idle")

        inst:AddTag(name)

        MakeInventoryFloatable(inst, "small", 0.2, { 1.4, 1, 1 })

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("stackable")
        inst.components.stackable.maxsize = TUNING.STACK_SIZE_LARGEITEM

        inst:AddComponent("hmrrepairer")
        inst.components.hmrrepairer:SetRepairTag(data.repair_tag)
        inst.components.hmrrepairer:SetRepairAbility(data.repair_ability)

        inst:AddComponent("inspectable")

        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.atlasname = "images/inventoryimages/"..name..".xml"

        MakeHauntableLaunch(inst)

        return inst
    end

    table.insert(prefs, Prefab(name, fn, assets))
end

MakeKit("honor_kit", {
    repair_tag = "HONOR",
    repair_ability = 500,
})
MakeKit("terror_kit", {
    repair_tag = "TERROR",
    repair_ability = 600,
})

return unpack(prefs)
local function MakeSpice(name)
    local assets =
    {
        Asset("ANIM", "anim/hmr_spices.zip"),
        Asset("ATLAS", "images/inventoryimages/"..name..".xml"),
        Asset("IMAGE", "images/inventoryimages/"..name..".tex"),
    }

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)

        inst.AnimState:SetBank("hmr_spices")
        inst.AnimState:SetBuild("hmr_spices")
        inst.AnimState:PlayAnimation(name)

        inst:AddTag("spice")

        MakeInventoryFloatable(inst, "med", nil, 0.7)

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("stackable")
        inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

        inst:AddComponent("inspectable")

        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.imagename = name
        inst.components.inventoryitem.atlasname = "images/inventoryimages/"..name..".xml"

        MakeHauntableLaunch(inst)

        return inst
    end

    return Prefab(name, fn, assets)
end

local SPICES = {}
local spice_names = require("hmrmain/hmr_lists").SPICE_DATA_LIST

for name, data in pairs(spice_names) do
    if data.source ~= nil and data.source == "hmr" then
        table.insert(SPICES, MakeSpice(data.product))
    end
end

return unpack(SPICES)
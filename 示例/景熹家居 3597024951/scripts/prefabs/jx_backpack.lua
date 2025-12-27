local assets =
{
    Asset("ANIM", "anim/backpack.zip"),
    Asset("ANIM", "anim/jx_backpack_build.zip"),
    Asset("ANIM", "anim/ui_backpack_2x4.zip"),
}

local prefabs =
{
  "ash",
}

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_body", "jx_backpack_build", "swap_body")

    if inst.components.container ~= nil then
        inst.components.container:Open(owner)
    end
end

local function onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_body")
    owner.AnimState:ClearOverrideSymbol("backpack")
    if inst.components.container ~= nil then
        inst.components.container:Close(owner)
    end
end

local function onequiptomodel(inst, owner, from_ground)
    if inst.components.container ~= nil then
        inst.components.container:Close(owner)
    end
end

--[[local function onburnt(inst)
    if inst.components.container ~= nil then
        inst.components.container:DropEverything()
        inst.components.container:Close()
    end

    SpawnPrefab("ash").Transform:SetPosition(inst.Transform:GetWorldPosition())

    inst:Remove()
end

local function onignite(inst)
    if inst.components.container ~= nil then
        inst.components.container.canbeopened = false
    end
end

local function onextinguish(inst)
    if inst.components.container ~= nil then
        inst.components.container.canbeopened = true
    end
end]]

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("backpack1")
    inst.AnimState:SetBuild("jx_backpack_build")
    inst.AnimState:PlayAnimation("anim")

    inst:AddTag("backpack")

    inst.MiniMapEntity:SetIcon("jx_backpack.tex")

    inst.foleysound = "dontstarve/movement/foley/backpack"

    MakeInventoryFloatable(inst, "small", 0.2, nil, nil, nil, {bank = "backpack1", anim = "anim"})

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.cangoincontainer = false

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.BACK or EQUIPSLOTS.BODY
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst.components.equippable:SetOnEquipToModel(onequiptomodel)
    
    inst:AddComponent("insulator")
    inst.components.insulator:SetInsulation(TUNING.INSULATION_SMALL)

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("jx_backpack")
    --inst.components.container:EnableInfiniteStackSize(true)

    --MakeSmallBurnable(inst)
    --MakeSmallPropagator(inst)
    --inst.components.burnable:SetOnBurntFn(onburnt)
    --inst.components.burnable:SetOnIgniteFn(onignite)
    --inst.components.burnable:SetOnExtinguishFn(onextinguish)

    MakeHauntableLaunchAndDropFirstItem(inst)

    return inst
end

return Prefab("jx_backpack", fn, assets, prefabs)
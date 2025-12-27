local assets =
{
    Asset("ANIM", "anim/jx_phonograph.zip"),
}

local prefabs =
{
    "record",
}

local function OnHaunted(inst)
    inst.use_count = inst.use_count + 1
    if inst.use_count >= 3 then
        local fx = SpawnPrefab("collapse_small")
        fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
        fx:SetMaterial("glass")

        inst:Remove()
    end
    return true
end

local function OnLoad(inst, data)
    inst.use_count = data and data.use_count or 0
end

local function OnSave(inst, data)
    data.use_count = inst.use_count
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddFollower()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst.MiniMapEntity:SetIcon("jx_phonograph.tex")

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("jx_phonograph")
    inst.AnimState:SetBuild("jx_phonograph")
    inst.AnimState:PlayAnimation("idle", false)

    inst:AddTag("furnituredecor")

    MakeInventoryFloatable(inst, "med", 0.07, 0.72)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.use_count = 0

    inst:AddComponent("furnituredecor")

    inst:AddComponent("inspectable")

    inst:AddComponent("inventory")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/jx_phonograph.xml"

    inst:AddComponent("lootdropper")

    local workable = inst:AddComponent("workable")
    workable:SetWorkAction(ACTIONS.HAMMER)
    workable:SetWorkLeft(1)
    workable:SetOnFinishCallback(inst.OnHammered)

    inst.OnLoad = OnLoad
    inst.OnSave = OnSave

    MakeHauntable(inst)
    inst.components.hauntable:SetOnHauntFn(OnHaunted)
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_INSTANT_REZ)

    return inst
end

return Prefab("jx_phonograph", fn, assets, prefabs)

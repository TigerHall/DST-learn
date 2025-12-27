local assets =
{
    Asset("ANIM", "anim/ui_jx_rug_bag_5x5.zip"),
    Asset("ANIM", "anim/jx_rug_bag.zip"),
}

local prefabs =
{
}

local SOUNDS =
{
    open  = "meta5/wendy/basket_open",
    close = "meta5/wendy/basket_close",
}

local function OnOpen(inst)
    if inst:HasTag("burnt") then
        return
    end
    inst.AnimState:PlayAnimation("opened", false)
    inst.SoundEmitter:PlaySound(inst._sounds.open)
end

local function OnClose(inst)
    if inst:HasTag("burnt") then
        return
    end
    inst.AnimState:PlayAnimation("closed", false)
    inst.SoundEmitter:PlaySound(inst._sounds.close)
end

local function OnPutInInventory(inst)
    inst.components.container:Close()
    inst.AnimState:PlayAnimation("closed", false)
end

--[[local function OnBurnt(inst)
    inst.components.container:DropEverything()
    DefaultBurntFn(inst)
end]]

local function OnSave(inst, data)
    if (inst.components.burnable ~= nil and inst.components.burnable:IsBurning()) or inst:HasTag("burnt") then
        data.burnt = true
    end
end

local function OnLoad(inst, data)
    if data ~= nil and data.burnt and inst.components.burnable ~= nil then
        inst.components.burnable.onburnt(inst)
    end
end

local FLOATABLE_SWAP_DATA = { bank = "jx_rug_bag", anim = "closed" }
local FLOATABLE_SCALE = { 1.35, 1, 1.35 }

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst.MiniMapEntity:SetIcon("jx_rug_bag.tex")

    inst.AnimState:SetBank("jx_rug_bag")
    inst.AnimState:SetBuild("jx_rug_bag")
    inst.AnimState:PlayAnimation("closed")
    --inst.AnimState:SetScale(.75, .75, .75)

    MakeInventoryPhysics(inst)

    MakeInventoryFloatable(inst, "small", 0.3, FLOATABLE_SCALE, nil, nil, FLOATABLE_SWAP_DATA)

    inst.entity:SetPristine()

    inst:AddTag("portablestorage")--"便携容器",与角色打开时状态机有关，指向"搜寻"动作RUMMAGE

    if not TheWorld.ismastersim then
        return inst
    end

    inst._sounds = SOUNDS

    inst:AddComponent("inspectable")
    inst:AddComponent("lootdropper")

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("jx_rug_bag")
    inst.components.container.onopenfn = OnOpen
    inst.components.container.onclosefn = OnClose
    inst.components.container.skipclosesnd = true
    inst.components.container.skipopensnd = true
    inst.components.container.droponopen = true

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:SetOnPutInInventoryFn(OnPutInInventory)

    --MakeSmallBurnable(inst)
    --MakeMediumPropagator(inst)
    --inst.components.burnable:SetOnBurntFn(OnBurnt)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    MakeHauntableLaunchAndDropFirstItem(inst)

    return inst
end

return Prefab("jx_rug_bag", fn, assets, prefabs)
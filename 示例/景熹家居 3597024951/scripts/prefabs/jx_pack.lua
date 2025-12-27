local assets =
{
    Asset("ANIM", "anim/jx_pack.zip"),
}

local sounds =
{
	open = "wintersfeast2019/winters_feast/table/place",
	close = "dontstarve/common/together/packaged",
}

local function OnOpen(inst)
  inst.SoundEmitter:PlaySound(sounds.open)
  inst.AnimState:PlayAnimation("idle_on")
end

local function OnClose(inst)
  inst.SoundEmitter:PlaySound(sounds.close)
  inst.AnimState:PlayAnimation("idle_off")
end

local function Close(inst)
    inst.components.container:Close()
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("jx_pack")
    inst.AnimState:SetBuild("jx_pack")
    inst.AnimState:PlayAnimation("idle_off")

    inst.MiniMapEntity:SetIcon("jx_pack.tex")
    
    inst:AddTag("jx_pack")

    MakeInventoryFloatable(inst, "small", 0.2, nil, nil, nil, {bank = "jx_pack", anim = "jx_pack"})

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:SetOnPutInInventoryFn(Close)
    inst.components.inventoryitem:SetOnDroppedFn(Close)

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("jx_pack")
    inst.components.container.onopenfn = OnOpen
    inst.components.container.onclosefn = OnClose
    inst.components.container.skipclosesnd = true
    inst.components.container.skipopensnd = true
    
    inst:AddComponent("preserver")
    inst.components.preserver:SetPerishRateMultiplier(0.2)

    MakeHauntableLaunchAndDropFirstItem(inst)

    return inst
end

return Prefab("jx_pack", fn, assets)
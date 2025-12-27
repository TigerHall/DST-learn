local assets =
{
    Asset("ANIM", "anim/jx_car.zip"),
}

local prefabs =
{
    "collapse_big",
}

local function onopen(inst)
    inst.AnimState:PlayAnimation("open")
    inst.SoundEmitter:PlaySound("jx_sound_5/jx_sound_5/open")
end

local function onclose(inst)
    inst.AnimState:PlayAnimation("close")
    inst.SoundEmitter:PlaySound("jx_sound_5/jx_sound_5/close")
end

local function onhammered(inst, worker)
    inst.components.lootdropper:DropLoot()
    if inst.components.container then
      inst.components.container:DropEverything()
    end
    local fx = SpawnPrefab("collapse_big")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("metal")
    inst:Remove()
end

local function onhit(inst, worker)
    inst.AnimState:PlayAnimation("hit")
    inst.AnimState:PushAnimation("closed", false)
    if inst.components.container then
      inst.components.container:DropEverything()
      inst.components.container:Close()
    end
end

local function onbuilt(inst)
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("closed", false)
end

local function onburnt(inst)
  if inst.components.container then
    inst.components.container:DropEverything()
  end
  inst.Transform:SetNoFaced()
  DefaultBurntStructureFn(inst)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

	inst:SetDeploySmartRadius(3.5)
    MakeObstaclePhysics(inst, 2)

    inst.MiniMapEntity:SetIcon("jx_car.tex")

    inst:AddTag("structure")

    inst.AnimState:SetBank("jx_car")
    inst.AnimState:SetBuild("jx_car")
    inst.AnimState:PlayAnimation("closed")
    
    inst.Transform:SetFourFaced()

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    
    inst:AddComponent("container")
    inst.components.container:WidgetSetup("jx_car")
    inst.components.container.onopenfn = onopen
    inst.components.container.onclosefn = onclose
    inst.components.container.skipclosesnd = true
    inst.components.container.skipopensnd = true

    inst:AddComponent("lootdropper")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(6)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)

    inst:ListenForEvent("onbuilt", onbuilt)
    
    MakeLargeBurnable(inst, nil, nil, true)
    inst.components.burnable:SetOnBurntFn(onburnt)
    MakeMediumPropagator(inst)

    AddHauntableDropItemOrWork(inst)

    return inst
end

return Prefab("jx_car", fn, assets, prefabs),
    MakePlacer("jx_car_placer", "jx_car", "jx_car", "closed", nil, nil, nil, nil, 285, "four")

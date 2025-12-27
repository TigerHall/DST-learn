require "prefabutil"

local assets =
{
    Asset("ANIM", "anim/jx_wardrobe.zip"),
}

local prefabs =
{
    "collapse_big",
}

local function onhammered(inst)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
        inst.components.burnable:Extinguish()
    end
    inst.components.lootdropper:DropLoot()
    
    local fx = SpawnPrefab("collapse_big")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("wood")
    inst:Remove()
end

local function onhit(inst)
    if not inst:HasTag("burnt") then
        if inst.components.container ~= nil then
            inst.components.container:DropEverything()
            inst.components.container:Close()
        end
        inst.AnimState:PlayAnimation("hit")
        inst.AnimState:PushAnimation("closed", false)
        inst.SoundEmitter:PlaySound("dontstarve/common/wardrobe_hit")
    end
end

local function onbuilt(inst)
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("closed", false)
    inst.SoundEmitter:PlaySound("dontstarve/common/wardrobe_craft")
    PreventCharacterCollisionsWithPlacedObjects(inst)
end

local function onopen(inst)
    inst.AnimState:PlayAnimation("open")
    inst.SoundEmitter:PlaySound("dontstarve/common/wardrobe_open")
end

local function onclose(inst)
    inst.AnimState:PlayAnimation("closed")
    inst.SoundEmitter:PlaySound("dontstarve/common/wardrobe_close")
end

local function onsave(inst, data)
    if inst:HasTag("burnt") or (inst.components.burnable ~= nil and inst.components.burnable:IsBurning()) then
        data.burnt = true
    end
end

local function onload(inst, data)
    if data ~= nil and data.burnt then
        inst.components.burnable.onburnt(inst)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

	inst:SetDeploySmartRadius(1.25) --recipe min_spacing/2
    inst:SetPhysicsRadiusOverride(.75)
    MakeObstaclePhysics(inst, inst.physicsradiusoverride)

    inst:AddTag("structure")

    inst.AnimState:SetBank("jx_wardrobe")
    inst.AnimState:SetBuild("jx_wardrobe")
    inst.AnimState:PlayAnimation("closed")

    inst.MiniMapEntity:SetIcon("jx_wardrobe.tex")

    --MakeSnowCoveredPristine(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("lootdropper")
    
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)
    
    inst:AddComponent("container")
    inst.components.container:WidgetSetup("jx_wardrobe")
    inst.components.container.skipclosesnd = true
    inst.components.container.skipopensnd = true
    inst.components.container.onopenfn = onopen
    inst.components.container.onclosefn = onclose

    MakeLargeBurnable(inst, nil, nil, true)
    MakeMediumPropagator(inst)

    inst:ListenForEvent("onbuilt", onbuilt)

    inst.OnSave = onsave
    inst.OnLoad = onload

    --MakeSnowCovered(inst)
    MakeHauntableWork(inst)

    return inst
end

return Prefab("jx_wardrobe", fn, assets, prefabs),
    MakePlacer("jx_wardrobe_placer", "jx_wardrobe", "jx_wardrobe", "closed")

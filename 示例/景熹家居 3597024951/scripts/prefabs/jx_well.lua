local assets =
{
    Asset("ANIM", "anim/jx_well.zip"),
}

local prefabs =
{
    "collapse_big",
}

local function onworkfinished(inst)
    inst.components.lootdropper:DropLoot()
    local fx = SpawnPrefab("collapse_big")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("wood")
    inst:Remove()
end

local function onworked(inst, worker, workleft)
    if workleft > 0 then 
      inst.AnimState:PlayAnimation("hit")
      inst.AnimState:PushAnimation("idle", true)
    end
end

local function onbuilt(inst)
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("idle", true)
end

local function onuse_watersource(inst)
    inst.AnimState:PlayAnimation("splash")
    inst.AnimState:PushAnimation("idle", true)
end

local function fn()
    local inst = CreateEntity()
    
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()
    
    MakePondPhysics(inst, 1.6)
    
    inst.MiniMapEntity:SetIcon("jx_well.tex")
    
    inst.AnimState:SetBank("jx_well")
    inst.AnimState:SetBuild("jx_well")
    inst.AnimState:PlayAnimation("idle", true)
    
    inst:AddTag("watersource")
    inst:AddTag("antlion_sinkhole_blocker")
    inst:AddTag("birdblocker")
    
    inst.entity:SetPristine()
    
    if not TheWorld.ismastersim then
        return inst
    end
    
    inst:AddComponent("inspectable")
    
    inst:AddComponent("watersource")
    inst.components.watersource.onusefn = onuse_watersource
    
    inst:AddComponent("lootdropper")
    
    local workable = inst:AddComponent("workable")
    workable:SetWorkAction(ACTIONS.HAMMER)
    workable:SetWorkLeft(10)
    workable:SetOnFinishCallback(onworkfinished)
    workable:SetOnWorkCallback(onworked)
    
    inst:ListenForEvent("onbuilt", onbuilt)
    
    return inst
end

return Prefab("jx_well", fn, assets, prefabs),
  MakePlacer("jx_well_placer", "jx_well", "jx_well", "idle")
require "prefabutil"

local ret = {}

local assets =
{
  Asset("ANIM", "anim/jx_bookcase.zip"),
}

local decor_assets = 
{
  Asset("ANIM", "anim/jx_decor.zip"),
}

local prefabs = 
{
  "collapse_big",
}

local function AddDecor(inst, data)
  if data and data.slot and data.item and not inst:HasTag("burnt") then
    local decor = inst["decor"..tostring(data.slot)]
    if decor and decor:IsValid() then
      if decor.decor and decor.decor:IsValid() then
        decor.decor:Remove()
        decor.decor = nil
      end
      local copy_item = SpawnPrefab(data.item.prefab)
      copy_item.AnimState:SetScale(.5, .5, .5)
      copy_item.AnimState:SetFinalOffset(1)
      copy_item.entity:SetParent(decor.entity)
      copy_item:AddTag("FX")
      copy_item:AddTag("NOCLICK")
      copy_item:AddTag("INLIMBO")
      copy_item:AddTag("outofreach")
      copy_item.persists = false
      decor.decor = copy_item
    end
  end
end

local function RemoveDecor(inst, data)
    if data and data.slot and not inst:HasTag("burnt") then
      local decor = inst["decor"..tostring(data.slot)]
      if decor and decor:IsValid() then
        if decor.decor and decor.decor:IsValid() then
          decor.decor:Remove()
          decor.decor = nil
        end
      end
    end
end

local function onhammered(inst, worker)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
        inst.components.burnable:Extinguish()
    end

    if inst.components.container ~= nil then
        inst.components.container:DropEverything()
    end

    inst.components.lootdropper:DropLoot()

    local fx = SpawnPrefab("collapse_big")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("wood")
    inst:Remove()
end

local function onhit(inst, worker)
    if not inst:HasTag("burnt") then
        if inst.components.container ~= nil then
          inst.components.container:DropEverything()
          inst.components.container:Close()
        end

        inst.AnimState:PlayAnimation("hit")
        inst.AnimState:PushAnimation("idle", false)
    end
end

local function onbuilt(inst)
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("idle", false)
end

local function onburnt(inst)
  if inst.components.container then
    inst.components.container:DropEverything()
  end
  for i = 1, 6 do
    local decor = inst["decor"..tostring(i)]
    if decor and decor:IsValid() then
      decor:Remove()
      decor = nil
    end
  end
  DefaultBurntStructureFn(inst)
end

local function onsave(inst, data)
    if inst:HasTag("burnt") or (inst.components.burnable ~= nil and inst.components.burnable:IsBurning()) then
        data.burnt = true
    end
end

local function onload(inst, data)
    if data and data.burnt then
      inst.components.burnable.onburnt(inst)
    end
end

local function decor_fn()
  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddAnimState()
  inst.entity:AddFollower()
  inst.entity:AddNetwork()
  
  inst.AnimState:SetBank("jx_decor")
  inst.AnimState:SetBuild("jx_decor")
  inst.AnimState:PlayAnimation("idle")
    
  inst:AddTag("FX")

  inst.entity:SetPristine()
  
  if not TheWorld.ismastersim then
    return inst
  end

  inst.persists = false
  
  return inst
end

table.insert(ret, Prefab("jx_decor_bookcase", decor_fn, decor_assets))
table.insert(prefabs, "jx_decor_bookcase")



local function fn()
    local inst = CreateEntity()
    
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()
    
    inst:SetDeploySmartRadius(1)
    MakeObstaclePhysics(inst, 1)
    
    inst.MiniMapEntity:SetIcon("jx_bookcase.tex")
    
    inst:AddTag("structure")
    inst:AddTag("jx_bookcase")
    
    inst.AnimState:SetBank("jx_bookcase")
    inst.AnimState:SetBuild("jx_bookcase")
    inst.AnimState:PlayAnimation("idle")
    
    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end
    
    inst:AddComponent("container")
    inst.components.container:WidgetSetup("jx_bookcase") 
    
    inst:AddComponent("inspectable")
    
    inst:AddComponent("lootdropper")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)
    
    inst:AddComponent("preserver")
	  inst.components.preserver:SetPerishRateMultiplier(0)
    
    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)
    
    inst:ListenForEvent("onbuilt", onbuilt)
    inst:ListenForEvent("itemget", AddDecor)
    inst:ListenForEvent("itemlose", RemoveDecor)
    
    MakeMediumBurnable(inst, nil, nil, true)
    inst.components.burnable:SetOnBurntFn(onburnt)
    MakeMediumPropagator(inst)
    
    for i = 1, 6 do
      local decor = SpawnPrefab("jx_decor_bookcase")
      if decor then
        decor.entity:SetParent(inst.entity)
        decor.Follower:FollowSymbol(inst.GUID, "swap_img"..tostring(i))
        decor.AnimState:SetFinalOffset(1)
        inst["decor"..tostring(i)] = decor
      end
    end
    
    inst.OnSave = onsave
    inst.OnLoad = onload
    
    return inst
end

table.insert(ret, Prefab("jx_bookcase", fn, assets, prefabs))
table.insert(ret, MakePlacer("jx_bookcase_placer", "jx_bookcase", "jx_bookcase", "placer"))


return unpack(ret)
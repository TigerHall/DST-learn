require "prefabutil"

local ret = {}

local decor_assets = 
{
  Asset("ANIM", "anim/jx_decor.zip"),
}

local prefabs =
{
    "collapse_small",
}

local function onhammered(inst)
    if inst.components.burnable and inst.components.burnable:IsBurning() then
        inst.components.burnable:Extinguish()
    end
    if inst.components.lootdropper then
      inst.components.lootdropper:DropLoot()
    end
    
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("wood")
    inst:Remove()
end

local function onhit(inst)
    if not inst:HasTag("burnt") then
        if inst.components.inventory then
          inst.components.inventory:DropEverything()
        end
        if inst.components.pickable then
          inst.components.pickable.canbepicked = false
          inst.components.pickable.numtoharvest = 0
        end
        
        if inst.copy_item and inst.copy_item:IsValid() then
          inst.copy_item:Remove()
          inst.copy_item = nil
        end
        inst.AnimState:PlayAnimation("hit")
        inst.AnimState:PushAnimation("idle", false)
    end
end

local function onbuilt(inst)
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("idle", false)
end

local function onpicked(inst, picker)
    if inst.components.pickable then
      inst.components.pickable.canbepicked = false
      inst.components.pickable.numtoharvest = 0
    end
    if picker then
      local item = inst.components.inventory:RemoveItemBySlot(1)
      if item then
        if picker.components.inventory then
          picker.components.inventory:GiveItem(item)
        end
        if item.components.perishable then
          item.components.perishable:StartPerishing()
        end
      end
    end
    if inst.copy_item and inst.copy_item:IsValid() then
      inst.copy_item:Remove()
      inst.copy_item = nil
    end
end

local function onburnt(inst)
  if inst.components.inventory then
    inst.components.inventory:DropEverything()
  end
  if inst.components.pickable then
    inst.components.pickable.canbepicked = false
    inst.components.pickable.numtoharvest = 0
  end
  
  if inst.copy_item and inst.copy_item:IsValid() then
    inst.copy_item:Remove()
    inst.copy_item = nil
  end
  if inst.decor and inst.decor:IsValid() then
    inst.decor:Remove()
    inst.decor = nil
  end
  DefaultBurntStructureFn(inst)
end

local function onsave(inst, data)
    if inst:HasTag("burnt") or (inst.components.burnable ~= nil and inst.components.burnable:IsBurning()) then
        data.burnt = true
    else
      if inst.real_y_offset then
        data.real_y_offset = inst.real_y_offset
      end
    end
end

local function onload(inst, data)
    if data ~= nil then
      if data.burnt then
        inst.components.burnable.onburnt(inst)
      else
        if inst.decor and inst.decor:IsValid() then
          inst.decor:Remove()
          inst.decor = nil
        end
        inst.decor = SpawnPrefab("jx_decor_table2")
        inst.decor.entity:SetParent(inst.entity)
        if data.real_y_offset then
          inst.real_y_offset = data.real_y_offset
          inst.decor.Follower:FollowSymbol(inst.GUID, "pot", inst.x_offset, inst.real_y_offset, inst.z_offset)
        else
          inst.decor.Follower:FollowSymbol(inst.GUID, "pot", inst.x_offset, inst.y_offset, inst.z_offset)
        end
        inst.decor.AnimState:SetFinalOffset(1)
        
        if inst.copy_item and inst.copy_item:IsValid() then
          inst.copy_item:Remove()
          inst.copy_item = nil
        end
        
        local item = inst.components.inventory:GetItemInSlot(1)
        if item then
          inst.components.trader.onaccept(inst, nil, item)
          if data.real_y_offset then--onaccept函数会修改一次inst.real_y_offset，所以再改回去，确保inst.real_y_offset每次加载可以不变
            inst.real_y_offset = data.real_y_offset
          end
        end
      end
    end
end

local function ShouldAcceptItem(inst, item, giver)
  if inst:HasTag("jx_table_2") and not item:HasTag("preparedfood") then
    if giver and giver.components.talker then
      giver.components.talker:Say(STRINGS.MUST_BE_PREPAREDFOOD)--"只有高级的料理才可以上这台桌。"
    end
    return false
  elseif inst.components.inventory and inst.components.inventory:IsFull() then
    if giver and giver.components.talker then
      giver.components.talker:Say(STRINGS.CHARACTERS.WARLY.DESCRIBE.FENCE_ELECTRIC_ITEM)--"得给它找个好位置。"
    end
    return false
  end
  return not inst:HasTag("burnt")
end

local function OnGetItemFromPlayer(inst, giver, item)
  if item == nil then 
    return 
  end
  
  inst.SoundEmitter:PlaySound("dontstarve/common/together/moonbase/moonstaff_place", nil, .2)
  
  --[[if giver and giver.components.talker then
    giver.components.talker:Say(STRINGS.JX_TABLE_6_OFFSET)--"将物品拿下再重新放上可以修正位置。"
  end]]
  
  if inst.decor == nil or not inst.decor:IsValid() then
    inst.decor = SpawnPrefab("jx_decor_table2")
    inst.decor.entity:SetParent(inst.entity)
    inst.decor.AnimState:SetFinalOffset(1)
  end
  inst.decor.Follower:FollowSymbol(inst.GUID, "pot", inst.x_offset, inst.real_y_offset or inst.y_offset, inst.z_offset)
  
  if inst.copy_item and inst.copy_item:IsValid() then
    inst.copy_item:Remove()
    inst.copy_item = nil
  end
  
  local copy_item = SpawnPrefab(item.prefab, item:GetSkinBuild(), item.skin_id)
  copy_item.AnimState:SetScale(.9, .9, .9)
  copy_item.AnimState:SetFinalOffset(1)
  copy_item.entity:SetParent(inst.decor.entity)
  copy_item:AddTag("FX")
  copy_item:AddTag("NOCLICK")
  copy_item:AddTag("INLIMBO")
  copy_item:AddTag("outofreach")
  if copy_item.components.perishable then
    copy_item.components.perishable:StopPerishing()
  end
  inst.copy_item = copy_item
  
  if inst.real_y_offset then
    local random_y_offset = math.floor(-20 * math.random())
    inst.real_y_offset = inst.y_offset + inst.real_y_offset_num + random_y_offset
    inst.real_y_offset_num = inst.real_y_offset_num + random_y_offset--积累偏移值
    if inst.real_y_offset_num <= 0 then
      inst.real_y_offset_num = inst.real_y_offset_num + 80--回到最高值附近重新积累
    end
  end
  
  if item.components.perishable then
    item.components.perishable:StopPerishing()
  end
  if inst.components.pickable then
    inst.components.pickable.canbepicked = true
    inst.components.pickable.numtoharvest = 1
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

table.insert(ret, Prefab("jx_decor_table2", decor_fn, decor_assets))
table.insert(prefabs, "jx_decor_table2")



local function MakeTable(name, x_offset, y_offset, z_offset, change_offset, acceptnontradable)
  local assets =
  {
      Asset("ANIM", "anim/"..name..".zip"),
  }
  local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

	  inst:SetDeploySmartRadius(1)
    MakeObstaclePhysics(inst, .5)

    inst:AddTag("structure")
    inst:AddTag(name)
    inst:AddTag("trader")
    if acceptnontradable then
      inst:AddTag("alltrader")
    end

    inst.AnimState:SetBank(name)
    inst.AnimState:SetBuild(name)
    inst.AnimState:PlayAnimation("idle")

    inst.MiniMapEntity:SetIcon(name..".tex")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
    
    inst.x_offset = x_offset
    inst.y_offset = y_offset
    inst.z_offset = z_offset
    if change_offset then
      inst.real_y_offset_num = 70--其值在0~80之间，用于修正inst.real_y_offset，每次给予物品时积累值，向下积累
      inst.real_y_offset = inst.y_offset + inst.real_y_offset_num--inst.real_y_offset是真实偏移，inst.y_offset只做基础定位
    end
    
    inst.decor = SpawnPrefab("jx_decor_table2")
    inst.decor.entity:SetParent(inst.entity)
    inst.decor.Follower:FollowSymbol(inst.GUID, "pot", inst.x_offset, inst.real_y_offset or inst.y_offset, inst.z_offset)
    inst.decor.AnimState:SetFinalOffset(1)

    inst:AddComponent("inspectable")

    inst:AddComponent("lootdropper")
    
    inst:AddComponent("inventory")
    inst.components.inventory.maxslots = 1
        
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)
    
    inst:AddComponent("trader")
    inst.components.trader:SetAcceptTest(ShouldAcceptItem)
    inst.components.trader:SetOnAccept(OnGetItemFromPlayer)
    inst.components.trader.deleteitemonaccept = false
    inst.components.trader.acceptnontradable = acceptnontradable
    
    inst:AddComponent("pickable")
    inst.components.pickable.canbepicked = false
    inst.components.pickable.numtoharvest = 0
    inst.components.pickable:SetOnPickedFn(onpicked)
    inst.components.pickable.quickpick = true

    MakeLargeBurnable(inst, nil, nil, true)
    inst.components.burnable:SetOnBurntFn(onburnt)
    MakeMediumPropagator(inst)

    inst:ListenForEvent("onbuilt", onbuilt)

    inst.OnSave = onsave
    inst.OnLoad = onload

    MakeHauntableWork(inst)

    return inst
  end
  table.insert(ret, Prefab(name, fn, assets, prefabs))
  table.insert(ret, MakePlacer(name.."_placer", name, name, "idle"))
end

--         name,        x_offset, y_offset, z_offset, change_offset, acceptnontradable
MakeTable("jx_table_2",  0,         20,      0,       false,         false)
MakeTable("jx_table_6",  -10,       -80,     0,       true,          true)

return unpack(ret)
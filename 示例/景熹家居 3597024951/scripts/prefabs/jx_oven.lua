require "prefabutil"

local ret = {}

local assets =
{
    Asset("ANIM", "anim/jx_oven.zip"),
}

local front_assets = 
{
    Asset("ANIM", "anim/jx_oven.zip"),
    Asset("ANIM", "anim/jx_oven2.zip"),
}

local decor_assets = 
{
  Asset("ANIM", "anim/jx_decor.zip"),
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
    fx:SetMaterial("metal")
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
        if inst.cook_task then
          inst.cook_task:Cancel()
          inst.cook_task = nil
        end
        if inst.copy_item_1 and inst.copy_item_1:IsValid() then
          inst.copy_item_1:Remove()
          inst.copy_item_1 = nil
        end
        if inst.copy_item_2 and inst.copy_item_2:IsValid() then
          inst.copy_item_2:Remove()
          inst.copy_item_2 = nil
        end
        inst.SoundEmitter:KillSound("cooking")
        inst.AnimState:PlayAnimation("hit")
        inst.AnimState:PushAnimation("closed", false)
        if inst.front ~= nil then
          inst.front.AnimState:PlayAnimation("hit")
          inst.front.AnimState:PushAnimation("closed", false)
        end
    end
end

local function onbuilt(inst)
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("closed", false)
    inst.SoundEmitter:PlaySound("dontstarve/common/icebox_craft")
    if inst.front ~= nil then
      inst.front.AnimState:PlayAnimation("place")
      inst.front.AnimState:PushAnimation("closed", false)
    end
end

local function onpicked(inst, picker)
    inst.components.pickable.canbepicked = false
    inst.components.pickable.numtoharvest = 0
    if picker and inst.components.inventory then
      inst.components.inventory:TransferInventory(picker)
    end
    if inst.copy_item_1 and inst.copy_item_1:IsValid() then
      inst.copy_item_1:Remove()
      inst.copy_item_1 = nil
    end
    if inst.copy_item_2 and inst.copy_item_2:IsValid() then
      inst.copy_item_2:Remove()
      inst.copy_item_2 = nil
    end
    inst.AnimState:PlayAnimation("close")
    inst.AnimState:PushAnimation("closed", false)
    if inst.front then
      inst.front.AnimState:PlayAnimation("close")
      inst.front.AnimState:PushAnimation("closed", false)
    end
end

local function onburnt(inst)
  inst.components.inventory:DropEverything()
  inst.components.pickable.canbepicked = false
  inst.components.pickable.numtoharvest = 0
  
  if inst.front and inst.front:IsValid() then
    inst.front:Remove()
    inst.front = nil
  end
  if inst.copy_item_1 and inst.copy_item_1:IsValid() then
    inst.copy_item_1:Remove()
    inst.copy_item_1 = nil
  end
  if inst.copy_item_2 and inst.copy_item_2:IsValid() then
    inst.copy_item_2:Remove()
    inst.copy_item_2 = nil
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
    end
end

local function onload(inst, data)
    if data ~= nil then
      if inst.decor and inst.decor:IsValid() then
        inst.decor:Remove()
        inst.decor = nil
      end
      inst.decor = SpawnPrefab("jx_decor_oven")
      if inst.decor ~= nil then
        inst.decor.entity:SetParent(inst.entity)
        inst.decor.Follower:FollowSymbol(inst.GUID, "base", -10, 110, 0, true, false, 0)
      end
      
      if data.burnt then
        inst.components.burnable.onburnt(inst)
      else
        local item1 = inst.components.inventory:GetItemInSlot(1)
        local item2 = inst.components.inventory:GetItemInSlot(2)
        if item1 then
          inst.components.trader.onaccept(inst, nil, item1)
        elseif item2 then
          inst.AnimState:PlayAnimation("open")
          if inst.front then
            inst.front.AnimState:PlayAnimation("open")
          end
          if inst.copy_item_1 and inst.copy_item_1:IsValid() then
            inst.copy_item_1:Remove()
            inst.copy_item_1 = nil
          end
          if inst.copy_item_2 and inst.copy_item_2:IsValid() then
            inst.copy_item_2:Remove()
            inst.copy_item_2 = nil
          end
          local copy_item_2 = SpawnPrefab(item2.prefab)
          if copy_item_2 ~= nil then
            copy_item_2.AnimState:SetScale(.5, .5, .5)
            copy_item_2.AnimState:SetFinalOffset(1) -- 确保在正确的渲染层
            copy_item_2.entity:SetParent(inst.decor.entity)
            copy_item_2:AddTag("FX")
            copy_item_2:AddTag("NOCLICK")
            copy_item_2:AddTag("INLIMBO")
            copy_item_2:AddTag("outofreach")
            if copy_item_2.components.perishable then
              copy_item_2.components.perishable:StopPerishing()
            end
            inst.copy_item_2 = copy_item_2
          end
        end
      end
    end
end

local function ShouldAcceptItem(inst, item, giver)
  if not item:HasTag("cookable") then
    if giver and giver.components.talker then
      giver.components.talker:Say(STRINGS.SKIN_QUOTES.warly_nature)--"我只用天然材料烹饪。"
    end
    return false
  elseif inst.components.inventory:GetFirstItemInAnySlot() ~= nil then
    if giver and giver.components.talker then
      giver.components.talker:Say(STRINGS.CHARACTERS.WURT.ACTIONFAIL.CHANGEIN.INUSE)--"得等等……"
    end
    return false
  end
  return not inst:HasTag("burnt") and item.components.health == nil
end

local function OnGetItemFromPlayer(inst, giver, item)
  inst.SoundEmitter:PlaySound("dontstarve/quagmire/common/safe/open")
  inst:DoTaskInTime(0.5, function() inst.SoundEmitter:PlaySound("jx_sound_1/jx_sound_1/oven", "cooking") end)
  
  inst.AnimState:PlayAnimation("open")
  inst.AnimState:PushAnimation("close")
  inst.AnimState:PushAnimation("cook", true)
  
  if inst.front ~= nil then
    inst.front.AnimState:PlayAnimation("open")
    inst.front.AnimState:PushAnimation("close")
    inst.front.AnimState:PushAnimation("cook", true)
  end
  
  if inst.decor == nil or not inst.decor:IsValid() then
    inst.decor = SpawnPrefab("jx_decor_oven")
    if inst.decor ~= nil then
      inst.decor.entity:SetParent(inst.entity)
      inst.decor.Follower:FollowSymbol(inst.GUID, "base", -10, 110, 0, true, false, 0)
    end
  end
  
  if inst.copy_item_1 and inst.copy_item_1:IsValid() then
    inst.copy_item_1:Remove()
    inst.copy_item_1 = nil
  end
  if inst.decor and inst.decor:IsValid() then
    local copy_item_1 = SpawnPrefab(item.prefab)
    if copy_item_1 ~= nil then
      copy_item_1.AnimState:SetScale(.5, .5, .5)
      copy_item_1.AnimState:SetFinalOffset(1)
      copy_item_1.entity:SetParent(inst.decor.entity)
      copy_item_1:AddTag("FX")
      copy_item_1:AddTag("NOCLICK")
      copy_item_1:AddTag("INLIMBO")
      copy_item_1:AddTag("outofreach")
      inst.copy_item_1 = copy_item_1
    end
  end
  
  inst.cook_task = inst:DoTaskInTime(5, function()
    if inst:HasTag("burnt") then
      return
    end
    
    -- 不重新创建 decor，直接使用
    if inst.decor == nil or not inst.decor:IsValid() then
      return
    end
    
    local cook_pos = inst:GetPosition()
    local current_item = inst.components.inventory:GetItemInSlot(1)
    if current_item == nil then
      return
    end
    
    local stackable = current_item.components.stackable
    local stacksize = stackable and stackable:StackSize() or 1
    for i = 1, stacksize do
      local stacked = stackable and stackable:IsStack()
      local ingredient = stacked and stackable:Get() or current_item
    
      if ingredient ~= current_item then
        ingredient.Transform:SetPosition(cook_pos:Get())
      end
        
      local product = ingredient.components.cookable and ingredient.components.cookable:Cook(inst, inst)
      if product ~= nil then
        inst.components.inventory:GiveItem(product, 2, cook_pos)
        if inst.copy_item_2 == nil and inst.decor and inst.decor:IsValid() then
          local copy_item_2 = SpawnPrefab(product.prefab)
          if copy_item_2 ~= nil then
            copy_item_2.AnimState:SetScale(.5, .5, .5)
            copy_item_2.AnimState:SetFinalOffset(1)
            copy_item_2.entity:SetParent(inst.decor.entity)
            copy_item_2:AddTag("FX")
            copy_item_2:AddTag("NOCLICK")
            copy_item_2:AddTag("INLIMBO")
            copy_item_2:AddTag("outofreach")
            if copy_item_2.components.perishable then
              copy_item_2.components.perishable:StopPerishing()
            end
            inst.copy_item_2 = copy_item_2
            if inst.copy_item_2:IsInLimbo() then
              inst.copy_item_2:ReturnToScene()
            end
            if not inst.copy_item_2.entity:IsVisible() then
              inst.copy_item_2:Show()
            end
          end
        end
      elseif ingredient:IsValid() then
        inst.components.inventory:GiveItem(ingredient, nil, cook_pos)
      end
      
      ingredient:Remove()
    end
    
    inst.components.pickable.canbepicked = true
    inst.components.pickable.numtoharvest = 1
    inst.SoundEmitter:PlaySound("dontstarve/quagmire/common/safe/open")
    inst.AnimState:PlayAnimation("open")
    if inst.front then
      inst.front.AnimState:PlayAnimation("open")
    end
    if inst.copy_item_1 and inst.copy_item_1:IsValid() then
      inst.copy_item_1:Remove()
      inst.copy_item_1 = nil
    end
    inst.cook_task = nil
  end)
end

local function front_fn()
  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddAnimState()
  inst.entity:AddNetwork()
  
  inst:AddTag("FX")

  inst.AnimState:SetBank("jx_oven")
  inst.AnimState:SetBuild("jx_oven2")
  inst.AnimState:PlayAnimation("closed")
  inst.AnimState:SetFinalOffset(3)

  inst.entity:SetPristine()

  if not TheWorld.ismastersim then
    return inst
  end

  inst.persists = false
  
  return inst
end

table.insert(ret, Prefab("oven_front", front_fn, front_assets))
table.insert(prefabs, "oven_front")


local function decor_fn()
  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddAnimState()
  inst.entity:AddFollower()
  inst.entity:AddNetwork()
  
  inst.AnimState:SetBank("jx_decor")
  inst.AnimState:SetBuild("jx_decor")
  pcall(function()
    inst.AnimState:PlayAnimation("idle")
  end)
    
  inst:AddTag("FX")

  inst.entity:SetPristine()
  
  if not TheWorld.ismastersim then
    return inst
  end

  inst.persists = false
  
  return inst
end

table.insert(ret, Prefab("jx_decor_oven", decor_fn, decor_assets))
table.insert(prefabs, "jx_decor_oven")



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
    inst:AddTag("jx_oven")

    inst.AnimState:SetBank("jx_oven")
    inst.AnimState:SetBuild("jx_oven")
    inst.AnimState:PlayAnimation("closed")
    inst.AnimState:Hide("door")

    inst.MiniMapEntity:SetIcon("jx_oven.tex")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
    
    inst.decor = SpawnPrefab("jx_decor_oven")
    if inst.decor ~= nil then
      inst.decor.entity:SetParent(inst.entity)
      inst.decor.Follower:FollowSymbol(inst.GUID, "base", -10, 110, 0, true, false, 0)
    end
    
    inst.front = SpawnPrefab("oven_front")
    if inst.front ~= nil then
      inst.front.entity:SetParent(inst.entity)
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("lootdropper")
    
    inst:AddComponent("inventory")
    inst.components.inventory.maxslots = 3
        
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)
    
    inst:AddComponent("trader")
    inst.components.trader:SetAcceptTest(ShouldAcceptItem)
    inst.components.trader:SetOnAccept(OnGetItemFromPlayer)
    inst.components.trader.deleteitemonaccept = false
    inst.components.trader:SetAcceptStacks()
    
    inst:AddComponent("pickable")
    inst.components.pickable.canbepicked = false
    inst.components.pickable.numtoharvest = 0
    inst.components.pickable:SetOnPickedFn(onpicked)

    MakeLargeBurnable(inst, nil, nil, true)
    inst.components.burnable:SetOnBurntFn(onburnt)
    MakeMediumPropagator(inst)

    inst:ListenForEvent("onbuilt", onbuilt)

    inst.OnSave = onsave
    inst.OnLoad = onload

    MakeHauntableWork(inst)

    return inst
end

table.insert(ret, Prefab("jx_oven", fn, assets, prefabs))
table.insert(ret, MakePlacer("jx_oven_placer", "jx_oven", "jx_oven", "closed"))

return unpack(ret)
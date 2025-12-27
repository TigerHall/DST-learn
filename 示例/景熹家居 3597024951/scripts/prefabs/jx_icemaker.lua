local assets =
{
    Asset("ANIM", "anim/jx_icemaker.zip"),
}

local prefabs = 
{
  "collapse_small",
  "ice",
}

local MACHINESTATES =
{
	ON = "_on",
	OFF = "_off",
}

local function onhammered(inst, worker)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
        inst.components.burnable:Extinguish()
    end

    inst.components.lootdropper:DropLoot()

    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("metal")
    inst:Remove()
end

local function onhit(inst, worker)
  if not inst:HasTag("burnt") then
    inst.AnimState:PlayAnimation("hit"..inst.machinestate)
    inst.AnimState:PushAnimation("idle"..inst.machinestate, true)
    if inst.components.container ~= nil then
      inst.components.container:DropEverything()
      inst.components.container:Close()
    end
  end
end

local function onbuilt(inst)
	inst.AnimState:PlayAnimation("place")
  inst.AnimState:PushAnimation("turn"..inst.machinestate)
	inst.AnimState:PushAnimation("idle"..inst.machinestate, true)
	inst.SoundEmitter:PlaySound("dontstarve_DLC001/common/firesupressor_craft")
end

local function ontakefuel(inst)
  inst.SoundEmitter:PlaySound("dontstarve_DLC001/common/machine_fuel")
end

local function cantakefuelitem(inst, item, doer)
  if inst.components.fueled and inst.components.fueled:GetPercent() > .95 then
    if doer and doer:IsValid() then
      doer:DoTaskInTime(0,function()
        if doer.components.talker then
          doer.components.talker:Say(STRINGS.CHARACTERS.WILLOW.ACTIONFAIL.STORE.GENERIC)--"已经满了。"
        end
      end)
    end
    return false
  end
  return true
end

local function onburnt(inst)
  if inst.components.container then
    inst.components.container:DropEverything()
  end
  DefaultBurntStructureFn(inst)
end

local function StartWork(inst)
  if inst:HasTag("burnt") then
    return
  end
  if inst.components.fueled:GetPercent() <= 0 then
    local x, y, z = inst.Transform:GetWorldPosition()
    local players = FindPlayersInRange(x, y, z, 4, true)
    for _, v in pairs(players) do
      if v and v:IsValid() and v.components.talker then
        v.components.talker:Say(STRINGS.CHARACTERS.GENERIC.DESCRIBE.FIRESUPPRESSOR.LOWFUEL.."\n"..STRINGS.CHARACTERS.WINONA.DESCRIBE.WINONA_BATTERY_LOW.OFF)--"燃料有点不足了。\n需要再弄点硝石。"
        break
      end
    end
    return
  end
  
  if inst.components.container then
    inst.components.container:Close()
    inst.components.container.canbeopened = false
  end
  
  inst.SoundEmitter:PlaySound("dontstarve_DLC001/common/machine_fuel")
  if inst.machinestate == MACHINESTATES.ON then
    inst.machinestate = MACHINESTATES.OFF
    inst.AnimState:PlayAnimation("turn"..inst.machinestate)
    inst.AnimState:PushAnimation("work_loop", true)
  else
    inst.AnimState:PlayAnimation("work_loop", true)
  end
  
  local num_to_give = 0
  if inst.components.container and inst.components.fueled then
    for i = 1, inst.components.container.numslots do
      local item = inst.components.container:GetItemInSlot(i)
      if item and not item:HasTag("ice") then
        local stackable = item.components.stackable
        local stacksize = stackable and stackable:StackSize() or 1
        for j = 1, stacksize do
          local old_percent = inst.components.fueled:GetPercent()
          if old_percent > 0 then
            inst.components.fueled:SetPercent(old_percent - 0.005)
            if stackable then
              stackable:Get():Remove()
            else
              item:Remove()
            end
            num_to_give = num_to_give +1
          else
            break
          end
        end
      end
    end
  end
  
  if num_to_give > 0 then
    for i = 1, num_to_give do
      local ice = SpawnPrefab("ice")
      ice.Transform:SetPosition(inst.Transform:GetWorldPosition())
      if inst.components.container then
        inst.components.container:GiveItem(ice)
      end
    end
  end
  
  inst:DoTaskInTime(5,function()
    inst.SoundEmitter:PlaySound("dontstarve/common/researchmachine_science_gift_recieve", nil, .4)
    inst.machinestate = MACHINESTATES.ON
    inst.AnimState:PlayAnimation("use_from_off")
    inst.AnimState:PushAnimation("idle"..inst.machinestate, true)
  end)
  inst:DoTaskInTime(5 + 64 * FRAMES,function()
    inst.SoundEmitter:PlaySound("dontstarve_DLC001/common/machine_fuel")
  end)
  inst:DoTaskInTime(5 + 79 * FRAMES,function()
    if inst.components.container then
      inst.components.container.canbeopened = true
    end
  end)
end

local function is_idle_anim(inst)
  return inst.AnimState:IsCurrentAnimation("idle_on") or inst.AnimState:IsCurrentAnimation("idle_off")
end

local function onitemchange(inst, data)
  if inst:HasTag("burnt") then
    return
  end
  
  if data and 
    (
      (data.item and data.item.prefab == "ice") or 
      (data.prev_item and data.prev_item.prefab == "ice")
    )
  then
    local has_any_ice = inst.components.container and inst.components.container:HasItemWithTag("ice", 1)--至少一个
    if has_any_ice then
      if inst.machinestate == MACHINESTATES.OFF then
        inst.machinestate = MACHINESTATES.ON
        inst:DoTaskInTime(3 * FRAMES,function()
          if is_idle_anim(inst) then
            inst.AnimState:PlayAnimation("turn"..inst.machinestate)
            inst.AnimState:PushAnimation("idle"..inst.machinestate, true)
          end
        end)
      end
    else
      if inst.machinestate == MACHINESTATES.ON then
        inst.machinestate = MACHINESTATES.OFF
        inst:DoTaskInTime(3 * FRAMES,function()
          if is_idle_anim(inst) then
            inst.AnimState:PlayAnimation("turn"..inst.machinestate)
            inst.AnimState:PushAnimation("idle"..inst.machinestate, true)
          end
        end)
      end
    end
  end
end

local function OnSave(inst, data)
  if inst:HasTag("burnt") or (inst.components.burnable ~= nil and inst.components.burnable:IsBurning()) then
    data.burnt = true
  end
end

local function OnLoad(inst, data)
  if data ~= nil then
    if data.burnt then
      inst.components.burnable.onburnt(inst)
      onburnt(inst)
    else
      --播放正确的动画
      local has_any_ice = inst.components.container and inst.components.container:HasItemWithTag("ice", 1)--至少一个
      if has_any_ice then
        if inst.machinestate == MACHINESTATES.OFF then
          inst.machinestate = MACHINESTATES.ON
          inst.AnimState:PlayAnimation("idle"..inst.machinestate, true)
        end
      else
        if inst.machinestate == MACHINESTATES.ON then
          inst.machinestate = MACHINESTATES.OFF
          inst.AnimState:PlayAnimation("idle"..inst.machinestate, true)
        end
      end
    end
  end
end

local function fn()
    local inst = CreateEntity()
    
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()
    
    inst:SetDeploySmartRadius(1)
    MakeObstaclePhysics(inst, .5)
    
    inst.MiniMapEntity:SetIcon("jx_icemaker.tex")
    
    inst:AddTag("structure")
    inst:AddTag("jx_icemaker")
    
    inst.AnimState:SetBank("jx_icemaker")
    inst.AnimState:SetBuild("jx_icemaker")
    inst.AnimState:PlayAnimation("idle_off")
    
    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end
    
    inst:AddComponent("lootdropper")
    inst:AddComponent("workable")
  	inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
	  inst.components.workable:SetWorkLeft(4)
	  inst.components.workable:SetOnFinishCallback(onhammered)
	  inst.components.workable:SetOnWorkCallback(onhit)
    
    inst:AddComponent("inspectable")
    
    inst:AddComponent("fueled")
    inst.components.fueled:InitializeFuelLevel(900)
    inst.components.fueled:SetTakeFuelFn(ontakefuel)
    inst.components.fueled:SetCanTakeFuelItemFn(cantakefuelitem)
    inst.components.fueled.accepting = true
    inst.components.fueled.fueltype = FUELTYPE.CHEMICAL
    
    inst:AddComponent("container")
    inst.components.container:WidgetSetup("jx_icemaker")
    
    inst:AddComponent("preserver")
	  inst.components.preserver:SetPerishRateMultiplier(0)
    
    inst.machinestate = MACHINESTATES.OFF
    
    inst:ListenForEvent( "onbuilt", onbuilt)
    inst:ListenForEvent("itemget", onitemchange)
    inst:ListenForEvent("itemlose", onitemchange)
    
    MakeMediumBurnable(inst, nil, nil, true)
    inst.components.burnable:SetOnBurntFn(onburnt)
    MakeMediumPropagator(inst)
    
    inst.StartWork = StartWork
    
    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
    
    return inst
end

return Prefab( "jx_icemaker", fn, assets, prefabs),
		MakePlacer( "jx_icemaker_placer", "jx_icemaker", "jx_icemaker", "idle_off" )
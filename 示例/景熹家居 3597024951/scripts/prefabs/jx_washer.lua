require "prefabutil"

local assets =
{
    Asset("ANIM", "anim/jx_washer.zip"),
}

local prefabs =
{
    "collapse_big",
    --"heatrocklight",
}

local sound = 
{
  open = "jx_sound_3/jx_sound_3/open",
  close = "jx_sound_3/jx_sound_3/close",
  washing = "jx_sound_3/jx_sound_3/loop",
}

--[[local buffs_name =
{
  "walkspeedmult",
  "dapperness",
  "light_radiu",
  "hunger_modifier",
  "health_regen",
  "insulator",
  "waterproofer",
  "combat_damage_modifier",
  "combat_taken_modifier",
}

local buffs_value = 
{
  walkspeedmult = .05,-- +5% 移速
  dapperness = TUNING.DAPPERNESS_SMALL,-- +16.0 san/天
  light_radiu = .6,-- 0.6 半径发光
  hunger_modifier = .95,-- -5% 饥饿速度
  health_regen = 1/30,-- +16.0 health/天
  insulator = 30,-- +30 隔热/保暖值
  waterproofer = .1,-- +10% 防水值
  combat_damage_modifier = 1.05,-- +5% 伤害输出
  combat_taken_modifier = .95,-- +5% 减伤
}

local function GetRandomBuff(inst)
  if inst.components.equippable == nil then 
    return
  end
  
  local rnd = math.random(1, #buffs_name)
  local buff_name = buffs_name[rnd]
  local buff_value = buffs_value[buff_name]
  
  if buff_value == nil then 
    return 
  elseif buff_name == "walkspeedmult" then
    local old_walkspeedmult = inst.components.equippable.walkspeedmult or 1.0
    inst.components.equippable.walkspeedmult = old_walkspeedmult + buff_value
    inst.washer_old_walkspeedmult = old_walkspeedmult
  elseif buff_name == "dapperness" then
    local old_dapperness = inst.components.equippable.dapperness or 0
    inst.components.equippable.dapperness = old_dapperness + buff_value
    inst.washer_old_dapperness = old_dapperness
  elseif buff_name == "light_radiu" then
    local old_onequipfn = inst.components.equippable.onequipfn
    local old_onunequipfn = inst.components.equippable.onunequipfn
    inst.components.equippable:SetOnEquip(function(inst, owner)
      old_onequipfn(inst, owner)
      owner.washer_buff_light = SpawnPrefab("heatrocklight")-- 过热暖石光照为0.6照明半径
      owner.washer_buff_light.entity:SetParent(owner.entity)
      owner.washer_buff_light.Light:Enable(true)
    end)
    inst.components.equippable:SetOnUnequip(function(inst, owner)
      old_onunequipfn(inst, owner)
      if owner.washer_buff_light and owner.washer_buff_light:IsValid() then
        owner.washer_buff_light:Remove()
        owner.washer_buff_light = nil
      end
    end)
    inst.washer_old_onequipfn = old_onequipfn
    inst.washer_old_onunequipfn = old_onunequipfn
  elseif buff_name == "hunger_modifier" then
    local old_onequipfn = inst.components.equippable.onequipfn
    local old_onunequipfn = inst.components.equippable.onunequipfn
    inst.components.equippable:SetOnEquip(function(inst, owner)
      old_onequipfn(inst, owner)
      if owner.components.hunger then
        owner.components.hunger.burnratemodifiers:SetModifier(inst, buff_value)
      end
    end)
    inst.components.equippable:SetOnUnequip(function(inst, owner)
      old_onunequipfn(inst, owner)
      if owner.components.hunger then
        owner.components.hunger.burnratemodifiers:RemoveModifier(inst)
      end
    end)
    inst.washer_old_onequipfn = old_onequipfn
    inst.washer_old_onunequipfn = old_onunequipfn
  elseif buff_name == "health_regen" then
    local old_onequipfn = inst.components.equippable.onequipfn
    local old_onunequipfn = inst.components.equippable.onunequipfn
    inst.components.equippable:SetOnEquip(function(inst, owner)
      old_onequipfn(inst, owner)
      owner.washer_regen_task = owner:DoPeriodicTask(1,function()
        if owner.components.health then
          owner.components.health:DoDelta(buff_value, true)
        end
      end)
    end)
    inst.components.equippable:SetOnUnequip(function(inst, owner)
      old_onunequipfn(inst, owner)
      if owner.washer_regen_task then
        owner.washer_regen_task:Cancel()
        owner.washer_regen_task = nil
      end
    end)
    inst.washer_old_onequipfn = old_onequipfn
    inst.washer_old_onunequipfn = old_onunequipfn
  elseif buff_name == "insulator" then
    local old_insulator = inst.components.insulator ~= nil
    if not old_insulator then
      inst:AddComponent("insulator")
      if math.random() < .5 then
        inst.components.insulator:SetSummer()
      end
    end
    local old_insulation = inst.components.insulator.insulation
    inst.components.insulator.insulation = old_insulation + buff_value
    inst.washer_old_insulation = not old_insulator and nil or old_insulation
  elseif buff_name == "waterproofer" then
    local old_waterproofer = inst.components.waterproofer
    if not old_waterproofer then
      inst:AddComponent("waterproofer")
    end
    local old_effectiveness = inst.components.waterproofer.effectiveness
    inst.components.waterproofer:SetEffectiveness(old_effectiveness + buff_value)
    inst.washer_old_effectiveness = not old_waterproofer and nil or old_effectiveness
  elseif buff_name == "combat_damage_modifier" then
    local old_onequipfn = inst.components.equippable.onequipfn
    local old_onunequipfn = inst.components.equippable.onunequipfn
    inst.components.equippable:SetOnEquip(function(inst, owner)
      old_onequipfn(inst, owner)
      if owner.components.combat then
        owner.components.combat.externaldamagemultipliers:SetModifier(inst, buff_value)
      end
    end)
    inst.components.equippable:SetOnUnequip(function(inst, owner)
      old_onunequipfn(inst, owner)
      if owner.components.combat then
        owner.components.combat.externaldamagemultipliers:RemoveModifier(inst)
      end
    end)
    inst.washer_old_onequipfn = old_onequipfn
    inst.washer_old_onunequipfn = old_onunequipfn
  elseif buff_name == "combat_taken_modifier" then
    local old_onequipfn = inst.components.equippable.onequipfn
    local old_onunequipfn = inst.components.equippable.onunequipfn
    inst.components.equippable:SetOnEquip(function(inst, owner)
      old_onequipfn(inst, owner)
      if owner.components.combat then
        owner.components.combat.externaldamagetakenmultipliers:SetModifier(inst, buff_value)
      end
    end)
    inst.components.equippable:SetOnUnequip(function(inst, owner)
      old_onunequipfn(inst, owner)
      if owner.components.combat then
        owner.components.combat.externaldamagetakenmultipliers:RemoveModifier(inst)
      end
    end)
    inst.washer_old_onequipfn = old_onequipfn
    inst.washer_old_onunequipfn = old_onunequipfn
  end
  
  inst.washer_buff_name = buff_name
end

local function RemoveBuff(inst, data)
  if data and data.name ~= "buffover" then
    return
  elseif inst.washer_buff_name == nil then
    return
  elseif inst.washer_buff_name == "walkspeedmult" then
    inst.components.equippable.walkspeedmult = inst.washer_old_walkspeedmult
    inst.washer_old_walkspeedmult = nil
  elseif inst.washer_buff_name == "dapperness" then
    inst.components.equippable.dapperness = inst.washer_old_dapperness
    inst.washer_old_dapperness = nil
  elseif inst.washer_buff_name == "hunger_modifier" or
    inst.washer_buff_name == "health_regen" or
    inst.washer_buff_name == "combat_damage_modifier" or
    inst.washer_buff_name == "combat_taken_modifier" or
    inst.washer_buff_name == "light_radiu"
  then
    if inst.components.equippable:IsEquipped() then
      local owner = inst.components.inventoryitem and inst.components.inventoryitem:GetGrandOwner()
      if owner then
        if inst.washer_buff_name == "hunger_modifier" then
          owner.components.hunger.burnratemodifiers:RemoveModifier(inst)
        elseif inst.washer_buff_name == "health_regen" then
          if owner.washer_regen_task then
            owner.washer_regen_task:Cancel()
            owner.washer_regen_task = nil
          end
        elseif inst.washer_buff_name == "combat_damage_modifier" then
          owner.components.combat.externaldamagemultipliers:RemoveModifier(inst)
        elseif inst.washer_buff_name == "combat_taken_modifier" then
          owner.components.combat.externaldamagetakenmultipliers:RemoveModifier(inst)
        elseif inst.washer_buff_name == "light_radiu" then
          if owner.washer_buff_light and owner.washer_buff_light:IsValid() then
            owner.washer_buff_light:Remove()
            owner.washer_buff_light = nil
          end
        end
      end
    end
    inst.components.equippable:SetOnEquip(inst.washer_old_onequipfn)
    inst.components.equippable:SetOnUnequip(inst.washer_old_onunequipfn)
    inst.washer_old_onequipfn = nil
    inst.washer_old_onunequipfn = nil
  elseif inst.washer_buff_name == "insulator" then
    if inst.washer_old_insulation ~= nil then
      inst.components.insulator.insulation = inst.washer_old_insulation
      inst.washer_old_insulation = nil
    else
      inst:RemoveComponent("insulator")
    end
  elseif inst.washer_buff_name == "waterproofer" then
    if inst.washer_old_effectiveness ~= nil then
      inst.components.waterproofer:SetEffectiveness(inst.washer_old_effectiveness)
      inst.washer_old_effectiveness = nil
    else
      inst:RemoveComponent("waterproofer")
    end
  end
  
  inst.washer_buff_name = nil
end]]

local function OnStartWashing(inst)
  if not inst:HasTag("burnt") then
    inst.AnimState:PlayAnimation("close")
    inst.AnimState:PushAnimation("closed")
    inst.AnimState:PushAnimation("closed")
    inst.AnimState:PushAnimation("closed")
    inst.AnimState:PushAnimation("closed")
    inst.AnimState:PushAnimation("idle_loop", true)
    inst.SoundEmitter:KillSound("washing")
    inst.SoundEmitter:PlaySound(sound.washing, "washing", .5)
  end
end

local function OnDoneWashing(inst)
  if not inst:HasTag("burnt") then
    inst.AnimState:PlayAnimation("open")
    inst.AnimState:PushAnimation("close")
    inst.AnimState:PushAnimation("closed", false)
    inst.SoundEmitter:KillSound("washing")
    inst.SoundEmitter:PlaySound(sound.open)
    inst:DoTaskInTime(.3,function() inst.SoundEmitter:PlaySound(sound.close) end)
  end
end

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
        if inst.components.container then
          inst.components.container:DropEverything()
        end
        if inst.wash_task then
          inst.wash_task:Cancel()
          inst.wash_task = nil
        end
        inst.SoundEmitter:KillSound("washing")
        inst.AnimState:PlayAnimation("hit")
        inst.AnimState:PushAnimation("closed", false)
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
  DefaultBurntStructureFn(inst)
end

local function OnOpen(inst)
  inst.AnimState:PlayAnimation("open")
  inst.SoundEmitter:PlaySound(sound.open)
end

local function OnClose(inst)
  inst.SoundEmitter:PlaySound(sound.close)
  inst.AnimState:PlayAnimation("close")
  inst.AnimState:PushAnimation("closed", false)
end

local function StartWork(inst)
  local item = inst.components.container:GetItemInSlot(1)
  if item then
    inst.components.container.canbeopened = false
    OnStartWashing(inst)
    inst:DoTaskInTime(17, function()
      if item.components.inventoryitemmoisture then
	    	item.components.inventoryitemmoisture:SetMoisture(0)
	    end
      inst.components.container:DropEverything()
      inst.components.container.canbeopened = true
      OnDoneWashing(inst)
    end)
  end
end

local function onsave(inst, data)
    if inst:HasTag("burnt") or (inst.components.burnable ~= nil and inst.components.burnable:IsBurning()) then
        data.burnt = true
    end
end

local function onload(inst, data)
    if data and data.burnt then
      inst.components.burnable.onburnt(inst)
    else
      if not inst.components.container:IsEmpty() then
        inst.components.container.onclosefn(inst)
      end
    end
end

--[[local function ShouldAcceptItem(inst, item, giver)
  if item == nil then
    return
  elseif item.washer_buff_name then
    if giver and giver.components.talker then
      giver.components.talker:Say(STRINGS.OWN_WASHER_BUFF)--"过一会再来吧.."
    end
    return false
  elseif not item:HasTag("_equippable") or item:HasAnyTag("tool", "weapon", "pocketwatch", "icebox_valid") then
    if giver and giver.components.talker then
      giver.components.talker:Say(STRINGS.NEED_NOT_WASH)--"这个好像不能洗吧.."
    end
    return false
  elseif inst.components.inventory:IsFull() then
    if giver and giver.components.talker then
      giver.components.talker:Say(STRINGS.CHARACTERS.WURT.ACTIONFAIL.CHANGEIN.INUSE)--"得等等……"
    end
    return false
  end
  return not inst:HasTag("burnt")
end

local function OnGetItemFromPlayer(inst, giver, item)
    OnStartWashing(inst)
    inst:DoTaskInTime(17, function()
      if item.components.inventoryitemmoisture then
	    	item.components.inventoryitemmoisture:SetMoisture(0)
	    end
      
      --RemoveBuff(item)
      --GetRandomBuff(item)
      --if item.components.timer == nil then
      --  item:AddComponent("timer")
      --end
      --item.components.timer:StartTimer("buffover", 480)
      --item:ListenForEvent("timerdone", RemoveBuff)
      
      inst.components.inventory:DropEverything()
      OnDoneWashing(inst)
    end)
end]]

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
    inst:AddTag("jx_washer")
    
    inst.AnimState:SetBank("jx_washer")
    inst.AnimState:SetBuild("jx_washer")
    inst.AnimState:PlayAnimation("closed")
    
    inst.MiniMapEntity:SetIcon("jx_washer.tex")
    
    inst.entity:SetPristine()
    
    if not TheWorld.ismastersim then
        return inst
    end
    
    inst:AddComponent("inspectable")
    
    inst:AddComponent("lootdropper")
    
    --inst:AddComponent("inventory")
    --inst.components.inventory.maxslots = 1
    
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)
    
    --[[inst:AddComponent("trader")
    inst.components.trader:SetAcceptTest(ShouldAcceptItem)
    inst.components.trader:SetOnAccept(OnGetItemFromPlayer)
    inst.components.trader.deleteitemonaccept = false]] 
    
    inst:AddComponent("container")
    inst.components.container:WidgetSetup("jx_washer")
    inst.components.container.onopenfn = OnOpen
    inst.components.container.onclosefn = OnClose
    inst.components.container.skipclosesnd = true
    inst.components.container.skipopensnd = true
    
    inst:ListenForEvent("onbuilt", onbuilt)
    
    MakeMediumBurnable(inst, nil, nil, true)
    inst.components.burnable:SetOnBurntFn(onburnt)
    MakeSmallPropagator(inst)
    
    inst.OnSave = onsave
    inst.OnLoad = onload
    
    inst.StartWork = StartWork
    
    return inst
end

return Prefab("jx_washer", fn, assets, prefabs),
    MakePlacer("jx_washer_placer", "jx_washer", "jx_washer", "idle")
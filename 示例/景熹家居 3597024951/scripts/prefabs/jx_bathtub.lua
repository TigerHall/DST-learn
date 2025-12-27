local assets =
{
    Asset("ANIM", "anim/jx_bathtub.zip"),
}

local prefabs =
{
  "collapse_big",
  "crater_steam_fx1",
  "crater_steam_fx2",
  "crater_steam_fx3",
  "crater_steam_fx4",
  "slow_steam_fx1",
  "slow_steam_fx2",
  "slow_steam_fx3",
  "slow_steam_fx4",
  "slow_steam_fx5",
}

local function stopsleepsound(inst)
    inst.SoundEmitter:PlaySound("jx_sound_2/jx_sound_2/bathtub_close")
    inst.SoundEmitter:KillSound("loop")
end

local function startsleepsound(inst)
    stopsleepsound(inst)
    inst.SoundEmitter:PlaySound("jx_sound_2/jx_sound_2/bathtub_open")
    inst.SoundEmitter:PlaySound("jx_sound_2/jx_sound_2/bathtub_loop", "loop")
end

local function onhammered(inst, worker)
    inst.components.lootdropper:DropLoot()
    local fx = SpawnPrefab("collapse_big")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("metal")
    inst:Remove()
end

local function onhit(inst, worker)
    stopsleepsound(inst)
    inst.SoundEmitter:PlaySound("jx_sound_2/jx_sound_2/bathtub_close")
    inst.AnimState:PlayAnimation("hit")
    inst.AnimState:PushAnimation("idle", true)
    inst.components.machine.ison = false
    if inst:HasTag("hasplayer") then
      local player = inst.components.jx_bath.current_player
      if player and player.bathtub == inst then
        inst:PushEvent("onstopbath", {player = player})
        player.bathtub = nil
        player:DoTaskInTime(0,function() 
          player.sg:GoToState("idle")
        end)
        player:DoTaskInTime(1,function() 
          if player.components.talker then
            player.components.talker:Say(STRINGS.JX_WHAT_ARE_YOU_DOING)
          end
        end)
      end
    end
end

local function OnBuilt(inst)
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("idle", true)
end

local function OnStartBath(inst, data)
  inst.components.machine:TurnOff()
  startsleepsound(inst)
  
  local player = data and data.player
  if player and player:IsValid() then
    inst.components.jx_bath:StartBath(player)
  end
  
  inst.bath_fx_task = inst:DoPeriodicTask(1,function()
    local function GetRandomPos()
      local radius = math.random() * 0.5
      local theta = math.random(TWOPI)
      local pos = inst:GetPosition()
      local offset = Vector3(radius * math.cos( theta ), 0, -radius * math.sin( theta ))
      return pos + offset
    end
    SpawnPrefab("crater_steam_fx"..math.random(4)).Transform:SetPosition(GetRandomPos():Get())
    SpawnPrefab("slow_steam_fx"..math.random(5)).Transform:SetPosition(GetRandomPos():Get())
  end)
end

local function OnStopBath(inst, data)
  inst.components.machine:TurnOn()
  stopsleepsound(inst)
  
  inst.components.finiteuses:Use()
  local player = data and data.player
  if player and player:IsValid() then
    inst.components.jx_bath:StopBath(player)
  end
  
  if inst.bath_fx_task then
    inst.bath_fx_task:Cancel()
    inst.bath_fx_task = nil
  end
end

local function onfinished(inst)
  inst:AddTag("NOCLICK")
  local life = 48
  local color = 1
  inst.colortask = inst:DoPeriodicTask(FRAMES,function()
    if life >= 1 then
      inst.AnimState:SetMultColour(1, 1, 1, color)
      life = life - 1
      color = color - 0.02
    else
      if inst.colortask then
        inst.colortask:Cancel()
        inst.colortask = nil
      end
      inst:Remove()
    end
  end)
end

local function ShouldAcceptItem(inst, item, giver)
  return item and item.prefab == "cutstone" and 
    inst.components.finiteuses and inst.components.finiteuses:GetPercent() < 1
end

local function OnGetItemFromPlayer(inst, giver, item)
    inst.components.finiteuses:SetPercent(1)
end

local function turnon(inst)
  inst.SoundEmitter:PlaySound("jx_sound_2/jx_sound_2/bathtub_open")
  inst.components.machine.ison = true
  inst.AnimState:PlayAnimation("open")
end

local function turnoff(inst)
  inst.SoundEmitter:PlaySound("jx_sound_2/jx_sound_2/bathtub_close")
  inst.components.machine.ison = false
  inst.AnimState:PlayAnimation("close")
  inst.AnimState:PushAnimation("closed", false)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

	  inst:SetDeploySmartRadius(1.6) --recipe min_spacing/2
    MakeObstaclePhysics(inst, 1)

    inst:AddTag("structure")
    inst:AddTag("jx_bathtub")

    inst.AnimState:SetBank("jx_bathtub")
    inst.AnimState:SetBuild("jx_bathtub")
    inst.AnimState:PlayAnimation("idle")

    inst.MiniMapEntity:SetIcon("jx_bathtub.tex")

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

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetOnFinished(onfinished)
    inst.components.finiteuses:SetMaxUses(50)
    inst.components.finiteuses:SetUses(50)
    
    inst:AddComponent("trader")
    inst.components.trader:SetAcceptTest(ShouldAcceptItem)
    inst.components.trader:SetOnAccept(OnGetItemFromPlayer)
    
    inst:AddComponent("machine")
    inst.components.machine.turnonfn = turnon
    inst.components.machine.turnofffn = turnoff
    inst.components.machine.cooldowntime = 0
    inst.components.machine.ison = false
    
    inst:AddComponent("jx_bath")
    inst:ListenForEvent("onstartbath", OnStartBath)
    inst:ListenForEvent("onstopbath", OnStopBath)

    SetLunarHailBuildupAmountLarge(inst)
    inst:ListenForEvent("onbuilt", OnBuilt)
    
    MakeHauntableWork(inst)

    return inst
end

return Prefab("jx_bathtub", fn, assets, prefabs),
    MakePlacer("jx_bathtub_placer", "jx_bathtub", "jx_bathtub", "idle")
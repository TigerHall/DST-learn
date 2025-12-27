local assets =
{
    Asset("ANIM", "anim/jx_fan.zip"),
}

local prefabs =
{
    "collapse_small",
}

local sounds = 
{
  open = "jx_sound_4/jx_sound_4/open",
  --close = "jx_sound_4/jx_sound_4/close",
  loop = "jx_sound_4/jx_sound_4/loop",
}

local function fan_turnoff(inst)
    inst.components.machine.ison = false
    inst:Change_Task(false)
    --inst.SoundEmitter:PlaySound(sounds.close)
    inst.SoundEmitter:KillSound("loop")
    inst.AnimState:PlayAnimation("deactivate")
    inst.AnimState:PushAnimation("idle_off", false)
    if inst.loop_sound_task then
      inst.loop_sound_task:Cancel()
      inst.loop_sound_task = nil
    end
end

local function fan_turnon(inst)
    inst.components.machine.ison = true
    inst:Change_Task(true)
    inst.SoundEmitter:PlaySound(sounds.open)
    inst.loop_sound_task = inst:DoTaskInTime(1,function() inst.SoundEmitter:PlaySound(sounds.loop, "loop") end)
    inst.AnimState:PlayAnimation("activate")
    inst.AnimState:PushAnimation("deactivate")
    inst.AnimState:PushAnimation("activate")
    inst.AnimState:PushAnimation("deactivate")
    inst.AnimState:PushAnimation("activate")
    inst.AnimState:PushAnimation("idle_loop", true)
end

local function onworkfinished(inst)
    inst.components.lootdropper:DropLoot()
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("metal")
    inst:Remove()
end

local function onworked(inst, worker, workleft)
    if workleft > 0 then 
      if inst.components.machine.ison then
        inst.AnimState:PlayAnimation("hit_on")
        inst.AnimState:PushAnimation("idle_loop", true)
      else
        inst.AnimState:PlayAnimation("hit_off")
        inst.AnimState:PushAnimation("idle_off", false)
      end
    end
end

local function Change_Task(inst, turn_on)
  if inst.Task then
    inst.Task:Cancel()
    inst.Task = nil
  end
  if turn_on then
    inst.Task = inst:DoPeriodicTask(2, function()
        local x, y, z = inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, y, z, 7, nil, {"snuffed", "INLIMBO", "playerghost",}, {"player", "smolder", "fire",})
        for k, v in pairs(ents) do
          if not v:IsValid() or v:IsInLimbo() then
            return
          end
          if v:HasTag("player") then
            if v.components.health and not v.components.health:IsDead() and v.components.temperature then
              local tem = v.components.temperature:GetCurrent()
              if tem > 10 then
                local delta_tem
                if tem > 60 then
                  delta_tem = -0.1 * math.random(30,40)
                else
                  delta_tem = -0.1 * math.random(10,25)
                end
                v.components.temperature:SetTemperature(tem + delta_tem)
              end
            end
          elseif v.components.burnable then
            if v.components.burnable:IsBurning() then
              v.components.burnable:Extinguish()
            elseif v.components.burnable:IsSmoldering() then
              v.components.burnable:SmotherSmolder()
            end
          end
        end
    end)
  end
end


local function fn()
    local inst = CreateEntity()
    
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddFollower()
    inst.entity:AddNetwork()
    
    MakeInventoryPhysics(inst)
    
    inst.AnimState:SetBank("jx_fan")
    inst.AnimState:SetBuild("jx_fan")
    inst.AnimState:PlayAnimation("idle_off")
    
    MakeInventoryFloatable(inst, "small", 0.065, 0.85)
    
    inst.entity:SetPristine()
    
    if not TheWorld.ismastersim then
        return inst
    end
    
    inst:AddComponent("furnituredecor")    
    
    inst:AddComponent("inspectable")
    
    inst:AddComponent("lootdropper")
    
    local inventoryitem = inst:AddComponent("inventoryitem")
    inventoryitem:SetOnPutInInventoryFn(fan_turnoff)
    
    local workable = inst:AddComponent("workable")
    workable:SetWorkAction(ACTIONS.HAMMER)
    workable:SetWorkLeft(3)
    workable:SetOnFinishCallback(onworkfinished)
    workable:SetOnWorkCallback(onworked)
    
    local machine = inst:AddComponent("machine")
    machine.turnonfn = fan_turnon
    machine.turnofffn = fan_turnoff
    machine.cooldowntime = 3
    
    MakeHauntable(inst)
    
    inst.Task = nil
    inst.Change_Task = Change_Task
    
    return inst
end

return Prefab("jx_fan", fn, assets, prefabs)
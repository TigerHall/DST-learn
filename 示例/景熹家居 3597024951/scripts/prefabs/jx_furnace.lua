require "prefabutil"

local prefabs =
{
    "collapse_big",
}

local assets =
{
    Asset("ANIM", "anim/jx_furnace.zip"),
    Asset("ANIM", "anim/ui_backpack_2x4.zip"),
    Asset("MINIMAP_IMAGE", "jx_furnace"),
}

local function onworkfinished(inst)
    inst.components.lootdropper:DropLoot()
    local fx = SpawnPrefab("collapse_big")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("metal")
    inst:Remove()
end

local function onworked(inst)
    --[[if inst._task2 ~= nil then
        inst._task2:Cancel()
        inst._task2 = nil

		if not inst:IsAsleep() then
			inst.SoundEmitter:PlaySound("dontstarve/common/together/dragonfly_furnace/fire_LP", "loop")
		end

        if inst._task1 ~= nil then
            inst._task1:Cancel()
            inst._task1 = nil
        end
    end]]
    if inst.components.machine.ison then
      inst.AnimState:PlayAnimation("hit_on")
    else
      inst.AnimState:PlayAnimation("hit_off")
    end

    if inst.components.container ~= nil then
        inst.components.container:DropEverything()
        inst.components.container:Close()
    end
end

--[[local function BuiltTimeLine1(inst)
    inst._task1 = nil
    inst.SoundEmitter:PlaySound("dontstarve/common/fireAddFuel")
end]]

--[[local function BuiltTimeLine2(inst)
    inst._task2 = nil
    inst.SoundEmitter:PlaySound("dontstarve/common/together/dragonfly_furnace/light")
	if not inst:IsAsleep() then
		inst.SoundEmitter:PlaySound("dontstarve/common/together/dragonfly_furnace/fire_LP", "loop")
	end
end]]

local function onbuilt(inst)
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("idle_on")
    inst.SoundEmitter:KillSound("loop")
    --inst.SoundEmitter:PlaySound("dontstarve/common/together/dragonfly_furnace/place")
    --[[if inst._task2 ~= nil then
        inst._task2:Cancel()
        if inst._task1 ~= nil then
            inst._task1:Cancel()
        end
    end]]
    --inst._task1 = inst:DoTaskInTime(30 * FRAMES, BuiltTimeLine1)
    --inst._task2 = inst:DoTaskInTime(40 * FRAMES, BuiltTimeLine2)
end

--[[local function onsavesalad(inst, data)
    data.salad = true
end]]

--[[local function makesalad(inst)
    inst.AnimState:SetMultColour(.1, 1, .1, 1)

    inst:AddComponent("named")
    inst.components.named:SetName("Salad Furnace")

    inst.OnSave = onsavesalad
end]]

local function onsave(inst, data)
    if inst.components.machine.ison then
      data.turnon = true
    end
end

local function onload(inst, data)
    --[[if data ~= nil and data.salad then
        makesalad(inst)
    end]]
    if data then
      if data.turnon then
        inst.components.machine:TurnOn()
      else
        inst.components.machine:TurnOff()
      end
    end
end

local function _CanBeOpened(inst)
    inst.components.container.canbeopened = true
end

local function OnIncinerateItems(inst)
    inst.AnimState:PlayAnimation("incinerate")
    inst.AnimState:PushAnimation("incinerate")
    inst.AnimState:PushAnimation("idle_on", false)

    inst.SoundEmitter:PlaySound("dontstarve/common/fireAddFuel")

    inst.components.container:Close()
    inst.components.container.canbeopened = false

    --local time = inst.AnimState:GetCurrentAnimationLength() - inst.AnimState:GetCurrentAnimationTime() + FRAMES

    inst:DoTaskInTime(FRAMES * 10, _CanBeOpened)
end

local function ShouldIncinerateItem(inst, item)
    local incinerate = true

    --[[if item.prefab == "winter_food4" then
        incinerate = false]]
    if item:HasTag("irreplaceable") then
        incinerate = false
    elseif item.components.container ~= nil and not item.components.container:IsEmpty() then
        incinerate = false
    end

    return incinerate
end

local function turnon(inst)
  if inst.Light then
    inst.Light:Enable(true)
  end
  inst.AnimState:PlayAnimation("idle_on")
  
  inst.SoundEmitter:PlaySound("jx_sound_1/jx_sound_1/furnace_on")
  inst.SoundEmitter:PlaySound("dontstarve/common/together/dragonfly_furnace/fire_LP", "loop", .7)
  inst:AddTag("cooker")
  
  inst.components.machine.ison = true
  inst.components.heater.heat = 115
  inst.components.container.canbeopened = true
end

local function turnoff(inst)
  if inst.Light then
    inst.Light:Enable(false)
  end
  inst.AnimState:PlayAnimation("idle_off")
  inst.SoundEmitter:PlaySound("jx_sound_1/jx_sound_1/furnace_off")
  inst.SoundEmitter:KillSound("loop")
  inst:RemoveTag("cooker")
  
  inst.components.machine.ison = false
  inst.components.heater.heat = 0
  inst.components.container.canbeopened = false
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

	  inst:SetDeploySmartRadius(1.25)
    MakeObstaclePhysics(inst, .5)

    inst.MiniMapEntity:SetIcon("jx_furnace.tex")

    inst.Light:Enable(true)
    inst.Light:SetRadius(1)
    inst.Light:SetFalloff(.33)
    inst.Light:SetIntensity(.8)
    inst.Light:SetColour(235 / 255, 121 / 255, 12 / 255)

    inst.AnimState:SetBank("jx_furnace")
    inst.AnimState:SetBuild("jx_furnace")
    inst.AnimState:PlayAnimation("idle_on")
    --inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    --inst.AnimState:SetLightOverride(0.4)

    inst:AddTag("structure")
    inst:AddTag("wildfireprotected")

    inst:AddTag("HASHEATER")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    -----------------------
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(onworkfinished)
    inst.components.workable:SetOnWorkCallback(onworked)

    -----------------------
    inst:AddComponent("container")
    inst.components.container:WidgetSetup("jx_furnace")

    -----------------------
    inst:AddComponent("incinerator")
    inst.components.incinerator:SetOnIncinerateFn(OnIncinerateItems)
    inst.components.incinerator:SetShouldIncinerateItemFn(ShouldIncinerateItem)

    -----------------------
    inst:AddComponent("cooker")
    inst:AddComponent("lootdropper")

    -----------------------
    inst:AddComponent("inspectable")
    -----------------------
    inst:AddComponent("heater")
    inst.components.heater.heat = 115
    --------------------------
    inst:AddComponent("machine")
    inst.components.machine.turnonfn = turnon
    inst.components.machine.turnofffn = turnoff
    inst.components.machine.cooldowntime = 0
    inst.components.machine.ison = true

    -----------------------
    --MakeHauntableWork(inst)

    inst:ListenForEvent("onbuilt", onbuilt)
    inst.OnSave = onsave
    inst.OnLoad = onload

    return inst
end

return Prefab("jx_furnace", fn, assets, prefabs),
       MakePlacer("jx_furnace_placer", "jx_furnace", "jx_furnace", "idle_off")
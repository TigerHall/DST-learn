local assets =
{
    Asset("ANIM", "anim/jx_lamp.zip"),
}

local LAMP_LIGHT_COLOUR = Vector3(180 / 255, 195 / 255, 150 / 255)

local function lamp_turnoff(inst)
    if inst.Light then
        inst.Light:Enable(false)
    end
    --inst.SoundEmitter:PlaySound("dontstarve/wilson/lantern_off", nil, .7)
    inst.components.fueled:StopConsuming()
    inst.components.machine.ison = false
    if not inst:HasTag("burnt") then
      inst.AnimState:PlayAnimation("idle_off")
    end
end

local function lamp_fuelupdate(inst)
    local fuelpercent = inst.components.fueled:GetPercent()
    if inst.Light then
        inst.Light:SetIntensity(Lerp(0.4, 0.6, fuelpercent))
        inst.Light:SetRadius(Lerp(2, 4, fuelpercent))
    end
end

local function lamp_turnon(inst)
    local fueled = inst.components.fueled
    if fueled:IsEmpty() or inst.components.inventoryitem:IsHeld() then return end

    fueled:StartConsuming()
    if inst.Light then
        inst.Light:Enable(true)
    end
    --inst.SoundEmitter:PlaySound("dontstarve/wilson/lantern_on", nil, .7)
    inst.components.machine.ison = true
    if not inst:HasTag("burnt") then
      inst.AnimState:PlayAnimation("idle_on")
    end
end

local function lamp_ondropped(inst)
    lamp_turnoff(inst)
    lamp_turnon(inst)
end

local function onburnt(inst)
  inst:AddTag("burnt")
  inst.AnimState:PlayAnimation("burnt", true)
  inst.components.fueled:SetPercent(0)
  inst.components.fueled.accepting = false
  inst.components.machine.enabled = false
end

local function onsave(inst, data)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() or inst:HasTag("burnt") then
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
    inst.entity:AddFollower()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("jx_lamp")
    inst.AnimState:SetBuild("jx_lamp")
    inst.AnimState:PlayAnimation("idle_off")

    inst:AddTag("furnituredecor")

    inst.Light:SetIntensity(0.4)
    inst.Light:SetColour(LAMP_LIGHT_COLOUR.x, LAMP_LIGHT_COLOUR.y, LAMP_LIGHT_COLOUR.z)
    inst.Light:SetFalloff(0.8)
    inst.Light:SetRadius(2)
    inst.Light:Enable(false)

    MakeInventoryFloatable(inst, "small", 0.065, 0.85)

    inst.entity:SetPristine()
    
    if not TheWorld.ismastersim then
        return inst
    end

    --
    local fueled = inst:AddComponent("fueled")
    fueled.fueltype = FUELTYPE.CAVE
    fueled:InitializeFuelLevel(TUNING.LANTERN_LIGHTTIME)
    fueled:SetDepletedFn(lamp_turnoff)
    fueled:SetUpdateFn(lamp_fuelupdate)
    fueled:SetTakeFuelFn(lamp_turnon)
    fueled:SetFirstPeriod(TUNING.TURNON_FUELED_CONSUMPTION, TUNING.TURNON_FULL_FUELED_CONSUMPTION)
    fueled.accepting = true

    --
    local furnituredecor = inst:AddComponent("furnituredecor")
    furnituredecor.onputonfurniture = lamp_ondropped

    --
    inst:AddComponent("inspectable")

    --
    local inventoryitem = inst:AddComponent("inventoryitem")
    inventoryitem:SetOnDroppedFn(lamp_ondropped)
    inventoryitem:SetOnPutInInventoryFn(lamp_turnoff)

    --
    local machine = inst:AddComponent("machine")
    machine.turnonfn = lamp_turnon
    machine.turnofffn = lamp_turnoff
    machine.cooldowntime = 0

    --
    MakeHauntable(inst)

    --
    MakeSmallBurnable(inst)
    inst.components.burnable:SetOnBurntFn(onburnt)
    MakeSmallPropagator(inst)
    
    inst.OnSave = onsave
    inst.OnLoad  = onload

    return inst
end

return Prefab("jx_lamp", fn, assets)
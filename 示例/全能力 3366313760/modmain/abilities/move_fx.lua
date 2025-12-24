local MOVE_FX = GetModConfigData("move_fx")

local PLANTS_RANGE = 1
local MAX_PLANTS = 18

local PLANTFX_TAGS = { "wormwood_plant_fx" }
local function PlantTick(inst)
    if inst.sg:HasStateTag("ghostbuild") or inst.components.health:IsDead() or not inst.entity:IsVisible() then
        return
    end

    if inst.components.health:GetPercent() < math.random() or inst:GetCurrentPlatform() then
        return
    end

    local x, y, z = inst.Transform:GetWorldPosition()
    if #TheSim:FindEntities(x, y, z, PLANTS_RANGE, PLANTFX_TAGS) < MAX_PLANTS then
        local map = TheWorld.Map
        local pt = Vector3(0, 0, 0)
        local offset = FindValidPositionByFan(
            math.random() * TWOPI,
            math.random() * PLANTS_RANGE,
            3,
            function(offset)
                pt.x = x + offset.x
                pt.z = z + offset.z
                return map:CanPlantAtPoint(pt.x, 0, pt.z)
                    and #TheSim:FindEntities(pt.x, 0, pt.z, .5, PLANTFX_TAGS) < 3
                    and map:IsDeployPointClear(pt, nil, .5)
                    and not map:IsPointNearHole(pt, .4)
            end
        )
        if offset then
            local plant = SpawnPrefab("wormwood_plant_fx")
            plant.Transform:SetPosition(x + offset.x, 0, z + offset.z)
            --randomize, favoring ones that haven't been used recently
            local rnd = math.random()
            rnd = table.remove(inst._aab_plantpool, math.clamp(math.ceil(rnd * rnd * #inst._aab_plantpool), 1, #inst._aab_plantpool))
            table.insert(inst._aab_plantpool, rnd)
            plant:SetVariation(rnd)
        end
    end
end

local function GetFx(inst)
    if inst._aab_move_fx and inst._aab_move_fx:IsValid() then
        return inst._aab_move_fx
    end

    local fx = SpawnPrefab(MOVE_FX)
    fx.entity:AddFollower()
    fx.entity:SetParent(inst.entity)
    inst._aab_move_fx = fx
    return fx
end

local function Init(inst)
    if MOVE_FX == "grass" then
        inst._aab_plantpool = { 1, 2, 3, 4 }
        inst:DoPeriodicTask(.25, PlantTick)
    else
        local fx = GetFx(inst)
        fx.Follower:FollowSymbol(inst.GUID, "swap_body", 0, 0, 0)
    end
end

local function OnEquip(inst, data)
    if data and data.eslot == EQUIPSLOTS.HANDS then
        local fx = GetFx(inst)
        fx.Follower:FollowSymbol(inst.GUID, "swap_object", 0, -105, 0)
    end
end
local function OnUnequip(inst, data)
    if data and data.eslot == EQUIPSLOTS.HANDS then
        local fx = GetFx(inst)
        fx.Follower:FollowSymbol(inst.GUID, "swap_body", 0, 0, 0)
    end
end

AddPlayerPostInit(function(inst)
    if not TheWorld.ismastersim then return end

    inst:DoTaskInTime(0, Init)

    if MOVE_FX ~= "grass" then
        inst:ListenForEvent("equip", OnEquip)
        inst:ListenForEvent("unequip", OnUnequip)
    end
end)

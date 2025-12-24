local NOT_DROP = GetModConfigData("not_drop")
local Utils = require("aab_utils/utils")


-- 禁止对drownable.enabled修改，遇事不决就刷帧
local function Update(inst)
    if inst.components.drownable and inst.components.drownable.enabled and not TheWorld:HasTag("cave") then
        inst.components.drownable.enabled = false
    end
end
----------------------------------------------------------------------------------------------------

local function SetWereDrowning(inst, enable)
    inst._aab_ignore_reset_colliders = true
    --V2C: drownable HACKS, using "false" to override "nil" load behaviour
    --     Please refactor drownable to use POST LOAD timing.
    if inst.components.drownable ~= nil then
        if enable and not TheWorld:HasTag("cave") then
            if inst.components.drownable.enabled ~= false then
                inst.components.drownable.enabled = false
                inst.Physics:ClearCollisionMask()
                inst.Physics:CollidesWith(COLLISION.GROUND)
                inst.Physics:CollidesWith(COLLISION.OBSTACLES)
                inst.Physics:CollidesWith(COLLISION.SMALLOBSTACLES)
                inst.Physics:CollidesWith(COLLISION.CHARACTERS)
                inst.Physics:CollidesWith(COLLISION.GIANTS)
                inst.Physics:Teleport(inst.Transform:GetWorldPosition())
            end
        elseif inst.components.drownable.enabled == false then
            inst.components.drownable.enabled = true
            if not inst:HasTag("playerghost") then
                inst.Physics:ClearCollisionMask()
                inst.Physics:CollidesWith(COLLISION.WORLD)
                inst.Physics:CollidesWith(COLLISION.OBSTACLES)
                inst.Physics:CollidesWith(COLLISION.SMALLOBSTACLES)
                inst.Physics:CollidesWith(COLLISION.CHARACTERS)
                inst.Physics:CollidesWith(COLLISION.GIANTS)
                inst.Physics:Teleport(inst.Transform:GetWorldPosition())
            end
        end
    end
    inst._aab_ignore_reset_colliders = nil
end

local GOOSE_FLAP_STATES =
{
    ["idle"] = true,
    ["run_start"] = true,
    ["run"] = true,
    ["weregoose_takeoff"] = true,
    --["run_stop"] = true,
}

local function DoRipple(inst)
    if inst.components.drownable ~= nil and inst.components.drownable:IsOverWater() then
        SpawnPrefab("weregoose_ripple" .. tostring(math.random(2))).entity:SetParent(inst.entity)
    end
end

local function OnNewGooseState(inst, data)
    if not GOOSE_FLAP_STATES[data.statename] or (inst.components.grogginess ~= nil and inst.components.grogginess.isgroggy) then
        if inst.gooserippletask == nil then
            inst.gooserippletask = inst:DoPeriodicTask(.7, DoRipple, FRAMES)
        end
    else
        if inst.gooserippletask ~= nil then
            inst.gooserippletask:Cancel()
            inst.gooserippletask = nil
        end
    end
end


local function OnReSpawnedFromGhost(inst)
    SetWereDrowning(inst, false)
    inst:RemoveEventCallback("newstate", OnNewGooseState)

    SetWereDrowning(inst, true)
    inst:ListenForEvent("newstate", OnNewGooseState)
    if inst.sg and inst.sg.currentstate then
        OnNewGooseState(inst, { statename = inst.sg.currentstate.name })
    end
end

AddPlayerPostInit(function(inst)
    if not TheWorld.ismastersim then return end

    inst:ListenForEvent("ms_respawnedfromghost", function(inst) inst:DoTaskInTime(0, OnReSpawnedFromGhost) end)
    OnReSpawnedFromGhost(inst)

    inst:DoPeriodicTask(0.1, Update)
end)

----------------------------------------------------------------------------------------------------

Utils.FnDecorator(GLOBAL, "PlayFootstep", function(inst)
    if inst:HasTag("player") and inst.components.drownable and not inst.components.drownable.enabled and inst.components.drownable:IsOverWater() then
        SpawnPrefab("weregoose_splash_med" .. tostring(math.random(2))).entity:SetParent(inst.entity)
        if NOT_DROP == 1 and inst.components.hunger then
            inst.components.hunger:DoDelta(-0.5)
        end
    end
end)

----------------------------------------------------------------------------------------------------
-- 禁止对碰撞类型修改
local PHYSICS_ENT_MAP = {}
Utils.FnDecorator(Entity, "AddPhysics", nil, function(retTab, ent)
    local inst = Ents[ent:GetGUID()]
    local anim = retTab[1]
    if anim and inst then
        PHYSICS_ENT_MAP[anim] = inst
        inst:ListenForEvent("onremove", function() PHYSICS_ENT_MAP[anim] = nil end)
    end
    return retTab
end)

local function Reset(inst)
    if not inst:HasTag("playerghost") then
        SetWereDrowning(inst, false)
        SetWereDrowning(inst, true)
    end
    inst._aab_reset_colliderstask = nil
end

local function SetCollisionBefore(self)
    local inst = PHYSICS_ENT_MAP[self]
    if inst and inst:IsValid()
        and not inst._aab_reset_colliderstask    --防止递归
        and not inst._aab_ignore_reset_colliders --优化
        and inst:HasTag("player")                --玩家
        and inst.components.drownable            --主机执行
    then
        inst._aab_reset_colliderstask = inst:DoTaskInTime(0, Reset)
    end
end

Utils.FnDecorator(Physics, "SetCollisionMask", SetCollisionBefore)
Utils.FnDecorator(Physics, "CollidesWith", SetCollisionBefore)

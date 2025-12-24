local Utils = require("aab_utils/utils")
local Constructor = require("aab_utils/constructor")
local GetPrefab = require("aab_utils/getprefab")
local ROLL_DODGE_KEY = GetModConfigData("roll_dodge_key")

table.insert(Assets, Asset("ANIM", "anim/player_actions_roll.zip"))

WHEELER_DODGE_COOLDOWN = 1.5
DODGE_TIMEOUT = 0.25
----------------------------------------------------------------------------------------------------
if ROLL_DODGE_KEY == "RIGHT" then
    --右键
    AAB_AddClickAction(function(inst, target, pos, useitem, right, bufs)
        if #bufs <= 0
            and right
            and not useitem
            and not inst.checkingmapactions
            and not inst:HasTag("aab_roll_dodge_cd")
            and not (inst.replica.rider ~= nil and inst.replica.rider:IsRiding())
        then
            return ACTIONS.AAB_ROLL_DODGE
        end
    end)
else
    --按键
    AddModRPCHandler(modname, "RollDodge", function(inst, x, z)
        if x
            and not GetPrefab.IsEntityDeadOrGhost(inst)
            and inst.sg and not inst.sg:HasStateTag("busy")
        then
            inst:PushBufferedAction(BufferedAction(inst, nil, ACTIONS.AAB_ROLL_DODGE, nil, Vector3(x, 0, z))) --虽然这个也不需要坐标
        end
    end)
    TheInput:AddKeyDownHandler(GLOBAL["KEY_" .. ROLL_DODGE_KEY], function()
        if Utils.IsDefaultScreen()
            and not ThePlayer:HasTag("aab_roll_dodge_cd")
            and not (ThePlayer.replica.rider ~= nil and ThePlayer.replica.rider:IsRiding())
        then
            local pos = TheInput:GetWorldPosition()
            SendModRPCToServer(MOD_RPC[modname]["RollDodge"], pos.x, pos.z)
        end
    end)
end

----------------------------------------------------------------------------------------------------

local function ArriveAnywhere()
    return true
end

Constructor.AddAction({ customarrivecheck = ArriveAnywhere }, "AAB_ROLL_DODGE", AAB_L("Dodge", "闪避"), function(act) return true end, "aab_roll_dodge")


local function OnTimerDone(inst, data)
    if data.name == "aab_roll_dodge_cd" then
        inst:RemoveTag("aab_roll_dodge_cd")
    end
end

AddPlayerPostInit(function(inst)
    if not TheWorld.ismastersim then return end

    inst:ListenForEvent("timerdone", OnTimerDone)
end)

----------------------------------------------------------------------------------------------------

local function OnBlocked(inst)
    SpawnPrefab("shadow_shield" .. math.random(6)).entity:SetParent(inst.entity)
end

AddStategraphState("wilson", State {
    name = "aab_roll_dodge",
    tags = { "busy", "canrotate" },

    onenter = function(inst)
        inst:AddTag("aab_roll_dodge_cd")
        inst.components.timer:StartTimer("aab_roll_dodge_cd", 1.5)

        local buf = inst:GetBufferedAction()
        local pos = buf and buf:GetActionPoint()
        if pos then
            inst:ForceFacePoint(pos)
        end

        inst.sg:SetTimeout(DODGE_TIMEOUT)
        inst.components.locomotor:Stop()
        inst.AnimState:PlayAnimation("slide_pre")
        inst.AnimState:PushAnimation("slide_loop")
        inst.SoundEmitter:PlaySound("meta3/sharkboi/swipe_tail")
        inst.components.locomotor:EnableGroundSpeedMultiplier(false)

        inst.sg.statemem.was_invincible = inst.components.health.invincible
        inst.components.health:SetInvincible(true)

        inst:ListenForEvent("blocked", OnBlocked)

        local fx = SpawnPrefab("cane_rose_fx")
        fx.entity:AddFollower()
        fx.entity:SetParent(inst.entity)
        fx.Follower:FollowSymbol(inst.GUID, "swap_object", 0, 0, 0)
        inst.sg.statemem.fx = fx
    end,

    onupdate = function(inst)
        inst.Physics:SetMotorVelOverride(20, 0, 0)
    end,

    ontimeout = function(inst)
        inst.sg:GoToState("aab_dodge_pst")
    end,

    onexit = function(inst)
        inst.components.locomotor:EnableGroundSpeedMultiplier(true)
        inst.Physics:ClearMotorVelOverride()
        inst.components.locomotor:Stop()

        inst.components.locomotor:SetBufferedAction(nil)
        if not inst.sg.statemem.was_invincible then
            inst.components.health:SetInvincible(false)
        end

        inst:RemoveEventCallback("blocked", OnBlocked)

        if inst.sg.statemem.fx then
            inst.sg.statemem.fx:Remove()
        end
    end,
})

AddStategraphState("wilson", State {
    name = "aab_dodge_pst",
    tags = { "nopredict" },

    onenter = function(inst)
        inst.AnimState:PlayAnimation("slide_pst")
    end,

    events =
    {
        EventHandler("animover", function(inst)
            inst.sg:GoToState("idle")
        end),
    }
})

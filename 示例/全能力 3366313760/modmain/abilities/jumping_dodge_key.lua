local Constructor = require("aab_utils/constructor")
local Utils = require("aab_utils/utils")
local GetPrefab = require("aab_utils/getprefab")
local JUMPING_DODGE_KEY = GetModConfigData("jumping_dodge_key")

if JUMPING_DODGE_KEY == "RIGHT" then
    --右键
    AAB_AddClickAction(function(inst, target, pos, useitem, right, bufs)
        if #bufs <= 0
            and right
            and not useitem
            and not inst.checkingmapactions
            and not (inst.replica.rider ~= nil and inst.replica.rider:IsRiding())
        then
            return ACTIONS.AAB_JUMP_DODGE
        end
    end)
else
    --按键
    AddModRPCHandler(modname, "JumpingDodge", function(inst)
        if not GetPrefab.IsEntityDeadOrGhost(inst)
            and inst.sg and not inst.sg:HasStateTag("busy")
        then
            inst:PushBufferedAction(BufferedAction(inst, nil, ACTIONS.AAB_JUMP_DODGE)) --虽然这个也不需要坐标
        end
    end)
    TheInput:AddKeyDownHandler(GLOBAL["KEY_" .. JUMPING_DODGE_KEY], function()
        if Utils.IsDefaultScreen() and not (ThePlayer.replica.rider ~= nil and ThePlayer.replica.rider:IsRiding()) then
            SendModRPCToServer(MOD_RPC[modname]["JumpingDodge"])
        end
    end)
end

local function ArriveAnywhere()
    return true
end

--不能交给事件处理器来进入state，因为角色不动了才执行，那时候玩家已经没有移动，只能原地跳，但是我希望玩家可以带有移速得起跳，所以需要立即执行
Constructor.AddAction({ customarrivecheck = ArriveAnywhere, instant = true }, "AAB_JUMP_DODGE", AAB_L("Jump", "跳跃"), function(act)
    act.doer.sg:GoToState("aab_jumping_dodge")
    return true
end)

----------------------------------------------------------------------------------------------------

local function ToggleOffPhysics(inst)
    inst.sg.statemem.isphysicstoggle = true
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.GROUND)
end

local function ToggleOnPhysics(inst)
    inst.sg.statemem.isphysicstoggle = nil
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.WORLD)
    inst.Physics:CollidesWith(COLLISION.OBSTACLES)
    inst.Physics:CollidesWith(COLLISION.SMALLOBSTACLES)
    inst.Physics:CollidesWith(COLLISION.CHARACTERS)
    inst.Physics:CollidesWith(COLLISION.GIANTS)
end

local function OnBlocked(inst)
    SpawnPrefab("shadow_shield" .. math.random(6)).entity:SetParent(inst.entity)
end

AddStategraphState("wilson", State {
    name = "aab_jumping_dodge",
    tags = { "nointerrupt", "jumping", "busy", "nopredict", "nomorph", "nosleep" },

    onenter = function(inst)
        inst.AnimState:PlayAnimation("boat_jump_pre")
        inst.AnimState:PushAnimation("boat_jump_pst", false)
        inst.sg.statemem.was_invincible = inst.components.health.invincible
        inst.components.health:SetInvincible(true)
        ToggleOffPhysics(inst)
        inst.sg.statemem.up = true
        --我希望能跳的远一点，把水平速度提高一点
        local vx, vy, vz = inst.Physics:GetMotorVel()
        vx = vx * 1.5
        inst.Physics:SetMotorVel(vx, vy, vz)

        -- inst.SoundEmitter:PlaySound("dontstarve/movement/bodyfall_dirt")
        -- inst.SoundEmitter:PlaySound("dontstarve/common/fishingpole_linebreak")
        inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/swipe")

        inst:ListenForEvent("blocked", OnBlocked)
        inst:ClearBufferedAction() --留着没用
    end,

    onupdate = function(inst)
        local vx, vy, vz = inst.Physics:GetMotorVel()
        if inst.sg.statemem.up then
            inst.Physics:SetMotorVel(vx, 10, vz)
        else
            local x, y, z = inst.Transform:GetWorldPosition()
            if y > .1 then
                inst.Physics:SetMotorVel(vx, -7, vz)
            else
                inst.sg:GoToState("idle")
            end
        end
    end,

    timeline =
    {
        FrameEvent(9, function(inst)
            inst.sg.statemem.up = nil --开始下降
        end),
    },

    events =
    {
        EventHandler("animqueueover", function(inst)
            if inst.AnimState:AnimDone() then
                inst.sg:GoToState("idle")
            end
        end),
    },

    onexit = function(inst)
        if not inst.sg.statemem.was_invincible then
            inst.components.health:SetInvincible(false)
        end
        ToggleOnPhysics(inst)
        inst.Physics:Stop()
        inst:RemoveEventCallback("blocked", OnBlocked)
    end
})

require("stategraphs/commonstates")

local function DoEquipmentFoleySounds(inst)
    for k, v in pairs(inst.components.inventory.equipslots) do
        if v.foleysound ~= nil then
            inst.SoundEmitter:PlaySound(v.foleysound, nil, nil, true)
        end
    end
end

local function DoFoleySounds(inst)
    DoEquipmentFoleySounds(inst)
    if inst.foleysound ~= nil then
        inst.SoundEmitter:PlaySound(inst.foleysound, nil, nil, true)
    end
end

local DoRunSounds = function(inst)
    if inst.sg.mem.footsteps > 3 then
        PlayFootstep(inst, .6, true)
    else
        inst.sg.mem.footsteps = inst.sg.mem.footsteps + 1
        PlayFootstep(inst, 1, true)
    end
end

local function DoHurtSound(inst)
    if inst.hurtsoundoverride ~= nil then
        inst.SoundEmitter:PlaySound(inst.hurtsoundoverride, nil, inst.hurtsoundvolume)
    elseif not inst:HasTag("mime") then
        inst.SoundEmitter:PlaySound((inst.talker_path_override or "dontstarve/characters/") .. (inst.soundsname or inst.prefab) .. "/hurt", nil, inst.hurtsoundvolume)
    end
end

----------------------------------------------------------------------------------------------------

local actionhandlers =
{
    ActionHandler(ACTIONS.CHOP,
        function(inst)
            return not inst.sg:HasStateTag("prechop")
                and (inst.sg:HasStateTag("chopping") and "chop" or "chop_start") or nil
        end),
    ActionHandler(ACTIONS.MINE,
        function(inst)
            return not inst.sg:HasStateTag("premine")
                and (inst.sg:HasStateTag("mining") and "mine" or "mine_start") or nil
        end),
    ActionHandler(ACTIONS.DIG,
        function(inst)
            return not inst.sg:HasStateTag("predig")
                and (inst.sg:HasStateTag("digging") and "dig" or "dig_start") or nil
        end),
    ActionHandler(ACTIONS.PICKUP, "doshortaction"),
    ActionHandler(ACTIONS.PICK, "dolongaction"),
}

local events =
{
    CommonHandlers.OnLocomote(true, false),
    CommonHandlers.OnAttack(),
    CommonHandlers.OnDeath(),
    CommonHandlers.OnAttacked()
}
local states =
{

    State {
        name = "chop_start",
        tags = { "prechop", "working" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("chop_pre")
            inst:AddTag("prechop")
        end,

        events =
        {
            EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg.statemem.chopping = true
                    inst.sg:GoToState("chop")
                end
            end),
        },

        onexit = function(inst)
            if not inst.sg.statemem.chopping then
                inst:RemoveTag("prechop")
            end
        end,
    },
    State {
        name = "chop",
        tags = { "prechop", "chopping", "working" },
        onenter = function(inst)
            inst.sg.statemem.action = inst:GetBufferedAction()
            inst.AnimState:PlayAnimation("chop_loop")
            inst:AddTag("prechop")
        end,

        timeline =
        {
            TimeEvent(2 * FRAMES, function(inst)
                inst:PerformBufferedAction()
            end),

            TimeEvent(9 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("prechop")
                inst:RemoveTag("prechop")
            end),

            TimeEvent(14 * FRAMES, function(inst)
                local act = inst.sg.statemem.action
                if act ~= nil and
                    act:IsValid() and
                    act.target ~= nil and
                    act.target.components.workable ~= nil and
                    act.target.components.workable:CanBeWorked() and
                    act.target:IsActionValid(act.action) and
                    CanEntitySeeTarget(inst, act.target)
                then
                    --No fast-forward when repeat initiated on server
                    inst:ClearBufferedAction()
                    inst:PushBufferedAction(act)
                end
            end),

            TimeEvent(16 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("chopping")
            end),
        },

        events =
        {
            EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    --We don't have a chop_pst animation
                    inst.sg:GoToState("idle")
                end
            end),
        },

        onexit = function(inst)
            inst:RemoveTag("prechop")
        end,
    },

    ----------------------------------------------------------------------------------------------------
    State {
        name = "mine_start",
        tags = { "premine", "working" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("pickaxe_pre")
            inst:AddTag("premine")
        end,

        events =
        {
            EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg.statemem.mining = true
                    inst.sg:GoToState("mine")
                end
            end),
        },

        onexit = function(inst)
            if not inst.sg.statemem.mining then
                inst:RemoveTag("premine")
            end
        end,
    },

    State {
        name = "mine",
        tags = { "premine", "mining", "working" },

        onenter = function(inst)
            inst.sg.statemem.action = inst:GetBufferedAction()
            inst.AnimState:PlayAnimation("pickaxe_loop")
            inst:AddTag("premine")
        end,

        timeline =
        {
            TimeEvent(7 * FRAMES, function(inst)
                if inst.sg.statemem.action ~= nil then
                    PlayMiningFX(inst, inst.sg.statemem.action.target)
                end
                inst.sg.statemem.recoilstate = "mine_recoil"
                inst:PerformBufferedAction()
            end),

            TimeEvent(9 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("premine")
                inst:RemoveTag("premine")
            end),

            TimeEvent(14 * FRAMES, function(inst)
                if inst.sg.statemem.action ~= nil and
                    inst.sg.statemem.action:IsValid() and
                    inst.sg.statemem.action.target ~= nil and
                    inst.sg.statemem.action.target.components.workable ~= nil and
                    inst.sg.statemem.action.target.components.workable:CanBeWorked() and
                    inst.sg.statemem.action.target:IsActionValid(inst.sg.statemem.action.action) and
                    CanEntitySeeTarget(inst, inst.sg.statemem.action.target) then
                    inst:ClearBufferedAction()
                    inst:PushBufferedAction(inst.sg.statemem.action)
                end
            end),
        },

        events =
        {
            EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.AnimState:PlayAnimation("pickaxe_pst")
                    inst.sg:GoToState("idle", true)
                end
            end),
        },

        onexit = function(inst)
            inst:RemoveTag("premine")
        end,
    },

    ----------------------------------------------------------------------------------------------------

    State {
        name = "dig_start",
        tags = { "predig", "working" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("shovel_pre")
            inst:AddTag("predig")
        end,

        events =
        {
            EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg.statemem.digging = true
                    inst.sg:GoToState("dig")
                end
            end),
        },

        onexit = function(inst)
            if not inst.sg.statemem.digging then
                inst:RemoveTag("predig")
            end
        end,
    },

    State {
        name = "dig",
        tags = { "predig", "digging", "working" },

        onenter = function(inst)
            inst.AnimState:PlayAnimation("shovel_loop")
            inst.sg.statemem.action = inst:GetBufferedAction()
            inst:AddTag("predig")
        end,

        timeline =
        {
            TimeEvent(15 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("predig")
                inst:RemoveTag("predig")
                inst.SoundEmitter:PlaySound("dontstarve/wilson/dig")
                inst:PerformBufferedAction()
            end),

            TimeEvent(35 * FRAMES, function(inst)
                if inst.sg.statemem.action ~= nil and
                    inst.sg.statemem.action:IsValid() and
                    inst.sg.statemem.action.target ~= nil and
                    inst.sg.statemem.action.target.components.workable ~= nil and
                    inst.sg.statemem.action.target.components.workable:CanBeWorked() and
                    inst.sg.statemem.action.target:IsActionValid(inst.sg.statemem.action.action, true) and
                    CanEntitySeeTarget(inst, inst.sg.statemem.action.target) then
                    inst:ClearBufferedAction()
                    inst:PushBufferedAction(inst.sg.statemem.action)
                end
            end),
        },

        events =
        {
            EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.AnimState:PlayAnimation("shovel_pst")
                    inst.sg:GoToState("idle", true)
                end
            end),
        },

        onexit = function(inst)
            inst:RemoveTag("predig")
        end,
    },

    ----------------------------------------------------------------------------------------------------
    State {
        name = "doshortaction",
        tags = { "doing", "busy", "keepchannelcasting" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("pickup")
            inst.AnimState:PushAnimation("pickup_pst", false)

            inst.sg.statemem.action = inst.bufferedaction
            inst.sg:SetTimeout(10 * FRAMES)
        end,

        timeline =
        {
            TimeEvent(6 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("busy")
                inst:PerformBufferedAction()
            end),
        },

        ontimeout = function(inst)
            --pickup_pst should still be playing
            inst.sg:GoToState("idle", true)
        end,
    },

    State {
        name = "dolongaction",
        tags = { "doing", "busy", "nodangle", "keep_pocket_rummage" },

        onenter = function(inst, timeout)
            if timeout == nil then
                timeout = 1
            elseif timeout > 1 then
                inst.sg:AddStateTag("slowaction")
            end
            inst.sg:SetTimeout(timeout)
            inst.components.locomotor:Stop()
            inst.SoundEmitter:PlaySound("dontstarve/wilson/make_trap", "make")
            inst.AnimState:PlayAnimation("build_pre")
            inst.AnimState:PushAnimation("build_loop", true)
            if inst.bufferedaction ~= nil then
                inst.sg.statemem.action = inst.bufferedaction
                if inst.bufferedaction.action.actionmeter then
                    inst.sg.statemem.actionmeter = true
                end
                if inst.bufferedaction.target ~= nil and inst.bufferedaction.target:IsValid() then
                    inst.bufferedaction.target:PushEvent("startlongaction", inst)
                end
            end
        end,

        timeline =
        {
            TimeEvent(4 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("busy")
            end),
        },

        ontimeout = function(inst)
            inst.SoundEmitter:KillSound("make")
            inst.AnimState:PlayAnimation("build_pst")
            if inst.sg.statemem.actionmeter then
                inst.sg.statemem.actionmeter = nil
            end
            inst.sg:RemoveStateTag("busy")
            inst:PerformBufferedAction()
        end,

        events =
        {
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },

        onexit = function(inst)
            inst.SoundEmitter:KillSound("make")
            if inst.bufferedaction == inst.sg.statemem.action then
                inst:ClearBufferedAction()
            end
        end,
    },

    ----------------------------------------------------------------------------------------------------

    State {
        name = "research",
        tags = { "busy", "nomorph" },

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("research")
        end,

        timeline =
        {
            TimeEvent(14 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("yotb_2021/common/heel_click")
            end),

            TimeEvent(23 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("yotb_2021/common/heel_click")
            end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    ----------------------------------------------------------------------------------------------------

    State {
        name = "hit",
        tags = { "hit", "busy" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst:ClearBufferedAction()

            inst.AnimState:PlayAnimation("hit")
            inst.SoundEmitter:PlaySound("dontstarve/wilson/hit")
            DoHurtSound(inst)

            local stun_frames = math.min(inst.AnimState:GetCurrentAnimationNumFrames(), 6)
            inst.sg:SetTimeout(stun_frames * FRAMES)
        end,

        ontimeout = function(inst)
            inst.sg:GoToState("idle", true)
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },

    },
    State {
        name = "attack",
        tags = { "attack", "busy" },

        onenter = function(inst)
            inst.Physics:Stop()
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("atk")
            inst.components.combat:StartAttack()
        end,

        timeline = {
            TimeEvent(8 * FRAMES, function(inst)
                inst.components.combat:DoAttack()
                inst.sg:RemoveStateTag("attack")
                inst.sg:RemoveStateTag("busy")
            end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },
    State {
        name = "death",
        tags = { "busy", "dead", "nomorph" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.components.locomotor:Clear()
            inst:ClearBufferedAction()

            inst.components.inventory:DropEverything(true)

            if inst.disappear then
                ErodeAway(inst)
                inst.sg.statemem.disappear = true
            else
                inst.SoundEmitter:PlaySound("dontstarve/wilson/death")
                inst.SoundEmitter:PlaySound((inst.talker_path_override or "dontstarve/characters/") .. (inst.soundsname or inst.prefab) .. "/death_voice")

                inst.AnimState:PlayAnimation("death")
                inst.AnimState:Hide("swap_arm_carry")
            end
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if not inst.sg.statemem.disappear and inst.AnimState:AnimDone() then
                    ErodeAway(inst)
                end
            end),
        },
    },
}


CommonStates.AddIdle(states, "research")

CommonStates.AddRunStates(states, {
    starttimeline = {
        TimeEvent(4 * FRAMES, function(inst)
            PlayFootstep(inst, nil, true)
            DoFoleySounds(inst)
        end),
    },

    runtimeline = {
        TimeEvent(7 * FRAMES, function(inst)
            DoRunSounds(inst)
            DoFoleySounds(inst)
        end),
        TimeEvent(15 * FRAMES, function(inst)
            DoRunSounds(inst)
            DoFoleySounds(inst)
        end),
    }
}, nil, nil, nil, {
    startonenter = function(inst)
        inst.sg.mem.footsteps = 0
    end,
    startonupdate = function(inst)
        inst.components.locomotor:RunForward()
    end,

    runonupdate = function(inst)
        inst.components.locomotor:RunForward()
    end,

})

return StateGraph("aab_minion", states, events, "idle", actionhandlers)

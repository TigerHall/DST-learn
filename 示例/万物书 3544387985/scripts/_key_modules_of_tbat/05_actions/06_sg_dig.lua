---------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    

]]--
---------------------------------------------------------------------------------------------------------------------------------------------------------
AddStategraphState("wilson",State{
    name = "tbat_sg_predig",
    tags = { "doing", "busy","working"  },

    onenter = function(inst)
        inst.components.locomotor:Stop()
        inst.AnimState:PlayAnimation("shovel_pre",false)
        -- inst.AnimState:PushAnimation("shovel_loop",false)
    end,

    timeline =
    {

    },

    events =
    {
        -- EventHandler("animover", function(inst)
        --     inst:PerformBufferedAction()
        -- end),
        -- EventHandler("animqueueover", function(inst)

        -- end),
        EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
        EventHandler("animover", function(inst)
            if inst.AnimState:AnimDone() then
                inst.sg:GoToState("tbat_sg_dig")
            end
        end),
    },
    onexit = function(inst)
    end,
})
AddStategraphState("wilson",State{
    name = "tbat_sg_dig",
    tags = { "doing", "busy","working"  },
    onenter = function(inst)
        inst.components.locomotor:Stop()
        inst.AnimState:PlayAnimation("shovel_loop",false)
        -- inst:PerformBufferedAction()
    end,
    timeline =
    {
        TimeEvent(15 * FRAMES, function(inst)
            inst.SoundEmitter:PlaySound("dontstarve/wilson/dig")
            inst:PerformBufferedAction()
        end),

        TimeEvent(35 * FRAMES, function(inst)
            inst:ClearBufferedAction()
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
    end,
})

AddStategraphState('wilson_client', State{
    name = "tbat_sg_predig",
    tags = { "doing", "busy","working"  },

    server_states = { "tbat_sg_dig" , "tbat_sg_predig" },
    onenter = function(inst)
        inst.components.locomotor:Stop()
        if not inst.sg:ServerStateMatches() then
            inst.AnimState:PlayAnimation("shovel_pre")
            inst.AnimState:PushAnimation("shovel_lag", false)
        end
        inst:PerformPreviewBufferedAction()
        inst.sg:SetTimeout(2)
    end,

    onupdate = function(inst)
        if inst.sg:ServerStateMatches() then
            if inst.entity:FlattenMovementPrediction() then
                inst.sg:GoToState("idle", "noanim")
            end
        elseif inst.bufferedaction == nil then
            inst.AnimState:PlayAnimation("shovel_pst")
            inst.sg:GoToState("idle", true)
        end
    end,

    ontimeout = function(inst)
        inst:ClearBufferedAction()
        inst.AnimState:PlayAnimation("shovel_pst")
        inst.sg:GoToState("idle", true)
    end,
})
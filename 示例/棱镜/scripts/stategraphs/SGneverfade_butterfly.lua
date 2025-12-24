require("stategraphs/commonstates")

-- local actionhandlers = {
--     ActionHandler(ACTIONS.GOHOME, "land")
-- }

local events = {
    EventHandler("locomote", function(inst)
        if not inst.sg:HasStateTag("busy") then
			local is_moving = inst.sg:HasStateTag("moving")
			local wants_to_move = inst.components.locomotor:WantsToMoveForward()
			if is_moving ~= wants_to_move then
				if wants_to_move then
					inst.sg.statemem.wantstomove = true
				else
					inst.sg:GoToState("idle")
				end
			end
        end
    end),
    EventHandler("death", function(inst)
        if not inst.sg:HasStateTag("death") then
            inst.sg:GoToState("death")
        end
    end)
}

local states = {
    State{
        name = "moving",
        tags = { "moving", "canrotate" },
        onenter = function(inst)
			inst.components.locomotor:WalkForward()
            inst.AnimState:PlayAnimation("flight_cycle", true)
        end
    },
    State{
        name = "death",
        tags = { "busy", "death" },
        onenter = function(inst)
            inst.Physics:Stop()
            RemovePhysicsColliders(inst)
            if inst.legiontag_dead == 2 then
                inst.AnimState:PlayAnimation("death")
            else
                inst.AnimState:PlayAnimation("land")
            end
            inst.AnimState:ClearBloomEffectHandle() --不清除光晕的话，ErodeAway就会出现一个短时间的滞留残影
            inst:DoTaskInTime(0, ErodeAway)
        end,
        -- timeline = {
        --     TimeEvent(10 * FRAMES, LandFlyingCreature)
        -- }
    },
    State{
        name = "idle",
        tags = { "idle" },
        onenter = function(inst)
            inst.Physics:Stop()
            if not inst.AnimState:IsCurrentAnimation("idle_flight_loop") then
                inst.AnimState:PlayAnimation("idle_flight_loop", true)
            end
            inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength())
        end,
        ontimeout = function(inst)
            if inst.sg.statemem.wantstomove then
                inst.sg:GoToState("moving")
            elseif math.random() < 0.8 then
                inst.sg:GoToState("idle")
            else
                inst.sg:GoToState("land")
            end
        end
    },
    State{
        name = "land",
        tags = { "busy", "landing" },
        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("land")
            -- LandFlyingCreature(inst)
        end,
        events = {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("land_idle")
            end)
        },
        -- onexit = RaiseFlyingCreature
    },
    State{
        name = "land_idle",
        tags = { "busy", "landed" },
        onenter = function(inst)
            inst.AnimState:PlayAnimation("idle", true)
            if inst.components.locomotor:WantsToMoveForward() then --如果需要移动了，那就做完当前动画就溜
                inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength())
            else
                inst.sg:SetTimeout(GetRandomWithVariance(3, 1))
            end
            -- LandFlyingCreature(inst)
        end,
        ontimeout = function(inst)
            inst.sg:GoToState("takeoff")
        end
        -- onexit = RaiseFlyingCreature
    },
    State{
        name = "takeoff",
        tags = { "busy" },
        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("take_off")
        end,
        events = {
            EventHandler("animover", function(inst)
                if inst.components.locomotor:WantsToMoveForward() then
                    inst.sg:GoToState("moving")
                else
                    inst.sg:GoToState("idle")
                end
            end)
        }
    }
}
-- CommonStates.AddFrozenStates(states, LandFlyingCreature, RaiseFlyingCreature)

return StateGraph("neverfade_butterfly", states, events, "takeoff")

require("stategraphs/commonstates")

local events =
{
	CommonHandlers.OnElectrocute(),

    EventHandler("death", function(inst)
        inst.sg:GoToState("death")
    end),

	EventHandler("attacked", function(inst, data)
        if not inst.components.health:IsDead() then
			if CommonHandlers.TryElectrocuteOnAttacked(inst, data) then
				return
			else
				inst.sg:GoToState("hit")
			end
        end
    end),

	EventHandler("worked", function(inst)
		if not inst.components.health:IsDead() then
			inst.sg:GoToState("death")
		end
	end),
}

local states =
{
    State{
        name = "appear",
        tags = { "busy" },

        onenter = function(inst)
            inst.AnimState:PlayAnimation("appear")
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

    State{
        name = "idle",
        tags = { "idle" },

        onenter = function(inst, push_anim)
            inst.Physics:Stop()
            if push_anim then
                inst.AnimState:PushAnimation("idle_loop", true)
            else
                inst.AnimState:PlayAnimation("idle_loop", true)
            end
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState(math.random() < .1 and "taunt" or "idle", true)
                end
            end),
        },
    },

    State{
        name = "taunt",
        tags = { "idle" },

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("taunt", true)
            inst.sg:SetTimeout(math.random() * 4 + 2)
        end,

        ontimeout = function(inst)
            inst.sg:GoToState("idle", true)
        end,
    },

    State{
        name = "hit",
		tags = { "busy", "hit" },

        onenter = function(inst)
            inst.AnimState:PlayAnimation("hit")
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

    State{
        name = "death",
        tags = { "busy" },

        onenter = function(inst)
            inst.AnimState:PlayAnimation("death")
            RemovePhysicsColliders(inst)

            inst.SoundEmitter:PlaySound("dontstarve/creatures/eyeplant/lure_die")
        end,

        timeline =
		{
			FrameEvent(15, function(inst)
                ErodeAway(inst)
            end),
		},
    },
}

-- CommonStates.AddElectrocuteStates(states,
-- nil, --timeline
-- {	--anims
-- 	loop = function(inst)
-- 		if not inst.sg.lasttags["hiding"] then
-- 			return "shock_out_loop"
-- 		end
-- 		inst.sg:AddStateTag("hiding")
-- 		if inst.sg.lasttags["vine"] then
-- 			inst.sg:AddStateTag("vine")
-- 			return "shock_loop"
-- 		end
-- 		return "shock_hidden_loop"
-- 	end,
-- 	pst = function(inst)
-- 		if not inst.sg.lasttags["hiding"] then
-- 			return "shock_out_pst"
-- 		end
-- 		inst.sg:AddStateTag("hiding")
-- 		if inst.sg.lasttags["vine"] then
-- 			inst.sg:AddStateTag("vine")
-- 			return "shock_pst"
-- 		end
-- 		return "shock_hidden_pst"
-- 	end,
-- },
-- {	--fns
-- 	onanimover = function(inst)
-- 		if inst.AnimState:AnimDone() then
-- 			if not inst.sg:HasStateTag("hiding") then
-- 				inst:PushEvent("hidebait")
-- 			else
-- 				inst.sg:GoToState(inst.sg:HasStateTag("vine") and "idlein" or "hibernate")
-- 			end
-- 		end
-- 	end,
-- })

return StateGraph("terror_bomb_flower", states, events, "appear")

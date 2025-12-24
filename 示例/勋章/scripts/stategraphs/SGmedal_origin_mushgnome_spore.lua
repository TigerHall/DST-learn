require("stategraphs/commonstates")

local events=
{
    EventHandler("locomote", function(inst)
        if not inst.sg:HasStateTag("busy") then
			local is_moving = inst.sg:HasStateTag("moving")
			local wants_to_move = inst.components.locomotor:WantsToMoveForward()--当前是否有目的地
			--有目的地并且当前不在移动状态，那么就动起来！
            if is_moving ~= wants_to_move then
				if wants_to_move then
					inst.sg.statemem.wantstomove = true
                    inst.sg:GoToState("moving")
				else
					inst.sg:GoToState("idle")
				end
			end
        end
    end),
    EventHandler("pop", function(inst) -- for instantaneous pops
        inst.sg:GoToState("pop")
    end),
    EventHandler("preparedpop", function(inst) -- for a delayed pop
        inst.sg:GoToState("pre_pop")
    end),
}

--当前有攻击目标的话就切换为追击模式
local function return_to_idle(inst)
    if inst.sg.statemem.wantstomove then
        inst.sg:GoToState("moving")
    else
        inst.sg:GoToState("idle")
    end
end

local states=
{
    State{--移动
        name = "moving",
        tags = {"moving", "canrotate"},

        onenter = function(inst)
            inst.components.locomotor:WalkForward()
            inst.AnimState:PlayAnimation("idle_flight_loop", true)
        end,
    },
    
    State{--爆炸前摇(给玩家一点反应时间)
        name = "pre_pop",
        tags = {"busy"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("rumble", true)

            -- inst.sg:SetTimeout(26 * FRAMES)
            inst.sg:SetTimeout(10 * FRAMES)
        end,

        ontimeout = function(inst)
            inst.sg:GoToState("pop")
        end,
    },

    State{--爆炸
        name = "pop",
        tags = {"busy"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("explode")
        end,

        timeline =
        {
            TimeEvent(4*FRAMES, function(inst)
                inst.Light:Enable(false)
                inst.DynamicShadow:Enable(false)

                inst:PushEvent("popped")
            end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                inst:Remove()
            end),
        },
    },

    State{--待机
        name = "idle",
        tags = {"idle", "canrotate"},

        onenter = function(inst)
            if not inst.AnimState:IsCurrentAnimation("idle_flight_loop") then
                inst.AnimState:PlayAnimation("idle_flight_loop", true)
            end
            inst.sg:SetTimeout( inst.AnimState:GetCurrentAnimationLength() )
        end,

        ontimeout = return_to_idle,
    },

    State{--掉落(出场动画)
        name = "takeoff",
        tags = {"busy"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("cough_out")
            inst.sg:SetTimeout(15 * FRAMES)--提前结束掉落状态,直接进入追击状态
        end,

        timeline =
        {
            TimeEvent(14*FRAMES, function(inst)
                inst.Light:Enable(true)
                inst.DynamicShadow:Enable(true)
                inst.SoundEmitter:PlaySound("dontstarve/cave/mushtree_tall_spore_land")
            end),
        },

        ontimeout = return_to_idle,

        events =
        {
            EventHandler("animover", return_to_idle),
        },
    },
}

return StateGraph("SGmedal_origin_mushgnome_spore", states, events, "takeoff")

require("stategraphs/commonstates")

local actionhandlers =
{
    ActionHandler(ACTIONS.GOHOME, "action"),
	ActionHandler(ACTIONS.MEDAL_ORIGIN_POLLINATION, "plant_dance"),
}

local events=
{
    EventHandler("hatch", function(inst) 
        if inst:HasTag("cocoon") then
            inst.sg:GoToState("cocoon_pst")
        end
    end),
	EventHandler("cocoon", function(inst) 
        if inst.ChangeToCocoon and not inst.sg:HasStateTag("busy") then
            inst:ChangeToCocoon()
        end
    end),
    EventHandler("attacked", function(inst) 
        if inst.components.health:GetPercent() > 0 then
            if inst:HasTag("cocoon") then
                inst.sg:GoToState("cocoon_hit") 
            else  
                inst.sg:GoToState("hit") 
            end
        end 
    end),
	EventHandler("death", function(inst) 
        if not inst.sg:HasStateTag("dead") then
			if inst:HasTag("cocoon") then
				inst.sg:GoToState("cocoon_death") 
			else
				inst.sg:GoToState("death") 
			end
		end
    end),
    -- CommonHandlers.OnLocomote(false,true),
	EventHandler("locomote", function(inst)
        if not inst.sg:HasStateTag("busy") and not inst:HasTag("cocoon") then
			local wants_to_move = inst.components.locomotor:WantsToMoveForward()
			if not inst.sg:HasStateTag("attack") then
				if wants_to_move then
					inst.sg:GoToState("moving")
				else                    
					inst.sg:GoToState("idle")
				end
			end
        end
    end),
}

local states=
{
	State{--默认动画
		name = "idle",
		tags = {"idle"},

		onenter = function(inst)
			inst.Physics:Stop()
			if inst:HasTag("cocoon") then
                inst.AnimState:PlayAnimation("cocoon_idle_loop", true) 
            else
                inst.AnimState:PlayAnimation("walk_loop", true)
            end
		end,
    },
	State{--动作切换
        name = "action",
        onenter = function(inst, playanim)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("idle", true)
            inst:PerformBufferedAction()
        end,
        events=
        {
            EventHandler("animover", function (inst)
                inst.sg:GoToState("idle")
            end),
        }
    },
	State{--移动
        name = "moving",
        tags = {"moving", "canrotate"},

        onenter = function(inst)        
            inst.components.locomotor:WalkForward()
            inst.AnimState:PlayAnimation("walk_loop", true)
        end,
		
		ontimeout = function(inst)
            inst.sg:GoToState("moving")
        end,
    },
	State{--化茧
        name = "cocoon_pre",
        tags = {"cocoon","busy"},

        onenter = function(inst)
            inst.Physics:Stop()            
            inst.AnimState:PlayAnimation("cocoon_idle_pre")            
        end,
        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end ),
        },        
    },
    State{--孵化
        name = "cocoon_pst",
        tags = {"cocoon","busy"},

        onenter = function(inst)           
            inst.Physics:Stop()
			--给本源之树回血
			if TheWorld and TheWorld.medal_origin_tree ~= nil and TheWorld.medal_origin_tree.DoRecovery then
				TheWorld.medal_origin_tree:DoRecovery(TUNING_MEDAL.MEDAL_ORIGIN_COCOON_RECOVERY)--回血
				local fx = SpawnPrefab("farm_plant_happy")
        		fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
			end
            inst.AnimState:PlayAnimation("cocoon_idle_pst")
            inst.persists = false
        end,
        
        events=
        {
            EventHandler("animover", function(inst) inst:Remove() end),
        },

        onexit = function(inst)
            inst:Remove()
        end,
    },

    State{--过期()
        name = "cocoon_expire",
        tags = {"cocoon","busy"},

        onenter = function(inst)           
            inst.AnimState:PlayAnimation("cocoon_idle_pst")
            inst.persists = false
        end,
        
        events=
        {
            EventHandler("animover", function(inst) inst:Remove() end),
        },

        onexit = function(inst)
            inst:Remove()
        end,
    },

    State{
        name = "cocoon_hit",
        tags = {"cocoon","busy"},

        onenter = function(inst)
            inst.SoundEmitter:PlaySound(inst.sounds.hit)
            inst.AnimState:PlayAnimation("cocoon_hit")
            inst.Physics:Stop()
        end,

        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end ),
        },
    },

    State{
        name = "cocoon_death",
        tags = {"cocoon", "busy", "death"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("cocoon_death")
			if inst.hatchtask ~= nil then
				inst.hatchtask:Cancel()
				inst.hatchtask = nil
			end
            RemovePhysicsColliders(inst)
            if inst.components.lootdropper then
                inst.components.lootdropper:DropLoot(Vector3(inst.Transform:GetWorldPosition()))
            end
        end,
    },
}


CommonStates.AddHitState(states,
{
	TimeEvent(0, function(inst)	inst.SoundEmitter:PlaySound(inst.sounds.hit) end)
})
CommonStates.AddDeathState(states,
{
	TimeEvent(0, function(inst) inst.SoundEmitter:PlaySound(inst.sounds.death) end),
	TimeEvent(10*FRAMES, LandFlyingCreature),
})


return StateGraph("SGmedal_origin_glowfly", states, events, "idle", actionhandlers)
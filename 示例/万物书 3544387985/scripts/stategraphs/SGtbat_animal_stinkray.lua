require("stategraphs/commonstates")

local actionhandlers =
{
	-- ActionHandler(ACTIONS.GOHOME, "action"),
	ActionHandler(ACTIONS.GOHOME, "active_action"),
	ActionHandler(ACTIONS.EAT, "active_action"),
	ActionHandler(ACTIONS.TBAT_PET_STINKRAY_WANDER_ACTIVE, "active_action"),		-- 自制 游走
	ActionHandler(ACTIONS.TBAT_PET_STINKRAY_WATERPLANT_SHAVE, "active_action"),		-- 藤壶采集
	ActionHandler(ACTIONS.TBAT_PET_STINKRAY_OCEAN_TRAWLER_PICK, "active_action"),	-- 渔网采集
	ActionHandler(ACTIONS.TBAT_PET_STINKRAY_DO_SWIM_FOR_BURNING, "gotoswim"),		-- 自己被点燃的时候
}

local events=
{
	
	CommonHandlers.OnLocomote(true, true),
	CommonHandlers.OnFreeze(),

	CommonHandlers.OnSleep(),
	EventHandler("attacked", function(inst) if inst.components.health:GetPercent() > 0 then inst.sg:GoToState("hit") end end),
    EventHandler("doattack", function(inst, data) if not inst.components.health:IsDead() and (inst.sg:HasStateTag("hit") or not inst.sg:HasStateTag("busy")) then inst.sg:GoToState("attack", data.target) end end),
    EventHandler("death", function(inst) inst.sg:GoToState("death") end),

}

local function GoToLocoState(inst, state)
	if inst:IsLocoState(state) then
		return true
	end
	inst.sg:GoToState("goto"..string.lower(state), {endstate = inst.sg.currentstate.name})
end
local function IsInOceanTile(inst)
	local x,y,z = inst.Transform:GetWorldPosition()
	local should_walk  =  TheWorld.Map:IsOceanTileAtPoint(x,y,z) and TheWorld.Map:IsOceanAtPoint(x,y,z,false)
	--- run 为飞起来状态，walk 为水里状态
	local should_fly = not should_walk

	-- local target = inst.components.combat.target
	-- if target and target:IsValid() then
	-- 	should_fly = true
	-- end
	
	if inst.ShouldFly and inst:ShouldFly() then
		should_fly = true
	end
	if should_fly then
		inst.components.locomotor:SetShouldRun(true)
	else
		inst.components.locomotor:SetShouldRun(false)
	end
	return not should_fly
end

local states =
{
	State{
		name = "active_action",
		tags = {"busy"},
		onenter = function(inst, data)
			local in_ocean_tile = inst.IsInOceanTile and inst:IsInOceanTile() or false
			local is_flying = inst.IsFlying and inst:IsFlying() or false
			----------------------------------------------------
			--- 正在飞行 + 位置在水上 =  跳水里
				if is_flying and in_ocean_tile then
					inst.sg:GoToState("gotoswim")
					return
				end
			----------------------------------------------------
			--- 正在潜水 + 位置在水上 =  跳出水里
				if not is_flying and in_ocean_tile then
					inst.sg:GoToState("gotofly")
					return
				end 
			----------------------------------------------------
			--- 正在飞行 + 位置在陆地上 = 直接操作
				if is_flying and not in_ocean_tile then
					inst.Physics:Stop()
					inst.AnimState:PlayAnimation("taunt",false)
				end
			----------------------------------------------------
		end,
		onexit = function(inst)

		end,
		events=
		{
			EventHandler("animover", function(inst)
				inst:PerformBufferedAction()
				inst.sg:GoToState("idle")
			end),
		},
	},

	State{
		name = "gotoswim",
		tags = {"busy", "swimming"},
		onenter = function(inst, data)
			inst.AnimState:PlayAnimation("submerge")
			-- inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/dogfish/water_submerge_med")
			inst.Physics:Stop()
            inst.sg.statemem.endstate =	data and data.endstate

            --[[
			local splash = SpawnPrefab("splash_water")
			local pos = inst:GetPosition()
			splash.Transform:SetPosition(pos.x, pos.y, pos.z)
			--]]
		end,

		onexit = function(inst)
			inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
			inst.Transform:SetNoFaced()
			inst.DynamicShadow:Enable(false)
			inst:SetLocoState("swim")
		end,

		events=
		{
			EventHandler("animover", function(inst)
				inst.Transform:SetScale(inst.scale_water, inst.scale_water, inst.scale_water)
				inst.sg:GoToState(inst.sg.statemem.endstate or "swim_idle")
				inst:PerformBufferedAction()
			end),
		},
	},

	State{
		name = "gotofly",
		tags = {"busy"},
		onenter = function(inst, data)
			inst.AnimState:SetOrientation(ANIM_ORIENTATION.Default)
			inst.Transform:SetFourFaced()
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("emerge")
			-- inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/dogfish/water_emerge_med")
	        inst.sg.statemem.endstate = data and data.endstate
	        inst.DynamicShadow:Enable(true)
	        inst.Transform:SetScale(inst.scale_flying, inst.scale_flying, inst.scale_flying)

			
				-- local splash = SpawnPrefab("splash_water")
				-- local pos = inst:GetPosition()
				-- splash.Transform:SetPosition(pos.x, pos.y, pos.z)
			
		end,

		onexit = function(inst)
			inst:SetLocoState("fly")
		end,

		events=
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState(inst.sg.statemem.endstate or "idle")
				inst:PerformBufferedAction()
			end),
		},
	},

	State{
		name = "idle",
		tags = {"idle", "canrotate"},
		onenter = function(inst, playanim)
			if IsInOceanTile(inst) then
				inst.sg:GoToState("swim_idle")
				return
			end
			if GoToLocoState(inst, "fly") then
				inst.Physics:Stop()
				inst.AnimState:PlayAnimation("fly_loop", true)
				-- inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/Stinkray/idle")
			end
		end,

		timeline =
		{
			TimeEvent(1*FRAMES, function(inst)
				-- inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/Stinkray/wingflap")  
			end ),
			TimeEvent(10*FRAMES, function(inst)
				 -- inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/Stinkray/wingflap")  
			end ),
		},

		events=
		{
			EventHandler("animover", function(inst)
				if IsInOceanTile(inst) then
					inst.sg:GoToState("swim_idle")
					return
				end
				inst.sg:GoToState("idle")
			end),
		},
	},

	State{
		name = "action",
		onenter = function(inst)
			if GoToLocoState(inst, "fly") then
				inst.Physics:Stop()
				inst.AnimState:PlayAnimation("fly_loop", true)
				inst:PerformBufferedAction()
			end
		end,

		timeline =
		{
			TimeEvent(1*FRAMES, function(inst)
				-- inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/Stinkray/wingflap")
			end ),
			TimeEvent(10*FRAMES, function(inst)
				-- inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/Stinkray/wingflap")
			end ),
		},

		events=
		{
			EventHandler("animover", function (inst)
				inst.sg:GoToState("idle")
			end),
		}
	},

	State{
		name = "taunt",
		tags = {"busy"},

		onenter = function(inst)
			if GoToLocoState(inst, "fly") then
				inst.Physics:Stop()
				inst.AnimState:PlayAnimation("taunt")
			end
		end,

		timeline =
		{
			TimeEvent(1*FRAMES, function(inst)
				-- inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/Stinkray/taunt")
			end ),
			-- TimeEvent(1*FRAMES, function(inst)
			-- -- inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/Stinkray/wingflap")
			-- end ),
		},

		events=
		{
			EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
		},
	},

	 State{ --This state isn't really necessary but I'm including it to make the default "OnLocomote" work
        name = "run_start",
        tags = {"moving", "running", "canrotate"},

        onenter = function(inst)
			if IsInOceanTile(inst) then
				inst.sg:GoToState("walk")
				return
			end
			if GoToLocoState(inst, "fly") then
				inst.components.locomotor:RunForward()
				inst.AnimState:PlayAnimation("fly_loop")
			end
        end,

        timeline =
		{
			TimeEvent(1*FRAMES, function(inst)
				-- inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/Stinkray/wingflap")
			end ),
			TimeEvent(10*FRAMES, function(inst)
				-- inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/Stinkray/wingflap")
			end ),
		},

        events=
        {
            EventHandler("animover", function(inst) 
				if IsInOceanTile(inst) then
					inst.sg:GoToState("walk")
					return
				end
				inst.sg:GoToState("run")
			end ),
        },
    },

	State{
		name = "run",
		tags = {"moving", "canrotate", "running"},

		onenter = function(inst)
			if IsInOceanTile(inst) then
				inst.sg:GoToState("walk")
				return
			end
			if GoToLocoState(inst, "fly") then
				inst.components.locomotor:RunForward()
				inst.AnimState:PlayAnimation("fly_loop")
			end
		end,

		timeline =
		{
			TimeEvent(1*FRAMES, function(inst)
				-- inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/Stinkray/wingflap")
			end ),
			TimeEvent(10*FRAMES, function(inst)
				-- inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/Stinkray/wingflap")
			end ),
		},

		events=
		{
			EventHandler("animover", function(inst)
				if IsInOceanTile(inst) then
					inst.sg:GoToState("walk")
					return
				end
				inst.sg:GoToState("run")
			end ),
		},
	},

	State{
        name = "run_stop",
        tags = {"idle"},

        onenter = function(inst)
			if IsInOceanTile(inst) then
				inst.sg:GoToState("walk_stop")
				return
			end
			if GoToLocoState(inst, "fly") then
				inst.components.locomotor:StopMoving()
			end
        end,

        timeline =
		{
			TimeEvent(1*FRAMES, function(inst)
				-- inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/Stinkray/wingflap")
			end ),
			TimeEvent(10*FRAMES, function(inst)
				-- inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/Stinkray/wingflap")
			end ),
		},

        events=
        {
            EventHandler("animover", function(inst)
				if IsInOceanTile(inst) then
					inst.sg:GoToState("swim_idle")
					return
				end
				inst.sg:GoToState("idle")
			end ),
        },
    },

	State{
		name = "swim_idle",
		tags = {"idle", "canrotate", "swimming"},
		onenter = function(inst)
			if not IsInOceanTile(inst) then
				inst.sg:GoToState("idle")
				return
			end
			if GoToLocoState(inst, "swim") then
				inst.Physics:Stop()
				inst.AnimState:PlayAnimation("shadow", true)
			end
		end,

		events=
		{
			EventHandler("animover", function(inst)
				if not IsInOceanTile(inst) then
					inst.sg:GoToState("idle")
					return
				end
				inst.sg:GoToState("swim_idle")
			end),
		},
	},

	State{
		name = "walk_start",
		tags = {"moving", "canrotate", "swimming"},

		onenter = function(inst)
			if not IsInOceanTile(inst) then
				inst.sg:GoToState("run")
				return
			end
			if GoToLocoState(inst, "swim") then
				inst.components.locomotor:WalkForward()
				inst.AnimState:PlayAnimation("shadow",true)
			end
		end,

		events =
		{
			EventHandler("animover", function(inst)
				if not IsInOceanTile(inst) then
					inst.sg:GoToState("run")
					return
				end
				inst.sg:GoToState("walk")
			end ),
		},
	},

	State{
		name = "walk",
		tags = {"moving", "canrotate", "swimming"},

		onenter = function(inst)
			if not IsInOceanTile(inst) then
				inst.sg:GoToState("run")
				return
			end
			if GoToLocoState(inst, "swim") then
				inst.components.locomotor:WalkForward()
				inst.AnimState:PlayAnimation("shadow")
			end
		end,

		events=
		{
			EventHandler("animover", function(inst)
				if not IsInOceanTile(inst) then
					inst.sg:GoToState("run")
					return
				end
				inst.sg:GoToState("walk")
			end ),
		},
	},

	State{
		name = "walk_stop",
		tags = {"canrotate", "swimming"},

		onenter = function(inst)
			if not IsInOceanTile(inst) then
				inst.sg:GoToState("run_stop")
				return
			end
			if GoToLocoState(inst, "swim") then
				inst.components.locomotor:StopMoving()
				inst.AnimState:PlayAnimation("shadow")
			end
		end,
		events=
		{
			EventHandler("animover", function(inst)
				if not IsInOceanTile(inst) then
					inst.sg:GoToState("idle")
					return
				end
				inst.sg:GoToState("swim_idle")
			end ),
		},
	},

    State{
        name = "sleep",
        tags = {"busy", "sleeping"},

        onenter = function(inst)
            if GoToLocoState(inst, "fly") then
            	inst.components.locomotor:StopMoving()
            	inst.AnimState:PlayAnimation("sleep_pre")
        	end
        end,

        timeine =
        {
        	TimeEvent(1*FRAMES, function(inst)
				-- inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/Stinkray/sleep")
			end),
        	-- TimeEvent(9*FRAMES, function(inst)
			-- -- inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/Stinkray/sleep")
			-- end),
        },

        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("sleeping") end ),
            EventHandler("onwakeup", function(inst) inst.sg:GoToState("wake") end),
        },
    },

    State{

        name = "sleeping",
        tags = {"busy", "sleeping"},

        onenter = function(inst)
            if GoToLocoState(inst, "fly") then
            	inst.AnimState:PlayAnimation("sleep_loop")
            end
        end,

        timeine =
        {
			TimeEvent(1*FRAMES, function(inst)
				-- inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/Stinkray/sleep")
			end),
        },

        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("sleeping") end ),
            EventHandler("onwakeup", function(inst) inst.sg:GoToState("wake") end),
        },
    },

    State{
        name = "wake",
        tags = {"busy", "waking"},

        onenter = function(inst)
            if GoToLocoState(inst, "fly") then
	            inst.components.locomotor:StopMoving()
	            inst.AnimState:PlayAnimation("sleep_pst")
	            if inst.components.sleeper and inst.components.sleeper:IsAsleep() then
	                inst.components.sleeper:WakeUp()
	            end
	        end
        end,

        timeine =
        {
        	TimeEvent(1*FRAMES, function(inst)
				-- inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/Stinkray/wingflap")
			end ),
			TimeEvent(9*FRAMES, function(inst)
				-- inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/Stinkray/wingflap")
			end ),
        },

        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end ),
        },
    },

    State{
        name = "frozen",
        tags = {"busy", "frozen"},

        onenter = function(inst)
	        if GoToLocoState(inst, "fly") then
	            if inst.components.locomotor then
	                inst.components.locomotor:StopMoving()
	            end
	            inst.AnimState:PlayAnimation("frozen_loop", true)
	            -- inst.SoundEmitter:PlaySound("dontstarve/common/freezecreature")
	            inst.AnimState:OverrideSymbol("swap_frozen", "frozen", "frozen")
	        end
        end,

        onexit = function(inst)
            inst.AnimState:ClearOverrideSymbol("swap_frozen")
        end,

        events=
        {
            EventHandler("onthaw", function(inst) inst.sg:GoToState("thaw") end ),
        },
    },

    State{
        name = "thaw",
        tags = {"busy", "thawing"},

        onenter = function(inst)
        	if GoToLocoState(inst, "fly") then
	            if inst.components.locomotor then
	                inst.components.locomotor:StopMoving()
	            end
	            inst.AnimState:PlayAnimation("frozen_loop_pst", true)
	            -- inst.SoundEmitter:PlaySound("dontstarve/common/freezethaw", "thawing")
	            inst.AnimState:OverrideSymbol("swap_frozen", "frozen", "frozen")
	        end
        end,

        onexit = function(inst)
            inst.SoundEmitter:KillSound("thawing")
            inst.AnimState:ClearOverrideSymbol("swap_frozen")
        end,

        events =
        {
            EventHandler("unfreeze", function(inst)
                if inst.sg.sg.states.hit then
                    inst.sg:GoToState("hit")
                else
                    inst.sg:GoToState("idle")
                end
            end ),
        },
    },

    State{
        name = "hit",
        tags = {"hit", "busy"},

        onenter = function(inst)
        	if GoToLocoState(inst, "fly") then
	            inst.components.locomotor:StopMoving()
	            inst.AnimState:PlayAnimation("hit")
	        end
        end,

        timeline =
        {
			TimeEvent(1*FRAMES, function(inst)
				-- inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/Stinkray/hurt")
			end),
        },

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "attack",
        tags = {"attack", "busy"},

        onenter = function(inst, target)
        	if GoToLocoState(inst, "fly") then
	            inst.components.locomotor:StopMoving()
	            inst.components.combat:StartAttack()
	            inst.AnimState:PlayAnimation("atk")
	        end
        end,

        timeline =
        {
        	TimeEvent(1*FRAMES, function(inst)
				-- inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/Stinkray/wingflap")
			end ),
        	TimeEvent(7*FRAMES, function(inst)
				-- inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/Stinkray/wingflap")
			end ),
			TimeEvent(8* FRAMES, function(inst)
				inst.components.combat:DoAttack()
				-- inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/Stinkray/attack")
			end),
        	TimeEvent(19*FRAMES, function(inst)
				-- inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/Stinkray/wingflap")
			end ),
        },

        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "death",
        tags = {"busy"},

        onenter = function(inst)
			if TheWorld.Map:IsPassableAtPoint(inst.Transform:GetWorldPosition()) then
			inst.AnimState:OverrideSymbol("ripple3_cutout2", "stinkray", "")
			inst.AnimState:OverrideSymbol("ripple3_back", "stinkray", "")	
			inst.AnimState:OverrideSymbol("splash", "stinkray", "")
			inst.AnimState:OverrideSymbol("droplet", "stinkray", "")	
			end
        	if GoToLocoState(inst, "fly") then
	            inst.AnimState:PlayAnimation("death")
                inst.components.locomotor:StopMoving()
				inst.Physics:ClearCollisionMask()
	            inst.components.lootdropper:DropLoot(Vector3(inst.Transform:GetWorldPosition()))
	        end
			inst.Physics:Stop()
			inst.Physics:SetActive(false)		
			
        end,

        timeline =
        {
			TimeEvent(1*FRAMES, function(inst)
				-- inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/Stinkray/death")
			end),
			---- --  I need a splash sound here...
			-- TimeEvent(17*FRAMES, function(inst)
			-- -- inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/Stinkray/wingflap")
			-- end ),
        },
    },

}

return StateGraph("stungray", states, events, "swim_idle", actionhandlers)

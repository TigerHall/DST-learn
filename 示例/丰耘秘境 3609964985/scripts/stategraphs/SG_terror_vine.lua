require("stategraphs/commonstates")

local MUST_TAGS =  {"_combat"}
local CANT_TAGS = { "FX", "NOCLICK", "DECOR", "INLIMBO", "invisible", "wall", "notarget", "noattack", "player", "companion"}

local TOSSITEM_MUST_TAGS = { "_inventoryitem" }
local TOSSITEM_CANT_TAGS = { "locomotor", "INLIMBO" }
local TOSS_RADIUS = .2
local TOSS_RADIUS_PADDING = .5
local function DoToss(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	local totoss = TheSim:FindEntities(x, 0, z, TOSS_RADIUS + TOSS_RADIUS_PADDING, TOSSITEM_MUST_TAGS, TOSSITEM_CANT_TAGS)
	for i, v in ipairs(totoss) do
		if v.components.mine ~= nil then
			v.components.mine:Deactivate()
		end
		if not v.components.inventoryitem.nobounce then
			Launch2(v, inst, .5, 1, .1, TOSS_RADIUS + v:GetPhysicsRadius(0))
		end
	end
end

local function FindTargets(inst)
    local targets = {}
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, TUNING.LUNARTHRALL_PLANT_VINE_ATTACK_RANGE, MUST_TAGS, CANT_TAGS )
    for i, target in ipairs(ents)do
        local leader = target.components.follower and target.components.follower:GetLeader()
        if (leader == nil or not (leader:HasTag("player") or leader:HasTag("companion"))) and
            (inst._owner == nil or (inst._owner.components.combat and inst._owner.components.combat:CanTarget(target)))
        then
            table.insert(targets, target)
        end
    end

    return targets
end

local events =
{
    CommonHandlers.OnFreeze(),
	CommonHandlers.OnElectrocute(),
	EventHandler("attacked", function(inst, data)
        if not inst.components.health:IsDead() then
			if CommonHandlers.TryElectrocuteOnAttacked(inst, data) then
				return
			elseif inst.sg:HasStateTag("caninterrupt") or not inst.sg:HasStateTag("busy") then
                inst.sg:GoToState("hit")
            end
        end
    end),
    EventHandler("doattack", function(inst, data)
        if not inst.sg:HasStateTag("busy") and not inst.components.health:IsDead() then
            inst.sg:GoToState("attack")
        end
    end),
    EventHandler("newcombattarget", function(inst, data)
        if inst.sg:HasStateTag("idle") and data.target then
            inst.sg:GoToState("attack")
        end
    end),
    EventHandler("death", function(inst) inst.sg:GoToState("death") end),
}

local states=
{
    State{
        name = "idle",
        tags = {"idle", "canrotate","emerged"},

        onenter = function(inst)
            local targets = FindTargets(inst)
            if (inst._last_attack_time == nil or GetTime() - inst._last_attack_time > 3) and #targets > 0 then
                inst.sg:GoToState("attack", { targets = targets })
            else
                inst.AnimState:PlayAnimation("idle")
            end
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "appear",
		tags = { "busy", "canrotate", "emerged", "noelectrocute" },

        onenter = function(inst)
            inst.SoundEmitter:PlaySound("rifts/lunarthrall/vine_breach")
            inst.AnimState:PlayAnimation("appear")
			DoToss(inst) -- 创飞附近物品
        end,

        timeline=
        {
			FrameEvent(7, function(inst)
				inst.sg:AddStateTag("caninterrupt")
				inst.sg:RemoveStateTag("noelectrocute")
			end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "retract", -- 收回
		tags = { "busy", "canrotate", "retracting", "emerged", "noelectrocute" },

        onenter = function(inst, pos)
            inst.AnimState:PlayAnimation("breach_pst")
        end,

        timeline=
        {
			FrameEvent(11, function(inst)
                inst.sg:AddStateTag("noattack")
                if inst.components.burnable and inst.components.burnable:IsBurning() then
                    inst.components.burnable:Extinguish()
                end
            end ),
        },

        events =
        {
            EventHandler("animover", function(inst)
                inst:Remove()
            end),
        },
    },

    State{
        name = "attack",
        tags = {"busy", "canrotate","emerged"},

        onenter = function(inst, data)
            inst.sg.statemem.targets = data and data.targets
            inst.AnimState:PlayAnimation("atk")
        end,

        timeline=
        {
            TimeEvent(10*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("rifts/lunarthrall/vine_attack")
            end),
            TimeEvent(17*FRAMES, function(inst)
                local targets = inst.sg.statemem.targets or FindTargets(inst)
                if #targets > 0 then
                    for i, target in ipairs(targets) do
                        inst.components.combat:DoAttack(target)
                    end
                end

                inst._last_attack_time = GetTime()
            end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "hit",
        tags = {"busy","caninterrupt"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("hit")
        end,

        timeline=
        {
            --TimeEvent(25*FRAMES, function(inst) end ),
        },

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "death",
		tags = { "dead", "busy" },

        onenter = function(inst)
            inst.sg:AddStateTag("emerged")

            inst.AnimState:PlayAnimation("death")

            inst.SoundEmitter:PlaySound("rifts/lunarthrall/vine_death")
        end,
    },
}

CommonStates.AddElectrocuteStates(states)
CommonStates.AddFrozenStates(states)

return StateGraph("terror_vine", states, events, "appear")
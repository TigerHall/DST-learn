require "behaviours/runaway"
require "behaviours/wander"
require "behaviours/doaction"
require "behaviours/findflower"
local BrainCommon = require("brains/braincommon")

local RUN_AWAY_DIST = 5
local STOP_RUN_AWAY_DIST = 10
local POLLINATE_FLOWER_DIST = 10
local SEE_FLOWER_DIST = 30
local MAX_WANDER_DIST = 15

local FLOWER_TAGS = {"flower"}
local FLOWER_TAGS_SPECIAL = {"tbat_plant_ephemeral_flower"}

local function find_avalable_flower(inst)
    return GetClosestInstWithTag(FLOWER_TAGS_SPECIAL, inst, SEE_FLOWER_DIST) or GetClosestInstWithTag(FLOWER_TAGS, inst, SEE_FLOWER_DIST)
end

local function NearestFlowerPos(inst)
    local flower = find_avalable_flower(inst)
    if flower and
       flower:IsValid() then
        return Vector3(flower.Transform:GetWorldPosition() )
    end
end

local function GoHomeAction(inst)
    local flower = inst.flower and inst.flower:IsValid() and inst.flower or find_avalable_flower(inst)
    if flower and
       flower:IsValid() then
        return BufferedAction(inst, flower, ACTIONS.GOHOME, nil, Vector3(flower.Transform:GetWorldPosition() ))
    end
end

local function GetNearestPlayerPos(inst)
    local player = inst:GetNearestPlayer(true)
    if player then
        return Vector3(player.Transform:GetWorldPosition() )
    end
end
local function Need_To_Wander_Player(inst)
    if inst.flower and inst.flower:IsValid() then
        return false
    else
        return GetNearestPlayerPos(inst) ~= nil
    end
end


local RUN_AWAY_PARAMS =
{
    tags = {"scarytoprey"},
    fn = function(guy)
        return not (guy.components.skilltreeupdater
                and guy.components.skilltreeupdater:IsActivated("wormwood_bugs"))
    end,
}

local ButterflyBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function ButterflyBrain:OnStart()

    local root =
        PriorityNode(
        {
			BrainCommon.PanicTrigger(self.inst),
            BrainCommon.ElectricFencePanicTrigger(self.inst),
            IfNode(function() return TheWorld.state.isday end, "IsNight",
                DoAction(self.inst, GoHomeAction, "go home", true )),
            IfNode(function() return self.inst.components.knownlocations:GetLocation("home") end, "IsPollinating",
                Wander(self.inst, function() return self.inst.components.knownlocations:GetLocation("home") end, 10) ),

            IfNode(function() return Need_To_Wander_Player(self.inst) end, "wander player",
                Wander(self.inst, function() return GetNearestPlayerPos(self.inst) end, 10) ),

            Wander(self.inst, NearestFlowerPos, MAX_WANDER_DIST)

        },1)


    self.bt = BT(self.inst, root)


end

return ButterflyBrain
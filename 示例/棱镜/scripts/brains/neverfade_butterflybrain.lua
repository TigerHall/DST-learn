require "behaviours/wander"
require "behaviours/doaction"
require "behaviours/follow"

local MAX_WANDER = 3
local MIN_FOLLOW = 0
local MAX_FOLLOW = 4
local MED_FOLLOW = 2

local function GetLeader(inst)
    local leader = inst.components.follower.leader
    if leader ~= nil and leader:IsValid() then
        return leader
    end
end
local function GetLeaderPos(inst)
    local leader = GetLeader(inst)
    if leader == nil then
        leader = inst --如果没有跟随者就以自己为中心徘徊
    end
    return leader:GetPosition()
end

-- local function GoHomeAction(inst)
--     local flower = inst --目标对象就是自己
--     if flower and flower:IsValid() then
--         return BufferedAction(inst, flower, ACTIONS.GOHOME, nil, flower:GetPosition())
--     end
-- end

local Neverfade_ButterflyBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function Neverfade_ButterflyBrain:OnStart()
    local root =
        PriorityNode({
            IfNode(
                function()
                    return self.inst.legiontag_dead ~= nil or
                        self.inst.components.follower.leader == nil or
                        not self.inst.components.follower.leader:IsValid()
                end,
                "No Worries",
                -- DoAction(self.inst, GoHomeAction, "go home", true) --这种是走向型动作，需要走到目标对象附近再触发
                ActionNode(function() self.inst:PushEvent("death") end) --这种是直接型动作，原地就触发
            ),
            Follow(self.inst, function() return GetLeader(self.inst) end, MIN_FOLLOW, MED_FOLLOW, MAX_FOLLOW, true),
            Wander(self.inst, GetLeaderPos, MAX_WANDER)
        }, 1)

    self.bt = BT(self.inst, root)
end

return Neverfade_ButterflyBrain

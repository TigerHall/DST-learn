require "behaviours/chaseandattack"  -- 引入追逐和攻击的行为
require "behaviours/runaway"          -- 引入逃跑的行为
require "behaviours/wander"           -- 引入徘徊的行为
require "behaviours/doaction"         -- 引入执行动作的行为
require "behaviours/attackwall"       -- 引入攻击墙体的行为
require "behaviours/spreadout"        -- 引入分散的行为

local MIN_FOLLOW_DIST = 4
local TARGET_FOLLOW_DIST = 8
local MAX_FOLLOW_DIST = 12

local function GetLeader(inst)
    return inst.components.follower.leader
end

local TreeGuardBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function TreeGuardBrain:OnStart()
    local root =
        PriorityNode(
        {
            ChaseAndAttack(self.inst),  -- 追逐并攻击
            Follow(self.inst, GetLeader, MIN_FOLLOW_DIST, TARGET_FOLLOW_DIST, MAX_FOLLOW_DIST),
            Wander(self.inst),  -- 随机徘徊
        }, 0.25)

    self.bt = BT(self.inst, root)
end

return TreeGuardBrain

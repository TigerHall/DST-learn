require "behaviours/follow"
require "behaviours/wander"
require "behaviours/faceentity"
require "behaviours/panic"

local BrainCommon = require "brains/braincommon"


-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--  Brain
--------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local MIN_FOLLOW_DIST = 0
    local MAX_FOLLOW_DIST = 16
    local TARGET_FOLLOW_DIST = 3
    local MAX_WANDER_DIST = 20
--------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 野生用的
    local function GetNearestPlayerPos(inst)
        local player = inst:GetNearestPlayer()
        if player then
            return Vector3(player.Transform:GetWorldPosition())
        end
        return Vector3(inst.Transform:GetWorldPosition())
    end
    local function HasLeader(inst)
        local leader = inst.components.follower:GetLeader()
        if leader and leader:IsValid() then
            return true,leader
        end
        return false
    end
    local function GetLeaderPos(inst)
        local hasLeader,leader = HasLeader(inst)
        if hasLeader then
            return Vector3(leader.Transform:GetWorldPosition())
        end
        return Vector3(inst.Transform:GetWorldPosition())
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------
----
    local function GetFollowingPlayer(inst)
        return inst.GetFollowingPlayer and inst:GetFollowingPlayer() or inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------
--- pick
    local function IsGoingToPick(inst)
        return inst.___brain_picking_target and inst.___brain_picking_target:IsValid()
    end
    local function DoPickingAction(inst)
        -- if IsGoingToPick(inst) then
        --     return
        -- end
        local item = inst.___brain_picking_target and inst.___brain_picking_target:IsValid() and inst.___brain_picking_target or inst.FindPickableItem and inst:FindPickableItem()
        if item then
            inst.___brain_picking_target = item
            return BufferedAction(inst, item, ACTIONS.TBAT_PET_LAVENDER_KITTY_PICK)
        else
            inst.___brain_picking_target = nil
        end
    end
    local function need_to_run_to_pick(inst)
        local item = inst.___brain_picking_target and inst.___brain_picking_target:IsValid() and inst.___brain_picking_target
        if item and inst:GetDistanceSqToInst(item) > 64 then
            return true
        end
        return false
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------
local KitcoonBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function KitcoonBrain:OnStart()
    local root = PriorityNode({
        --------------------------------------------------------------------------------------------------------------------------
        --- 野生的
            IfNode(function() return TBAT.PET_MODULES:ThisIsWildAnimal(self.inst) end , "wild animal",
                PriorityNode({

                    WhileNode(function() return HasLeader(self.inst) end, "has house",
                        Wander(self.inst, function() return GetLeaderPos(self.inst) end, 16,{minwaittime = 5})),

                    Wander(self.inst, function() return GetNearestPlayerPos(self.inst) end, 8,{minwaittime = 5}),
 
                },0.25)
            ),
        --------------------------------------------------------------------------------------------------------------------------
        --- 如果是养在窝里
            IfNode(function() return TBAT.PET_MODULES:ThisIsHouseAnimal(self.inst) and not TBAT.PET_MODULES:IsFollowingPlayer(self.inst) end, "in pet house",
                PriorityNode({

                    -- DoAction(self.inst, working_pick_plants,"pick plants",true),

                    DoAction(self.inst, DoPickingAction,"pick plants",function() return need_to_run_to_pick(self.inst) end),

                    Wander(self.inst, function() return GetLeaderPos(self.inst) end, MAX_WANDER_DIST,{minwaittime = 5}),

                },0.25)
            ),
        --------------------------------------------------------------------------------------------------------------------------
        --- 跟随玩家
            IfNode(function() return TBAT.PET_MODULES:IsFollowingPlayer(self.inst) end, "in pet house",
                PriorityNode({

                    -----------------------------------------------------------------------------
                    --- Follow
                        -- Follow(self.inst, GetFollowingPlayer, MIN_FOLLOW_DIST, TARGET_FOLLOW_DIST, MAX_FOLLOW_DIST),
                        --- 【笔记】用follower模式会出现奇怪的行为动作，用其他形式替代。
                        WhileNode(function() return TBAT.PET_MODULES:Need2RunClosePlayer(self.inst) end, "need 2 close player (run)",
                            Follow(self.inst, GetFollowingPlayer, MIN_FOLLOW_DIST, TARGET_FOLLOW_DIST, MAX_FOLLOW_DIST,true)),

                        Follow(self.inst, GetFollowingPlayer, MIN_FOLLOW_DIST, TARGET_FOLLOW_DIST, MAX_FOLLOW_DIST),
                          -- DoAction(self.inst, EatFoodAction),

                        Wander(self.inst, function() return GetLeaderPos(self.inst) end, MAX_FOLLOW_DIST,{minwaittime = 5}),
                    -----------------------------------------------------------------------------
                },0.25)
            ),
        --------------------------------------------------------------------------------------------------------------------------
    }) 
    self.bt = BT(self.inst, root)
end

return KitcoonBrain

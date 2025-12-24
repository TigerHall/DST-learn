require "behaviours/wander"
require "behaviours/runaway"
require "behaviours/doaction"
require "behaviours/panic"

local STOP_RUN_DIST = 20
local SEE_PLAYER_DIST = 8
local HIDE_PLAYER_DIST = 16

local SEE_FOOD_DIST = 20
local SEE_BUSH_DIST = 40
local MAX_WANDER_DIST = 20

local MIN_FOLLOW_DIST = 0
local MAX_FOLLOW_DIST = 20
local TARGET_FOLLOW_DIST = 8

local PeagawkBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local function EatFoodAction(inst)
    if not inst.is_bush then
        local target = nil
        if inst.components.inventory and inst.components.eater then
            target = inst.components.inventory:FindItem(function(item) return inst.components.eater:CanEat(item) end)
        end

        if not target then
            local leader = inst.components.follower and inst.components.follower:GetLeader()
            local mid_inst = leader and leader:IsValid() and leader or inst
            target = FindEntity(mid_inst, SEE_FOOD_DIST, function(item) 
                return inst.components.eater:CanEat(item)
                        and item:IsOnValidGround()
                        and (item.components.inventoryitem and item.components.inventoryitem.owner == nil)
                        and not TBAT.DEFINITION:IsImportantItem(item)
            end,nil,{"nosteal"})
            if target then
                --check for scary things near the food
                local predator = GetClosestInstWithTag("scarytoprey", target, SEE_PLAYER_DIST)
                if predator then target = nil end
            end
        end
        if target then
            local act = BufferedAction(inst, target, ACTIONS.EAT)
            act.validfn = function() return not (target.components.inventoryitem and target.components.inventoryitem.owner and target.components.inventoryitem.owner ~= inst) end
            return act
        end
    end	
end

local function IsNearDanger(inst)
    if inst.IsNearAttackers and inst:IsNearAttackers() then
        return true
    end
end

local function IsFollowingPlayer(inst)
    local leader = inst.components.follower and inst.components.follower:GetLeader()
    if leader and leader:HasTag("player") then
        return true
    end
    return false
end

local function GetWildWanderPos(inst)
    --- 寻找范围内最近的玩家
    local player = inst:GetNearestPlayer(true)
    if player and player:GetDistanceSqToInst(inst) > MAX_WANDER_DIST*MAX_WANDER_DIST then
        player = nil
    end
    --- 自己跟随的建筑
    local leader_building = inst.components.follower and inst.components.follower:GetLeader()
    if leader_building and leader_building:HasTag("player") then
        leader_building = nil
    end
    --- 没绑定建筑，跟着最近的玩家
    if player and leader_building == nil then
        return Vector3(player.Transform:GetWorldPosition())
    end
    --- 绑定建筑了建筑。在范围内跟着玩家
    if leader_building and player then
        if inst:GetDistanceSqToInst(leader_building) <= MAX_WANDER_DIST*MAX_WANDER_DIST then
            return Vector3(player.Transform:GetWorldPosition())
        end
    end
    --- 附近没玩家
    if leader_building then
        return Vector3(leader_building.Transform:GetWorldPosition())
    end
end

local function GetFollowingWanderPos(inst)
    local leader = inst.components.follower and inst.components.follower:GetLeader()
    if leader and leader:IsValid() then
        return Vector3(leader.Transform:GetWorldPosition())
    end
end

local function Need2ClosePlayer(inst)
    local leader = inst.components.follower and inst.components.follower:GetLeader()
    if leader and leader:IsValid() and leader:HasTag("player") then
        return leader:GetDistanceSqToInst(inst) > 400
    end
end
local function GetLeader(inst)
    local leader = inst.components.follower and inst.components.follower:GetLeader()
    if leader and leader:IsValid() then
        return leader
    end
    return nil
end

function PeagawkBrain:OnStart()
--    local clock = GetClock()
    
    local root = PriorityNode(
    {
        WhileNode( function() return self.inst.components.health.takingfiredamage end, "OnFire", Panic(self.inst)),
		
        -- IfNode(function() return not self.inst.is_bush and not self.inst.components.health:IsDead() end, "ThreatInRange",
        --     RunAway(self.inst, "scarytoprey", SEE_PLAYER_DIST, STOP_RUN_DIST)),

        IfNode(function() return IsNearDanger(self.inst) end, "ThreatInRange",
            RunAway(self.inst, "scarytoprey", SEE_PLAYER_DIST, STOP_RUN_DIST)),
        ----------------------------------------------------------------------------------------------------------------------------
        ---
            IfNode(function() return Need2ClosePlayer(self.inst) end, "Need2RunClosePlayer",
                Follow(self.inst, GetLeader, MIN_FOLLOW_DIST, TARGET_FOLLOW_DIST, MAX_FOLLOW_DIST,true)),
        ----------------------------------------------------------------------------------------------------------------------------
        --- 吃东西
            -- DoAction(self.inst, EatFoodAction, "Eat Food"),
        ----------------------------------------------------------------------------------------------------------------------------
        --- 野生的
            WhileNode(function() return not IsFollowingPlayer(self.inst) end ,"wild anim type",
                Wander(self.inst, function() return GetWildWanderPos(self.inst) end, MAX_WANDER_DIST,nil,nil,nil,nil,{
                    should_run = false
                }) ),
        ----------------------------------------------------------------------------------------------------------------------------
        --- 跟随的
            WhileNode(function() return IsFollowingPlayer(self.inst) end ,"wild anim type",
                Wander(self.inst, function() return GetFollowingWanderPos(self.inst) end, 16,nil,nil,nil,nil,{
                    should_run = false
                })),
        ----------------------------------------------------------------------------------------------------------------------------
    }, .25)
    
    self.bt = BT(self.inst, root)
end

return PeagawkBrain
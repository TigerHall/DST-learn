require "behaviours/wander"

local MIN_FOLLOW_DIST = 1
local TARGET_FOLLOW_DIST = 3
local MAX_FOLLOW_DIST = 4
local MAX_WANDER_DIST = 2


--搜索附近可采集物品的距离
local PICK_TARGET_DIST = 10


local PigpetBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
    self.tree_target = nil
end)

local function GetPlayerPosition(inst)
    local player = GetPlayer()
    if player then
        return player:GetPosition()
    end
    return inst:GetPosition()
end

local function GetFaceTargetFn(inst)
    return inst.components.follower.leader
end

local function KeepFaceTargetFn(inst, target)
    return inst.components.follower.leader == target
end


local function StartChoppingCondition(inst)
    return inst.components.follower.leader
end


local function KeepChoppingAction(inst)
    return inst.components.follower.leader and inst.components.follower.leader:GetDistanceSqToInst(inst) <= PICK_TARGET_DIST*PICK_TARGET_DIST
end


local function GetLeader(inst)
    return inst.components.follower.leader 
end

local function FindTreeToChopAction(inst)
    local target = FindEntity(inst.components.follower.leader, PICK_TARGET_DIST, function(item) return item.components.workable and item.components.workable.action == ACTIONS.CHOP end)
    if target then
        return BufferedAction(inst, target, ACTIONS.CHOP)
    end
end

--直接拾取， 燧石
local function GetPickableTarget(inst)
    return FindEntity(inst.components.follower.leader, PICK_TARGET_DIST, function(item)
        --判断是否在 notPickPrefeb表中
        for _, prefab in pairs(Pigpet.notPickPrefeb) do
            if prefab == item.prefab then
                return false
            end
        end
        
        --遍历 notPickTag 中的tag，判断item 是否在其中
        for _, tag in pairs(Pigpet.notPickTag) do
            if item:HasTag(tag) then
                return false
            end
        end
        return item.components.inventoryitem and item.components.inventoryitem.canbepickedup 
    end)
end

local function DoPickableTarget(inst)
    local target = GetPickableTarget(inst)
    if target then
        --放入背包       
        return BufferedAction(inst, target, ACTIONS.PICKUP)
    end
end


--采集 树枝， 浆果等
local function GetPickTarget(inst)
    local target = FindEntity(inst.components.follower.leader, PICK_TARGET_DIST, function(item) 
        if item.components.pickable and item.components.pickable:CanBePicked() then
            local prefb_name = Pigpet.pickPrefeb[item.prefab]
            if prefb_name then
                return true
            else 
                print("没有对应的prefb:" .. tostring(item.prefab))
            end
        end
    end)
    return target
end

local function  DoPickTarget(inst)
    local target = GetPickTarget(inst)
    if target then      
        return BufferedAction(inst, target, ACTIONS.PICK)
    end
end

local MAX_CHASE_TIME = 10
local MAX_CHASE_DIST = 30

local function GetWanderDistFn(inst)
    return MAX_WANDER_DIST
end

function PigpetBrain:OnStart()
    local work = WhileNode(function() return Pigpet.Status == 0 end, "Enable",  
            PriorityNode {
                WhileNode( function() return self.inst.components.combat.target ~= nil and KeepChoppingAction(self.inst) end, "AttackMomentarily",
                        ChaseAndAttack(self.inst, MAX_CHASE_TIME, MAX_CHASE_DIST) ),
                --可直接拾取
                WhileNode(function() return KeepChoppingAction(self.inst) and GetPickableTarget(self.inst) end, "keep pickup", 
                    DoAction(self.inst, DoPickableTarget)),

                --采集
                WhileNode(function() return KeepChoppingAction(self.inst) and GetPickTarget(self.inst)  end, "keep pickupable", 
                    DoAction(self.inst, DoPickTarget)),

                IfNode(function() return StartChoppingCondition(self.inst) end, "chop", 
                    WhileNode(function() return KeepChoppingAction(self.inst) end, "keep chopping", 
                        DoAction(self.inst, FindTreeToChopAction))),
             })

    local root = PriorityNode ({
        work,
        Follow(self.inst, GetLeader, MIN_FOLLOW_DIST, TARGET_FOLLOW_DIST, MAX_FOLLOW_DIST),
        --Wander(self.inst, GetPlayerPosition, GetWanderDistFn)
    }, 0.25)

    self.bt = BT(self.inst, root)
end

return PigpetBrain
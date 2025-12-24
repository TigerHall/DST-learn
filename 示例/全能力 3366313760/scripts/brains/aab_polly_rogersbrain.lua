require "behaviours/follow"
require "behaviours/wander"
require "behaviours/faceentity"
require "behaviours/standstill"

local function GetLeader(inst)
    return inst.leader:value()
end

local function CustomPickUpAction(inst)
    local leader = GetLeader(inst)
    local target = leader and leader.components.aab_container_auto_pickup and leader.components.aab_container_auto_pickup:GetTarget()
    if target then
        inst.brain._aab_pickup_timer = GetTime() -- 重置计时器
        return BufferedAction(inst, target, ACTIONS.PICKUP)
    elseif GetTime() - inst.brain._aab_pickup_timer > 3 then
        --五秒没有目标，或者leader没了就消失
        inst.components.inventory:DropEverything()
        ReplacePrefab(inst, "small_puff")
    end
end

local function GiveAction(inst)
    local leader = GetLeader(inst)
    if leader then
        return BufferedAction(inst, leader, ACTIONS.STORE, inst.components.inventory:GetItemInSlot(1))
    end
end

local PollyRogerBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
    self._aab_pickup_timer = GetTime() -- 初始化计时器
end)

function PollyRogerBrain:OnStart()
    local root = PriorityNode({ WhileNode(function() return not self.inst.sg:HasStateTag("busy") end, "NO BRAIN WHEN BUSY",
        PriorityNode({
            --捡
            WhileNode(function() return not self.inst.components.inventory:IsFull() end, "BC KeepPickup",
                DoAction(self.inst, CustomPickUpAction, "BC CustomPickUpAction", true)),
            --给
            WhileNode(function() return self.inst.components.inventory:IsFull() end, "BC KeepPickup",
                DoAction(self.inst, GiveAction, "BC GiveAction", true)),
        }, .25)
    ), }, .25)
    self.bt = BT(self.inst, root)
end

return PollyRogerBrain

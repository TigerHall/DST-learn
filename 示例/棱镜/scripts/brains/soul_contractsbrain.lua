-- require "behaviours/wander"
require "behaviours/standstill"
require "behaviours/follow"

local Soul_ContractsBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

----------
----------

-- local function GetValid(target)
--     if target ~= nil and target:IsValid() then
--         return target
--     end
--     return nil
-- end

local function StandStart(inst)
    return inst:HasTag("bookstay_l")
end
local function StandKeep(inst)
	return inst:HasTag("bookstay_l")
end

-- local function CanWanderWithOwner(inst)
--     return GetValid(inst.components.follower.leader) ~= nil and
--         inst:GetDistanceSqToInst(inst.components.follower.leader) <= 1
-- end
-- local function GetOwnerPos(inst)
-- 	return GetValid(inst.components.follower.leader) ~= nil and
-- 		Vector3(inst.components.follower.leader.Transform:GetWorldPosition()) or nil
-- end

----------
----------

function Soul_ContractsBrain:OnStart()
    local root = PriorityNode({
        --被命令原地不动
        StandStill(self.inst, StandStart, StandKeep), --启动条件、持续条件

		--在签订者附近徘徊
		-- WhileNode(function() return CanWanderWithOwner(self.inst) end, "WanderAroundOwner",
		-- 	Wander(self.inst, GetOwnerPos, 1)
		-- ),

		--跟随签订者
		Follow(self.inst,
            function() return self.inst._owner_s end, --获取跟随对象
            1, --最近跟随距离
            3, --普通跟随距离
            5, --最远跟随距离
            false --是否能跑起来。也就是用locomotor.runspeed的速度
        ),

		--失去签订者后，原地不动
		StandStill(self.inst)
    }, 0.6) --大脑刷新频率：0.6秒一次

    self.bt = BT(self.inst, root)
end

-- function Soul_ContractsBrain:OnInitializationComplete()
-- end

return Soul_ContractsBrain

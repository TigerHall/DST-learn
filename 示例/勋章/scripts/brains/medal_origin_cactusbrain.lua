require "behaviours/standandattack"

local MedalOriginCactusBrain = Class(Brain, function(self, inst)
	Brain._ctor(self, inst)
end)

function MedalOriginCactusBrain:OnStart()
	local root = PriorityNode(
	{
		WhileNode(function() return self.inst.has_spike end, "Has Spike",
			StandAndAttack(self.inst)),

	}, .25)
	
	self.bt = BT(self.inst, root)
end

return MedalOriginCactusBrain

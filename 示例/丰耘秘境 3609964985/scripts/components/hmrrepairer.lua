local Repairer = Class(function(self, inst)
	self.inst = inst
    self.repairtag = "HONOR"
    self.repairability = 80      -- 修理能力
	-- self.onrepaired = nil
end)

function Repairer:SetRepairTag(tag)
	self.repairtag = tag
end

function Repairer:GetRepairTag()
	return self.repairtag
end

function Repairer:SetRepairAbility(ability)
	self.repairability = ability
end

function Repairer:GetRepairAbility()
	return self.repairability
end

function Repairer:Repair(target, doer)
	if target.components.hmrrepairable ~= nil then
        return target.components.hmrrepairable:Repair(self.inst, doer, self.repairability)
    end
    return false
end

return Repairer
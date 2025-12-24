local EmptyScabbardLegion = Class(function(self, inst)
	self.inst = inst

	-- self.fn_test = function(inst, doer, item, count)end
	-- self.fn_do = function(inst, doer, item, count)end
end)

function EmptyScabbardLegion:PutInto(doer, item, count)
	local able, reason
	-- count = count or 1
	if self.fn_test == nil then
		able = true
	else
		able, reason = self.fn_test(self.inst, doer, item, count)
	end
	if able then
		if count ~= nil and item.components.stackable ~= nil and item.components.stackable.stacksize > count then
            item = item.components.stackable:Get(count)
        elseif item.components.inventoryitem ~= nil then
            item.components.inventoryitem:RemoveFromOwner(true)
        end
		self.fn_do(self.inst, doer, item, count)
		return true
	end
	return able, reason
end

return EmptyScabbardLegion

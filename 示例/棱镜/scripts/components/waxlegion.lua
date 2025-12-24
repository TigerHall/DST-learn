local TOOLS_L = require("tools_legion")

local WaxLegion = Class(function(self, inst)
	self.inst = inst
end)

function WaxLegion:Wax(doer, target, right)
	local result, reason
	local waxitem = self.inst
	if target._dd_wax ~= nil then --说明target是个打蜡过的棱镜实体
		result, reason = TOOLS_L.WaxWaxedObject(target, doer, waxitem)
	elseif target:HasTag("waxedplant") and target.savedata ~= nil then --说明target是个打蜡过的官方实体
		result, reason = TOOLS_L.WaxWaxedObject2(target, doer, waxitem)
	else
		if target.legionfn_wax ~= nil then
			result, reason = target.legionfn_wax(target, doer, waxitem, right)
		elseif target.components.waxable ~= nil then
			if target.components.waxable.waxfn ~= nil then
				result, reason = target.components.waxable.waxfn(target, doer, waxitem)
			end
		end
	end
	if result then
		if waxitem.components.finiteuses ~= nil then
			waxitem.components.finiteuses:Use()
		elseif waxitem.components.stackable ~= nil then
			waxitem.components.stackable:Get():Remove()
		else
			waxitem:Remove()
		end
	end
	return result, reason
end

return WaxLegion

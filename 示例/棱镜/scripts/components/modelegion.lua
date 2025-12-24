local ModeLegion = Class(function(self, inst)
	self.inst = inst

	self.now = 1
	self.max = 2
	-- self.fn_test = function(inst, newmode, doer)end
	-- self.fn_do = function(inst, newmode, doer)end
end)

function ModeLegion:Init(num, nummax, fn_test, fn_do)
    self.now = num
	self.max = nummax
	self.fn_test = fn_test
	self.fn_do = fn_do
end

function ModeLegion:SetMode(mode, doer, notest)
    if mode ~= nil then
		mode = math.clamp(mode, 1, self.max)
	else --如果为空，则按顺序切换到下一个
		if self.now >= self.max then
			mode = 1
		else
			mode = self.now + 1
		end
	end
	if notest or self.fn_test == nil or self.fn_test(self.inst, mode, doer) then
		self.now = mode
		self.fn_do(self.inst, mode, doer)
		return true
	end
	return false
end

function ModeLegion:OnSave()
	local data = { now = self.now }
	return data
end
function ModeLegion:OnLoad(data) --Tip：如果组件中的 OnSave() 没有返回数据，则 OnLoad() 也不会执行到了
	if data ~= nil then
        self:SetMode(data.now or 1, nil, true)
	else
		self:SetMode(1, nil, true)
    end
end

return ModeLegion

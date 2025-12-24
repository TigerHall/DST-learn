local tbat_showbufftime = Class(function(self, inst)
    self.inst = inst
	self._buffinfo=net_string(inst.GUID,"tbat_showbufftime._buffinfo")
end)
--获取Buff信息
function tbat_showbufftime:GetBuffInfo()
	return self._buffinfo:value()
end

return tbat_showbufftime
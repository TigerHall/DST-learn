local Factory = Class(function(self, inst)
    self.inst = inst

    self.temp_storage = net_string(inst.GUID, "factory.temp_storage")
end)

function Factory:SetTempStorage(data)
    self.temp_storage:set(HMR_UTIL.EncodeData(data))
end

function Factory:GetTempStorage()
    return HMR_UTIL.DecodeData(self.temp_storage:value()) or {}
end

function Factory:HasTempStorage()
    return next(self:GetTempStorage()) ~= nil
end

return Factory
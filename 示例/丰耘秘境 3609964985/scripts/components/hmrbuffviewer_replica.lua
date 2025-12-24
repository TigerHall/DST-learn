local BuffViewer = Class(function(self, inst)
    self.inst = inst

    self._buff_data = net_string(inst.GUID, "hmrbuffviewer._buff_data", "buff_data_dirty")
end)

function BuffViewer:SetBuffData(data)
    local encoded_data = HMR_UTIL.EncodeData(data)
    if encoded_data ~= self._buff_data:value() then
        self._buff_data:set(encoded_data)
    end
end

function BuffViewer:GetBuffData()
    local data = HMR_UTIL.DecodeData(self._buff_data:value())
    return data
end

return BuffViewer
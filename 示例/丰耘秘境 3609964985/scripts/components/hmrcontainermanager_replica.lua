local ContainerManager = Class(function(self, inst)
    self.inst = inst

    self._slot_display = net_string(inst.GUID, "containermanager.slot_display", "slot_display_dirty")
end)

function ContainerManager:SetSlotDisplay(slots)
    self._slot_display:set(HMR_UTIL.EncodeData(slots))
end

function ContainerManager:GetSlotDisplay()
    return HMR_UTIL.DecodeData(self._slot_display:value())
end

function ContainerManager:ShouldShowSlot(slot)
    if not slot then
        return true
    end

    local slots_to_hide = self:GetSlotDisplay()
    if slots_to_hide ~= nil then
        for _, s in ipairs(slots_to_hide) do
            if s == slot then
                return false
            end
        end
    end
    return true
end

return ContainerManager
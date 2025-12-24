local function DefaultSlotDirty(inst)
    local self = inst.replica.hmrcontainermanager
    if inst.components.container then
        for i = 1, inst.components.container.numslots do
            if not self:ShouldShowSlot(i) then
                local item = inst.components.container:RemoveItemBySlot(i)
                if item then
                    inst.components.container:GiveItem(item)
                end
            end
        end
    end
end

local ContainerManager = Class(function(self, inst)
    self.inst = inst

    self.slot_temperature = nil
    self.default_temperature_rate = 1

    self.slot_display = {}
    self.onslotdisplay = DefaultSlotDirty
    self.DefaultSlotDirty = DefaultSlotDirty
    inst:ListenForEvent("slot_display_dirty", self.onslotdisplay)
end)

function ContainerManager:SetSlotTemperature(fn)
    self.slot_temperature = fn
end

function ContainerManager:GetSlotTemperature(slot)
    if self.slot_temperature then
        if type(self.slot_temperature) == "function" then
            local temp, rate = self.slot_temperature(self.inst, slot)
            rate = rate or self.default_temperature_rate
            return temp, rate
        elseif type(self.slot_temperature) == "number" then
            return self.slot_temperature, self.default_temperature_rate
        end
    end
    return nil
end

function ContainerManager:SetSlotDisplay(slots)
    self.slot_display = slots
    self.inst.replica.hmrcontainermanager:SetSlotDisplay(slots)
end

function ContainerManager:GetSlotDisplay()
    return self.slot_display
end

function ContainerManager:HasDisplaySet()
    return self.slot_display and #self.slot_display > 0
end

function ContainerManager:SetOnSlotDisplay(fn)
    self.onslotdisplay = fn
end

function ContainerManager:OnSave()
    local data = {
        slot_display = self.slot_display,
    }
    return next(data) and data or nil
end

function ContainerManager:OnLoad(data)
    if data then
        if data.slot_display then
            self:SetSlotDisplay(data.slot_display)
        end
    end
end

return ContainerManager
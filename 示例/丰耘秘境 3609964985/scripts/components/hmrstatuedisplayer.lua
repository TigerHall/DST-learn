local StatueDisplayer = Class(function(self, inst)
    self.inst = inst

    self.override_symbol_name = nil

    self.statue_record = nil

    self.dofx = true
end)

function StatueDisplayer:OnRemoveFromEntity()
    if self.statue_record ~= nil then
        local item = SpawnSaveRecord(self.statue_record)
        if item ~= nil then
            self.inst.components.lootdropper:FlingItem(item, self.inst:GetPosition())
        end
    end
    self.inst:RemoveTag("displayer_occupied")
end

function StatueDisplayer:SetOnDisplay(fn)
    self.ondisplay = fn
end

function StatueDisplayer:SetOnUnDisplay(fn)
    self.onundisplay = fn
end

function StatueDisplayer:SetOverrideSymbolName(name)
    self.override_symbol_name = name
end

function StatueDisplayer:GetOverrideSymbolName()
    return self.override_symbol_name
end

function StatueDisplayer:IsOccupied()
    return self.inst:HasTag("displayer_occupied")
end

function StatueDisplayer:GiveStatue(item)
    if item.components.symbolswapdata ~= nil then
        if item.components.symbolswapdata.is_skinned then
            self.inst.AnimState:OverrideItemSkinSymbol(
                self.override_symbol_name,
                item.components.symbolswapdata.build,
                item.components.symbolswapdata.symbol,
                item.GUID,
                "swap_body" ) --default should never be used
        else
            self.inst.AnimState:OverrideSymbol(
                self.override_symbol_name,
                item.components.symbolswapdata.build,
                item.components.symbolswapdata.symbol)
        end

        if self.ondisplay ~= nil then
            self.ondisplay(self.inst)
        end
        self.statue_record = item:GetSaveRecord()
        item:Remove()
        self.inst:AddTag("displayer_occupied")
        return true
    end

    return false
end

function StatueDisplayer:PickStatue(doer)
    self.inst.AnimState:ClearOverrideSymbol(self.override_symbol_name)

    if self.statue_record ~= nil then
        local item = SpawnSaveRecord(self.statue_record)
        if item ~= nil then
            if doer then
                doer.components.inventory:Equip(item)
            else
                local pt = self.inst:GetPosition()
                self.inst.components.lootdropper:FlingItem(item, pt)
            end
        end

        if self.onundisplay ~= nil then
            self.onundisplay(self.inst)
        end

        self.inst:RemoveTag("displayer_occupied")

        return true
    end
end

function StatueDisplayer:OnSave()
    local data =
    {
        statue_record = self.statue_record,
    }

    return next(data) ~= nil and data or nil
end

function StatueDisplayer:OnLoad(data)
    if data ~= nil and data.statue_record ~= nil then
        self.statue_record = data.statue_record
        local item = SpawnSaveRecord(self.statue_record)
        if item ~= nil then
            self:GiveStatue(item)
        end
    end
end

return StatueDisplayer
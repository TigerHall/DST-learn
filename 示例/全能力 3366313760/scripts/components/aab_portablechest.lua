local function Init(inst, self)
    self:SetItem(self.isitem)
end

--- 箱子可携带
local Chest = Class(function(self, inst)
    self.inst = inst

    self.isitem = true --默认可以放背包里
    inst:DoTaskInTime(0, Init, self)
end)

function Chest:SetItem(isitem, doer)
    local inst = self.inst
    self.isitem = isitem
    inst.components.inventoryitem.canbepickedup = isitem
    inst.components.inventoryitem.cangoincontainer = isitem

    if isitem then
        inst:RemoveTag("structure")
        if doer then
            doer.components.inventory:GiveItem(self.inst)
        end
    else
        inst:AddTag("structure")
    end
end

function Chest:OnSave()
    return {
        isitem = self.isitem
    }
end

function Chest:OnLoad(data)
    if not data then return end
    self.isitem = data.isitem or self.isitem
end

return Chest

local Utils = require("aab_utils/utils")

local function DropEverythingBefore(self, ondeath)
    if ondeath and self.inst:HasTag("player") and IsEntityDeadOrGhost(self.inst) then
        --其他东西不掉，但是重生护符要掉下来
        for _, v in ipairs(self:FindItems(function(ent)
            return not ent.components.inventoryitem.keepondeath
                and ent.components.hauntable
                and ent.components.hauntable.hauntvalue == TUNING.HAUNT_INSTANT_REZ
        end)) do
            self:DropItem(v, true, true)
        end
        return nil, true
    end
end

AddComponentPostInit("inventory", function(self)
    Utils.FnDecorator(self, "DropEverything", DropEverythingBefore)
end)

local Utils = require("aab_utils/utils")

local function OnDespawnBefore(inst)
    inst._aab_ignore_irreplaceable = true
end

local function OnDespawnAfter(retTab, inst)
    inst._aab_ignore_irreplaceable = nil
    return retTab
end

local function DropEverythingWithTagBefore(self, tag)
    return nil, tag == "irreplaceable" and self.inst._aab_ignore_irreplaceable
end

AddPlayerPostInit(function(inst)
    if not TheWorld.ismastersim then return end

    Utils.FnDecorator(inst, "OnDespawn", OnDespawnBefore, OnDespawnAfter)
    Utils.FnDecorator(inst.components.inventory, "DropEverythingWithTag", DropEverythingWithTagBefore)
end)

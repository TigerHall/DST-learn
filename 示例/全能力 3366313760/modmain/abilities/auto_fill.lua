local Utils = require("aab_utils/utils")


local function FindItem(inst, fn)
    local owner = inst.components.inventoryitem.owner
    if owner.components.inventory then
        return owner.components.inventory:FindItem(fn)
    end
end

local function OnPercentusedChange(inst, data)
    if data and data.percent <= 0 then
        local item = FindItem(inst, function(ent) return ent.prefab == "nightmarefuel" end)
        if item then
            local owenr = inst.components.inventoryitem.owner
            local fuel = owenr.components.inventory:RemoveItem(item)
            if fuel then
                inst.components.fueled:TakeFuelItem(fuel, owenr)
                fuel:Remove()
            end
        end
    end
end

AddPrefabPostInit("waxwelljournal", function(inst)
    if not TheWorld.ismastersim then return end

    inst:ListenForEvent("percentusedchange", OnPercentusedChange)
end)

----------------------------------------------------------------------------------------------------

for prefab, findfn in pairs({
    slingshot = function(item) return item:HasTag("slingshotammo") end,
    houndstooth_blowpipe = function(item) return item:HasTag("blowpipeammo") end
}) do
    local function LaunchProjectileAfter(retTab, self)
        if self.inst.components.container:IsEmpty() then
            local owner = self.inst.components.inventoryitem.owner
            if owner and owner.components.inventory then
                local item = owner.components.inventory:FindItem(findfn)
                if item then
                    owner.components.inventory:RemoveItem(item, true)
                    self.inst.components.container:GiveItem(item)
                end
            end
        end
    end

    AddPrefabPostInit(prefab, function(inst)
        if not TheWorld.ismastersim then return end

        Utils.FnDecorator(inst.components.weapon, "LaunchProjectile", nil, LaunchProjectileAfter)
    end)
end

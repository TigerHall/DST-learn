local Constructor = require("aab_utils/constructor")

local assets = {
    Asset("ANIM", "anim/hat_disguise.zip"),
}

local function CoomonInit(inst)
    MakeInventoryFloatable(inst)
end

local CHECK_TAGS = { "monster", "wonkey", "pirate", "merm" }
local function OnDisguiseEquip(inst, owner)
    Constructor.OpenTopOnEquip(owner)
    owner.AnimState:OverrideSymbol("swap_hat", "hat_disguise", "swap_hat")

    inst.tags = {}
    for _, v in ipairs(CHECK_TAGS) do
        if owner:HasTag(v) then
            table.insert(inst.tags, v)
            owner:RemoveTag(v)
        end
    end
end

local function OnDisguiseUnEquip(inst, owner)
    Constructor.OnHatUnequip(inst, owner)

    for _, v in ipairs(inst.tags) do
        owner:AddTag(v)
    end
    inst.tags = nil
end

local function MasterInit(inst)
    inst.components.equippable:SetOnEquip(OnDisguiseEquip)
    inst.components.equippable:SetOnUnequip(OnDisguiseUnEquip)
end

return Constructor.MakePrefab("aab_disguisehat", {
    bank = "disguisehat",
    build = "hat_disguise",
    assets = assets,
    common_init = CoomonInit,
    master_init = MasterInit,
    ishat = true,
})

local HUNGER_MULT = GetModConfigData("hunger_mult") / 100

AddPlayerPostInit(function(inst)
    if not TheWorld.ismastersim then return end
    inst.components.hunger.burnratemodifiers:SetModifier(inst, HUNGER_MULT, "aab_hunger_mult")
end)

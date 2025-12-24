local SPEED_MULT = GetModConfigData("speed_mult") / 100

AddPlayerPostInit(function(inst)
    if not TheWorld.ismastersim then return end
    inst.components.locomotor:SetExternalSpeedMultiplier(inst, "aab_speed_mult", SPEED_MULT)
end)


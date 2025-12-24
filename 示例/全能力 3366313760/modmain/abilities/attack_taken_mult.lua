local ATTACK_TAKEN_MULT = GetModConfigData("attack_taken_mult") / 100

AddPlayerPostInit(function(inst)
    if not TheWorld.ismastersim then return end
    inst.components.combat.externaldamagetakenmultipliers:SetModifier(inst, ATTACK_TAKEN_MULT, "aab_attack_taken_mult")
end)

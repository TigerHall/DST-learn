local ATTACK_MULT = GetModConfigData("attack_mult") / 100

AddPlayerPostInit(function(inst)
    if not TheWorld.ismastersim then return end
    inst.components.combat.externaldamagemultipliers:SetModifier(inst, ATTACK_MULT, "aab_attack_mult")
end)

local WORK_MULT = GetModConfigData("work_mult") / 100

AddPlayerPostInit(function(inst)
    if not TheWorld.ismastersim then return end

    inst.components.workmultiplier:AddMultiplier(ACTIONS.CHOP, WORK_MULT, inst)
    inst.components.workmultiplier:AddMultiplier(ACTIONS.MINE, WORK_MULT, inst)
    inst.components.workmultiplier:AddMultiplier(ACTIONS.HAMMER, WORK_MULT, inst)
end)

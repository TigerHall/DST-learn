local INIT_TECH = GetModConfigData("init_tech")

AddPlayerPostInit(function(inst)
    if not TheWorld.ismastersim then return end

    if INIT_TECH == 1 then
        inst.components.builder.science_bonus = 1
        inst.components.builder.magic_bonus = 1
    elseif INIT_TECH == 2 then
        inst.components.builder.science_bonus = 2
        inst.components.builder.magic_bonus = 1
    elseif INIT_TECH == 3 then
        inst.components.builder.science_bonus = 2
        inst.components.builder.magic_bonus = 2
    elseif INIT_TECH == 4 then
        inst.components.builder.science_bonus = 2
        inst.components.builder.magic_bonus = 3
    end
end)

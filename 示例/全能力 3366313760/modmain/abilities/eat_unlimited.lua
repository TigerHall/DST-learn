AddPlayerPostInit(function(inst)
    if not TheWorld.ismastersim then return end

    inst.components.eater:SetDiet({ FOODGROUP.OMNI })
    inst.components.eater.preferseatingtags = nil
end)

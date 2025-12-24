local ICEBOX_FRESHNESS = GetModConfigData("icebox_freshness")

AddPrefabPostInit("icebox", function(inst)
    if not TheWorld.ismastersim then return end

    if not inst.components.preserver then
        inst:AddComponent("preserver")
    end
    inst.components.preserver:SetPerishRateMultiplier(ICEBOX_FRESHNESS)
end)

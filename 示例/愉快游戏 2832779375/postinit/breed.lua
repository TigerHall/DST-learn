

local function _py_breed(inst)
    if not TheWorld.ismastersim then
        return
    end

    inst:AddComponent("knownlocations")
    inst:AddComponent("herdmember")
    inst.components.herdmember:SetHerdPrefab("py_"..inst.prefab.."herd")
end
--------------------------------------------------------------------------------------------------------------------
if GetModConfigData("koalefant_breed") then
    AddPrefabPostInit("koalefant_winter", _py_breed)
    AddPrefabPostInit("koalefant_summer", _py_breed)
end
--------------------------------------------------------------------------------------------------------------------
if GetModConfigData("spat_breed") then
    AddPrefabPostInit("spat", _py_breed)
end
--------------------------------------------------------------------------------------------------------------------
if GetModConfigData("bearger_breed") then
    AddPrefabPostInit("bearger", _py_breed)
end
--------------------------------------------------------------------------------------------------------------------
if GetModConfigData("deerclops_breed") then
    AddPrefabPostInit("deerclops", _py_breed)
    AddPrefabPostInit("deerclops", function(inst)
        if not TheWorld.ismastersim then
            return inst
        end

        inst:DoTaskInTime(FRAMES, function(inst)
            inst:StopWatchingWorldState("stopwinter")
            inst.WantsToLeave = function() return false end
        end)
    end)
end
--------------------------------------------------------------------------------------------------------------------






























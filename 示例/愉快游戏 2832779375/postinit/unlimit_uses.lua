

local function unlimituses_postinitfn(inst)
    if not TheWorld.ismastersim then
        return inst
    end

    if inst.components.finiteuses then
        inst:RemoveComponent("finiteuses")
    end
    if inst.components.fueled then
        inst:RemoveComponent("fueled")
    end
end
if GetModConfigData("unlimituses_tentaclespike") then
    AddPrefabPostInit("tentaclespike", unlimituses_postinitfn)
end
--------------------------------------------------------------------------------------------------------------------
if GetModConfigData("unlimituses_heatrock") then
    AddPrefabPostInit("heatrock", function(inst)
        if not TheWorld.ismastersim then
            return inst
        end
        inst:ListenForEvent("percentusedchange", function(inst, data)
            local percent = data.percent
            if percent < 1 then
                inst.components.fueled:SetPercent(1.0)
            end
        end)
    end)
end
--------------------------------------------------------------------------------------------------------------------
if GetModConfigData("unlimituses_molehat") then
    AddPrefabPostInit("molehat", unlimituses_postinitfn)
end
--------------------------------------------------------------------------------------------------------------------







































